import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/user_local_data_cleaner.dart';
import '../../../core/error/result.dart';
import '../data/repositories/ai_chat_repository_impl.dart';
import '../domain/models/ai_chat_language.dart';
import '../domain/models/ai_chat_message.dart';
import '../domain/models/ai_chat_reply.dart';
import '../domain/repositories/ai_chat_repository.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

const _sessionPrefKey = UserLocalDataCleaner.aiChatSessionId;
const _guestKeysPrefKey = UserLocalDataCleaner.aiChatGuestSessionKeys;

class AiChatUiState {
  const AiChatUiState({this.isOpen = false, this.showHistory = false});

  final bool isOpen;
  final bool showHistory;

  AiChatUiState copyWith({bool? isOpen, bool? showHistory}) {
    return AiChatUiState(
      isOpen: isOpen ?? this.isOpen,
      showHistory: showHistory ?? this.showHistory,
    );
  }
}

class AiChatUiController extends Notifier<AiChatUiState>
    with DisposeTolerantNotifier<AiChatUiState> {
  @override
  AiChatUiState build() => const AiChatUiState();

  void open() => state = state.copyWith(isOpen: true, showHistory: false);

  void close() => state = state.copyWith(isOpen: false, showHistory: false);

  void toggle() => state.isOpen ? close() : open();

  void showHistory() => state = state.copyWith(showHistory: true);

  void hideHistory() => state = state.copyWith(showHistory: false);
}

final aiChatUiProvider = NotifierProvider<AiChatUiController, AiChatUiState>(
  AiChatUiController.new,
);

class AiChatPanelState {
  const AiChatPanelState({
    this.sessionId = '',
    this.messages = const [],
    this.language = AiChatLanguage.en,
    this.isSending = false,
    this.isUploading = false,
    this.isLoadingSession = false,
    this.isLoadingHistory = false,
    this.errorMessage,
    this.sessions = const [],
    this.pendingImageUrl,
    this.pendingImageName,
  });

  final String sessionId;
  final List<AiChatMessage> messages;
  final AiChatLanguage language;
  final bool isSending;
  final bool isUploading;
  final bool isLoadingSession;
  final bool isLoadingHistory;
  final String? errorMessage;
  final List<AiChatSessionSummary> sessions;
  final String? pendingImageUrl;
  final String? pendingImageName;

  AiChatPanelState copyWith({
    String? sessionId,
    List<AiChatMessage>? messages,
    AiChatLanguage? language,
    bool? isSending,
    bool? isUploading,
    bool? isLoadingSession,
    bool? isLoadingHistory,
    String? errorMessage,
    bool clearError = false,
    List<AiChatSessionSummary>? sessions,
    String? pendingImageUrl,
    String? pendingImageName,
    bool clearPendingImage = false,
  }) {
    return AiChatPanelState(
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      language: language ?? this.language,
      isSending: isSending ?? this.isSending,
      isUploading: isUploading ?? this.isUploading,
      isLoadingSession: isLoadingSession ?? this.isLoadingSession,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sessions: sessions ?? this.sessions,
      pendingImageUrl: clearPendingImage
          ? null
          : (pendingImageUrl ?? this.pendingImageUrl),
      pendingImageName: clearPendingImage
          ? null
          : (pendingImageName ?? this.pendingImageName),
    );
  }
}

class AiChatPanelNotifier extends Notifier<AiChatPanelState>
    with DisposeTolerantNotifier<AiChatPanelState> {
  CancelToken? _cancelToken;
  SharedPreferences? _prefs;

  @override
  AiChatPanelState build() {
    ref.watch(authProvider.select((s) => s.user?.id));
    ref.onDispose(() => _cancelToken?.cancel());
    _cancelToken?.cancel('auth-user-changed');
    _cancelToken = null;
    Future.microtask(_bootstrap);
    return const AiChatPanelState();
  }

  AiChatRepository get _repo => ref.read(aiChatRepositoryProvider);

  Future<void> _bootstrap() async {
    _prefs ??= await SharedPreferences.getInstance();
    var sessionId = _prefs!.getString(_sessionPrefKey) ?? '';
    if (sessionId.isEmpty) {
      sessionId = _newSessionId();
      await _prefs!.setString(_sessionPrefKey, sessionId);
      if (!ref.mounted) return;
      await _rememberGuestKey(sessionId);
      if (!ref.mounted) return;
    }
    state = state.copyWith(sessionId: sessionId);
  }

  String _newSessionId() {
    final rand = Random.secure();
    String block(int len) {
      const chars = 'abcdef0123456789';
      return List.generate(
        len,
        (_) => chars[rand.nextInt(chars.length)],
      ).join();
    }

    return 'gem-ai-${block(8)}-${block(4)}-${block(4)}-${block(4)}-${block(12)}';
  }

  Future<void> _rememberGuestKey(String sessionId) async {
    _prefs ??= await SharedPreferences.getInstance();
    final existing = _prefs!.getStringList(_guestKeysPrefKey) ?? <String>[];
    if (existing.contains(sessionId)) return;
    final next = [...existing, sessionId];
    if (next.length > 20) {
      next.removeRange(0, next.length - 20);
    }
    await _prefs!.setStringList(_guestKeysPrefKey, next);
    if (!ref.mounted) return;
  }

  Future<List<String>> _guestKeys() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getStringList(_guestKeysPrefKey) ?? const [];
  }

  void setLanguage(AiChatLanguage language) {
    state = state.copyWith(language: language, clearError: true);
  }

  void clearError() => state = state.copyWith(clearError: true);

  void clearPendingImage() => state = state.copyWith(clearPendingImage: true);

  Future<void> startNewChat() async {
    _cancelToken?.cancel('new-chat');
    final sessionId = _newSessionId();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_sessionPrefKey, sessionId);
    if (!ref.mounted) return;
    await _rememberGuestKey(sessionId);
    if (!ref.mounted) return;
    state = AiChatPanelState(sessionId: sessionId, language: state.language);
  }

  Future<void> pickAndUploadImage() async {
    if (state.isUploading || state.isSending) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (!ref.mounted) return;
    if (file == null) return;

    _cancelToken?.cancel('upload');
    _cancelToken = CancelToken();
    state = state.copyWith(isUploading: true, clearError: true);

    final result = await _repo.uploadImage(
      file: file,
      cancelToken: _cancelToken,
    );
    if (!ref.mounted) return;

    switch (result) {
      case Success(value: final url):
        state = state.copyWith(
          isUploading: false,
          pendingImageUrl: url,
          pendingImageName: file.name,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isUploading: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<void> sendMessage(String raw) async {
    final text = raw.trim();
    final imageUrl = state.pendingImageUrl;
    if ((text.isEmpty && (imageUrl == null || imageUrl.isEmpty)) ||
        state.isSending) {
      return;
    }

    final sessionId = state.sessionId.isEmpty
        ? _newSessionId()
        : state.sessionId;
    if (state.sessionId.isEmpty) {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(_sessionPrefKey, sessionId);
      if (!ref.mounted) return;
      await _rememberGuestKey(sessionId);
      if (!ref.mounted) return;
    }

    final localId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final userMessage = AiChatMessage(
      id: localId,
      role: AiChatRole.user,
      content: text.isEmpty ? 'Uploaded estimation image' : text,
      imageUrls: imageUrl == null ? const [] : [imageUrl],
      isLocal: true,
    );

    final history = state.messages
        .where((m) => m.content.trim().isNotEmpty)
        .map((m) => m.toHistoryTurn())
        .toList();

    state = state.copyWith(
      sessionId: sessionId,
      messages: [...state.messages, userMessage],
      isSending: true,
      clearError: true,
      clearPendingImage: true,
    );

    _cancelToken?.cancel('send');
    _cancelToken = CancelToken();

    final result = await _repo.chat(
      message: text.isEmpty ? null : text,
      history: history,
      sessionId: sessionId,
      imageUrls: imageUrl == null ? const [] : [imageUrl],
      language: state.language,
      cancelToken: _cancelToken,
    );
    if (!ref.mounted) return;

    switch (result) {
      case Success(value: final reply):
        final resolvedSession = reply.sessionId.isNotEmpty
            ? reply.sessionId
            : sessionId;
        if (resolvedSession != sessionId) {
          _prefs ??= await SharedPreferences.getInstance();
          await _prefs!.setString(_sessionPrefKey, resolvedSession);
          if (!ref.mounted) return;
          await _rememberGuestKey(resolvedSession);
          if (!ref.mounted) return;
        }
        final assistant = AiChatMessage(
          id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
          role: AiChatRole.assistant,
          content: reply.reply,
          products: reply.products,
          productGroups: reply.productGroups,
          totalFound: reply.totalFound,
          isLocal: true,
          sourceQuery: text,
        );
        state = state.copyWith(
          sessionId: resolvedSession,
          messages: [...state.messages, assistant],
          isSending: false,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(isSending: false, errorMessage: failure.message);
    }
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoadingHistory: true, clearError: true);
    final keys = await _guestKeys();
    if (!ref.mounted) return;
    final result = await _repo.listSessions(sessionKeys: keys, limit: 30);
    if (!ref.mounted) return;
    switch (result) {
      case Success(value: final sessions):
        state = state.copyWith(isLoadingHistory: false, sessions: sessions);
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isLoadingHistory: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<void> openSession(String sessionId) async {
    if (sessionId.isEmpty) return;
    state = state.copyWith(isLoadingSession: true, clearError: true);
    final result = await _repo.getSession(sessionId: sessionId);
    if (!ref.mounted) return;
    switch (result) {
      case Success(value: final detail):
        _prefs ??= await SharedPreferences.getInstance();
        await _prefs!.setString(_sessionPrefKey, detail.sessionId);
        if (!ref.mounted) return;
        await _rememberGuestKey(detail.sessionId);
        if (!ref.mounted) return;
        state = state.copyWith(
          sessionId: detail.sessionId,
          messages: detail.messages,
          isLoadingSession: false,
          clearPendingImage: true,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isLoadingSession: false,
          errorMessage: failure.message,
        );
    }
  }
}

final aiChatPanelProvider =
    NotifierProvider<AiChatPanelNotifier, AiChatPanelState>(
      AiChatPanelNotifier.new,
    );
