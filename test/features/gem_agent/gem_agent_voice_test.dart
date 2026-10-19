import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/error/result.dart';
import 'package:gemstone/features/gem_agent/application/gem_agent_controller.dart';
import 'package:gemstone/features/gem_agent/application/gem_agent_providers.dart';
import 'package:gemstone/features/gem_agent/application/gem_agent_state.dart';
import 'package:gemstone/features/gem_agent/application/speech_input_service.dart';
import 'package:gemstone/features/gem_agent/domain/llm_client.dart';

/// Recognizer the test drives by hand.
class _FakeSpeech implements SpeechInputService {
  bool ready = true;
  bool permitted = true;
  int starts = 0;
  bool _listening = false;
  void Function(String words, bool isFinal)? _onResult;
  VoidCallback? _onStopped;
  void Function(SpeechFailure failure)? _onError;

  @override
  bool get isListening => _listening;

  @override
  Future<bool> ensureReady() async => ready;

  @override
  Future<bool> hasPermission() async => permitted;

  @override
  Future<String?> resolveLocale(String preferred) async => preferred;

  @override
  Future<void> start({
    required String? localeId,
    required void Function(String words, bool isFinal) onResult,
    required VoidCallback onStopped,
    required void Function(SpeechFailure failure) onError,
    void Function(double level)? onLevel,
  }) async {
    starts++;
    _listening = true;
    _onResult = onResult;
    _onStopped = onStopped;
    _onError = onError;
  }

  @override
  Future<void> stop() async {
    _listening = false;
    _onStopped?.call();
  }

  @override
  Future<void> cancel() async {
    _listening = false;
    _onResult = _onStopped = _onError = null;
  }

  void say(String words, {bool isFinal = false}) =>
      _onResult?.call(words, isFinal);

  /// The platform ending a session on its own (pause, silence).
  void end([SpeechFailure? failure]) {
    _listening = false;
    if (failure == null) {
      _onStopped?.call();
    } else {
      _onError?.call(failure);
    }
  }
}

/// Model that never answers, so the turn stays in flight.
class _PendingLlm implements LlmClient {
  @override
  Future<Result<LlmResponse, LlmFailure>> complete(
    LlmRequest request, {
    CancelToken? cancelToken,
  }) => Completer<Result<LlmResponse, LlmFailure>>().future;
}

void main() {
  late _FakeSpeech speech;
  late ProviderContainer container;
  GemAgentController controller() =>
      container.read(gemAgentControllerProvider.notifier);
  GemAgentState state() => container.read(gemAgentControllerProvider);

  Future<void> settle() => Future<void>.delayed(const Duration(seconds: 1));

  setUp(() {
    speech = _FakeSpeech();
    container = ProviderContainer(
      overrides: [
        gemAgentSpeechProvider.overrideWithValue(speech),
        gemAgentLlmProvider.overrideWithValue(_PendingLlm()),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('silence does not close the mic', () async {
    await controller().open();
    expect(state().phase, GemAgentPhase.listening);

    speech.end(SpeechFailure.soft);
    await settle();
    speech.end();
    await settle();

    expect(state().phase, GemAgentPhase.listening);
    expect(speech.starts, 3);
    expect(state().notice, isNull);
  });

  test('keeps listening across pauses and sends everything on stop', () async {
    await controller().open();
    speech.say('two carat', isFinal: true);
    speech.end();
    await settle();

    expect(state().phase, GemAgentPhase.listening);
    expect(state().liveTranscript, 'two carat');

    speech.say('round');
    expect(state().liveTranscript, 'two carat round');

    await controller().stopListening();
    expect(state().phase, GemAgentPhase.thinking);
    expect(state().entries.last.text, 'two carat round');
  });

  test('stop with nothing heard goes idle without a request', () async {
    await controller().open();
    await controller().stopListening();
    expect(state().phase, GemAgentPhase.idle);
    expect(state().entries, isEmpty);
  });

  test('denied permission keeps the mic button for a retry', () async {
    speech
      ..ready = false
      ..permitted = false;
    await controller().open();
    expect(state().phase, GemAgentPhase.idle);
    expect(state().voiceAvailable, isTrue);
    expect(state().notice, contains('Settings'));
  });

  test('closing the sheet ends listening', () async {
    await controller().open();
    await controller().close();
    speech.end();
    await settle();
    expect(speech.starts, 1);
    expect(speech.isListening, isFalse);
  });
}
