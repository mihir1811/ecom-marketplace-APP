import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Crashlytics, on in release builds only.
///
/// Native crashes are captured by the SDK itself. Dart errors arrive here:
/// framework errors (the user sees the app's error screen, the app keeps
/// running) and uncaught async errors are recorded as non-fatal reports.
/// Release builds are obfuscated: upload the symbols from
/// `build/symbols/<version>` (see scripts/build_release_apk.ps1) so stacks
/// are readable in the console.
abstract final class CrashReporting {
  static bool _enabled = false;

  /// Call once Firebase is initialised. Web is not supported by Crashlytics.
  static Future<void> init({required bool firebaseReady}) async {
    if (kIsWeb || !firebaseReady) return;
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        kReleaseMode,
      );
      _enabled = kReleaseMode;
    } catch (_) {
      _enabled = false;
    }
  }

  static void recordFlutterError(FlutterErrorDetails details) {
    if (!_enabled) return;
    FirebaseCrashlytics.instance.recordFlutterError(details);
  }

  static void recordError(Object error, StackTrace stack, {String? reason}) {
    if (!_enabled) return;
    FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
  }
}
