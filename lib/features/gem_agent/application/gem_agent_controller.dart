import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/l10n/locale_preference_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/workspace_mode.dart';
import '../domain/agent_effect.dart';
import '../domain/agent_outcome.dart';
import '../domain/agent_session.dart';
import '../engine/guardrails.dart';
import '../engine/system_prompt_builder.dart';
import 'gem_agent_providers.dart';
import 'gem_agent_state.dart';
import 'speech_input_service.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

/// Drives one Gem Agent session: voice capture → engine turn → effects.
final gemAgentControllerProvider =
    NotifierProvider<GemAgentController, GemAgentState>(GemAgentController.new);

class GemAgentController extends Notifier<GemAgentState>
    with DisposeTolerantNotifier<GemAgentState> {
  CancelToken? _turn;
  Timer? _flashTimer;
  int _listenSession = 0;
  bool _stopRequested = false;
  bool _useDeviceLocale = false;

  /// Final words from earlier recognizer sessions of this capture.
  String _heard = '';

  /// Recognizer failures in a row with no speech in between.
  int _failStreak = 0;

  static const _maxEntries = 12;
  static const _flashFor = Duration(seconds: 4);
  static const _maxFailStreak = 6;
  static const _restartDelay = Duration(milliseconds: 350);
  static const _stopGrace = Duration(seconds: 3);
  static const _permissionNotice = 'Mic access off. Enable it in Settings.';
  static const _unavailableNotice = 'Voice unavailable. Type instead.';

  @override
  GemAgentState build() {
    ref.onDispose(() {
      _flashTimer?.cancel();
      _turn?.cancel();
    });
    // A different account never sees the previous one's conversation; the
    // engine (and its memory) is rebuilt for the new user at the same time.
    ref.listen(authProvider.select((s) => s.user?.id), (previous, next) {
      if (previous == next) return;
      _turn?.cancel('account-changed');
      _turn = null;
      state = GemAgentState(voiceAvailable: state.voiceAvailable);
    });
    return const GemAgentState();
  }

  /// Opens the sheet. The mic stays off until the user taps it.
  void open() {
    state = state.copyWith(isOpen: true, flash: null);
  }

  /// Dismisses the sheet and abandons any running turn.
  Future<void> close() async {
    _turn?.cancel('closed');
    _turn = null;
    _listenSession++;
    await ref.read(gemAgentSpeechProvider).cancel();
    if (!ref.mounted) return;
    state = state.copyWith(
      isOpen: false,
      phase: state.isBusy ? GemAgentPhase.idle : state.phase,
      activity: null,
      liveTranscript: '',
    );
  }

  /// Forgets the conversation so the next request starts fresh.
  void newSession() {
    _turn?.cancel('reset');
    _turn = null;
    ref.read(gemAgentEngineProvider).reset();
    state = GemAgentState(
      isOpen: state.isOpen,
      voiceAvailable: state.voiceAvailable,
    );
  }

  /// Opens the mic and keeps it open until [stopListening] (or the sheet
  /// closes); everything heard meanwhile is sent as one request.
  Future<void> startListening() async {
    if (state.isBusy) return;
    _stopRequested = false;
    _heard = '';
    _failStreak = 0;
    await _listen();
    if (!ref.mounted) return;
  }

  /// One recognizer session. Platform recognizers end a session after a
  /// pause or a few seconds of silence, so [_onListeningEnded] keeps
  /// reopening the mic until the user presses stop.
  Future<void> _listen() async {
    final speech = ref.read(gemAgentSpeechProvider);
    final session = ++_listenSession;
    if (!await speech.ensureReady()) {
      if (session != _listenSession) return;
      final permitted = await speech.hasPermission();
      if (!ref.mounted) return;
      state = state.copyWith(
        // Keep the mic button so a denied permission can be retried.
        voiceAvailable: !permitted,
        phase: GemAgentPhase.idle,
        notice: permitted ? _unavailableNotice : _permissionNotice,
      );
      return;
    }
    if (session != _listenSession || !state.isOpen) return;
    state = state.copyWith(
      phase: GemAgentPhase.listening,
      liveTranscript: _heard,
      notice: null,
      soundLevel: 0,
    );
    final locale = _useDeviceLocale
        ? null
        : await speech.resolveLocale(_speechLocale());
    if (session != _listenSession || state.phase != GemAgentPhase.listening) {
      return;
    }
    bool live() =>
        session == _listenSession && state.phase == GemAgentPhase.listening;
    await speech.start(
      localeId: locale,
      onResult: (words, isFinal) {
        if (!live()) return;
        final spoken = words.trim();
        if (spoken.isNotEmpty) _failStreak = 0;
        final all = _join(_heard, spoken);
        state = state.copyWith(liveTranscript: all);
        if (!isFinal) return;
        _heard = all;
        // Keep listening for more until the user presses stop.
        if (_stopRequested) _submit(all, viaVoice: true);
      },
      onStopped: () => _onListeningEnded(session, null),
      onError: (failure) => _onListeningEnded(session, failure),
      onLevel: (level) {
        if (live()) state = state.copyWith(soundLevel: level);
      },
    );
    if (!ref.mounted) return;
  }

  /// Ends capture; the recognizer then delivers its final words.
  Future<void> stopListening() async {
    _stopRequested = true;
    final speech = ref.read(gemAgentSpeechProvider);
    if (speech.isListening) {
      final session = _listenSession;
      await speech.stop();
      if (!ref.mounted) return;
      // Some recognizers never report back after a stop.
      Timer(_stopGrace, () => _onListeningEnded(session, null));
    } else {
      // Between sessions (mic reopening): nothing will report back.
      await _onListeningEnded(_listenSession, null);
      if (!ref.mounted) return;
    }
  }

  /// Typed request or quick reply.
  Future<void> submitText(String text) => _submit(text, viaVoice: false);

  /// Starter prompts for who is asking and which side of the app they are on.
  List<String> starterPrompts() =>
      InputGuard.starterOptions(_runtime().session);

  /// Opens a page from an answer card (row or button).
  Future<void> openFromCard(String route) async {
    await close();
    if (!ref.mounted) return;
    await OpenPageEffect(route).apply(ref);
    if (!ref.mounted) return;
  }

  Future<void> _onListeningEnded(int session, SpeechFailure? failure) async {
    if (session != _listenSession) return;
    if (state.phase != GemAgentPhase.listening) return;
    final heard = state.liveTranscript.trim();
    if (_stopRequested) {
      if (heard.isNotEmpty) return _submit(heard, viaVoice: true);
      _listenSession++;
      await ref.read(gemAgentSpeechProvider).cancel();
      if (!ref.mounted) return;
      state = state.copyWith(phase: GemAgentPhase.idle, soundLevel: 0);
      return;
    }
    // Session ended by itself: keep what was said and reopen the mic.
    _heard = heard;
    switch (failure) {
      case SpeechFailure.permission:
        return _endListening(_permissionNotice);
      case SpeechFailure.network:
        return _endListening(
          'Voice needs an internet connection. Check it, or type your request.',
        );
      case SpeechFailure.audio:
        return _endListening(
          'The microphone is in use by another app. Close it and tap the mic.',
        );
      case SpeechFailure.language when !_useDeviceLocale:
        // Retry in the device's own speech language.
        _useDeviceLocale = true;
        return _relisten();
      case SpeechFailure.language:
        return _endListening(
          'Voice isn\'t available for this language on your device. '
          'Type your request instead.',
        );
      case null || SpeechFailure.soft:
        // Pause or silence: normal, listen on.
        return _relisten();
      case SpeechFailure.busy || SpeechFailure.other:
        if (++_failStreak > _maxFailStreak) {
          return _endListening(
            'The microphone keeps failing. Tap the mic to try again.',
          );
        }
        return _relisten(backoff: _failStreak);
    }
  }

  Future<void> _relisten({int backoff = 0}) async {
    // Drop late events from the session being replaced.
    final next = ++_listenSession;
    await ref.read(gemAgentSpeechProvider).cancel();
    if (!ref.mounted) return;
    // Recognizers report busy if reopened right after a cancel.
    await Future<void>.delayed(_restartDelay * (1 + backoff));
    if (!ref.mounted) return;
    if (next != _listenSession ||
        state.phase != GemAgentPhase.listening ||
        !state.isOpen) {
      return;
    }
    await _listen();
    if (!ref.mounted) return;
  }

  static String _join(String a, String b) =>
      a.isEmpty ? b : (b.isEmpty ? a : '$a $b');

  Future<void> _endListening(String notice) async {
    _listenSession++;
    await ref.read(gemAgentSpeechProvider).cancel();
    if (!ref.mounted) return;
    state = state.copyWith(
      phase: GemAgentPhase.idle,
      notice: notice,
      soundLevel: 0,
    );
  }

  Future<void> _submit(String text, {required bool viaVoice}) async {
    final utterance = text.trim();
    if (utterance.isEmpty || state.isBusy) return;
    _listenSession++;
    unawaited(ref.read(gemAgentSpeechProvider).cancel());
    final token = CancelToken();
    _turn?.cancel('superseded');
    _turn = token;

    state = state.copyWith(
      phase: GemAgentPhase.thinking,
      liveTranscript: '',
      notice: null,
      options: const [],
      activity: 'Understanding your request…',
      entries: _append(GemAgentEntry.user(utterance)),
    );

    final outcome = await ref
        .read(gemAgentEngineProvider)
        .run(
          utterance,
          runtime: _runtime(),
          ref: ref,
          cancelToken: token,
          onProgress: (progress) {
            if (!identical(_turn, token)) return;
            state = switch (progress) {
              AgentThinking() => state.copyWith(
                phase: GemAgentPhase.thinking,
                activity: 'Understanding your request…',
              ),
              AgentToolRunning(:final label) => state.copyWith(
                phase: GemAgentPhase.acting,
                activity: label,
              ),
            };
          },
        );
    if (!ref.mounted) return;
    if (!identical(_turn, token)) return;
    _turn = null;
    await _handle(outcome);
    if (!ref.mounted) return;
  }

  Future<void> _handle(AgentOutcome outcome) async {
    switch (outcome) {
      case AgentReply(:final text, :final options):
        state = state.copyWith(
          phase: GemAgentPhase.idle,
          activity: null,
          options: options,
          entries: _append(GemAgentEntry.agent(text)),
        );
      case AgentClarification(:final question, :final options):
        state = state.copyWith(
          phase: GemAgentPhase.awaitingInput,
          activity: null,
          options: options,
          entries: _append(GemAgentEntry.agent(question)),
        );
      case AgentActionCompleted(:final summary, :final effects, :final cards)
          when effects.isEmpty:
        // Small answers stay in the sheet, with their cards.
        state = state.copyWith(
          phase: GemAgentPhase.idle,
          activity: null,
          entries: _append(GemAgentEntry.agent(summary, cards: cards)),
        );
      case AgentActionCompleted(:final summary, :final effects, :final cards):
        state = state.copyWith(
          phase: GemAgentPhase.idle,
          activity: null,
          isOpen: false,
          entries: _append(GemAgentEntry.agent(summary, cards: cards)),
        );
        for (final effect in effects) {
          await effect.apply(ref);
          if (!ref.mounted) return;
        }
        _showFlash(summary);
      case AgentFailed(:final message):
        state = state.copyWith(
          phase: GemAgentPhase.error,
          activity: null,
          entries: _append(GemAgentEntry.agent(message, isError: true)),
        );
      case AgentCancelled():
        state = state.copyWith(phase: GemAgentPhase.idle, activity: null);
    }
  }

  void _showFlash(String message) {
    _flashTimer?.cancel();
    state = state.copyWith(flash: message);
    _flashTimer = Timer(_flashFor, () => state = state.copyWith(flash: null));
  }

  List<GemAgentEntry> _append(GemAgentEntry entry) {
    final next = [...state.entries, entry];
    return next.length > _maxEntries
        ? next.sublist(next.length - _maxEntries)
        : next;
  }

  AgentRuntimeContext _runtime() {
    String route;
    try {
      route = appRouter.state.uri.path;
    } catch (_) {
      route = appRouter.routerDelegate.currentConfiguration.uri.path;
    }
    final auth = ref.read(authProvider);
    return AgentRuntimeContext(
      route: route,
      languageCode: ref.read(localePreferenceProvider).languageCode,
      now: DateTime.now(),
      session: AgentSession(
        signedIn: auth.isAuthenticated,
        isSeller: auth.isSeller,
        workspace: _agentWorkspace(route),
      ),
    );
  }

  /// Info pages outside both workspaces belong to neither side, so the
  /// agent asks which side a seller means there.
  static final _sharedPages = RegExp(
    r'^/(about|privacy|terms|policies|share|login|register|forgot-password|'
    r'verify-otp|reset-password|recover-account)(/|$)',
  );

  static AgentWorkspace _agentWorkspace(String route) {
    if (workspaceForPath(route) == AppWorkspace.seller) {
      return AgentWorkspace.seller;
    }
    return _sharedPages.hasMatch(route)
        ? AgentWorkspace.shared
        : AgentWorkspace.buyer;
  }

  String _speechLocale() =>
      switch (ref.read(localePreferenceProvider).languageCode) {
        'hi' => 'hi_IN',
        'gu' => 'gu_IN',
        _ => 'en_IN',
      };
}
