import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Why a listen session ended without words.
enum SpeechFailure {
  /// Silence or nothing recognised; worth listening again.
  soft,

  /// Recognizer still winding down from the last session; retry shortly.
  busy,

  /// Microphone or speech permission denied.
  permission,

  /// Cloud recognizer could not be reached.
  network,

  /// Requested language is not installed or supported.
  language,

  /// Microphone is in use elsewhere or failed.
  audio,

  /// Anything else.
  other,
}

/// On-device speech-to-text (free platform recognizers via `speech_to_text`).
///
/// The plugin binds its status/error callbacks once at init, so this
/// service forwards them to whichever session is currently listening.
class SpeechInputService {
  SpeechInputService({SpeechToText? engine}) : _stt = engine ?? SpeechToText();

  final SpeechToText _stt;
  bool _ready = false;
  List<String>? _localeIds;
  void Function(String words, bool isFinal)? _onResult;
  VoidCallback? _onStopped;
  void Function(SpeechFailure failure)? _onError;

  bool get isListening => _stt.isListening;

  /// Asks for mic/speech permission on first use. False when unavailable.
  Future<bool> ensureReady() async {
    if (_ready) return true;
    try {
      _ready = await _stt.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
    } catch (error) {
      debugPrint('Gem Agent speech init failed: $error');
      _ready = false;
    }
    return _ready;
  }

  /// Whether the mic permission was granted (false also when unknown).
  Future<bool> hasPermission() async {
    try {
      return await _stt.hasPermission;
    } catch (_) {
      return false;
    }
  }

  /// [preferred] (`en_IN`) when the recognizer has it, else the same
  /// language in another region, else null for the device default.
  Future<String?> resolveLocale(String preferred) async {
    // Web Speech takes a BCP-47 tag and cannot list its languages.
    if (kIsWeb) return preferred.replaceAll('_', '-');
    try {
      _localeIds ??= (await _stt.locales()).map((l) => l.localeId).toList();
    } catch (_) {
      return null;
    }
    String norm(String id) => id.replaceAll('-', '_').toLowerCase();
    final want = norm(preferred);
    final lang = want.split('_').first;
    String? sameLanguage;
    for (final id in _localeIds!) {
      final n = norm(id);
      if (n == want) return id;
      if (sameLanguage == null && n.split('_').first == lang) sameLanguage = id;
    }
    return sameLanguage;
  }

  Future<void> start({
    required String? localeId,
    required void Function(String words, bool isFinal) onResult,
    required VoidCallback onStopped,
    required void Function(SpeechFailure failure) onError,
    void Function(double level)? onLevel,
  }) async {
    if (_stt.isListening) await cancel();
    _onResult = onResult;
    _onStopped = onStopped;
    _onError = onError;
    try {
      await _stt.listen(
        onResult: _handleResult,
        onSoundLevelChange: onLevel,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          // Errors are handled by the caller, which may listen again.
          cancelOnError: false,
          listenMode: ListenMode.search,
          localeId: localeId,
          // No pause cut-off: the user ends capture with the stop button.
          listenFor: const Duration(minutes: 10),
        ),
      );
    } catch (error) {
      debugPrint('Gem Agent speech listen failed: $error');
      final report = _onError;
      _clear();
      report?.call(SpeechFailure.busy);
    }
  }

  Future<void> stop() => _stt.stop();

  Future<void> cancel() async {
    _clear();
    await _stt.cancel();
  }

  void _clear() {
    _onResult = null;
    _onStopped = null;
    _onError = null;
  }

  void _handleResult(SpeechRecognitionResult result) =>
      _onResult?.call(result.recognizedWords, result.finalResult);

  void _handleStatus(String status) {
    if (status == SpeechToText.doneStatus) _onStopped?.call();
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint('Gem Agent speech error: ${error.errorMsg}');
    _onError?.call(classify(error.errorMsg));
  }

  /// Maps Android/iOS (`error_*`) and Web Speech error codes.
  @visibleForTesting
  static SpeechFailure classify(String code) => switch (code) {
    'error_no_match' ||
    'error_speech_timeout' ||
    'no-speech' ||
    'error_retry' => SpeechFailure.soft,
    'error_busy' ||
    'error_client' ||
    'error_too_many_requests' ||
    'aborted' => SpeechFailure.busy,
    'error_permission' ||
    'not-allowed' ||
    'service-not-allowed' => SpeechFailure.permission,
    'error_network' ||
    'error_network_timeout' ||
    'error_server' ||
    'error_server_disconnected' ||
    'network' => SpeechFailure.network,
    'error_language_not_supported' ||
    'error_language_unavailable' ||
    'language-not-supported' => SpeechFailure.language,
    'error_audio_error' || 'audio-capture' => SpeechFailure.audio,
    _ => SpeechFailure.other,
  };
}
