import 'package:flutter/foundation.dart';

/// Web build: no crash reporting.
abstract final class CrashReporting {
  static Future<void> init({required bool firebaseReady}) async {}

  static void recordFlutterError(FlutterErrorDetails details) {}

  static void recordError(Object error, StackTrace stack, {String? reason}) {}
}
