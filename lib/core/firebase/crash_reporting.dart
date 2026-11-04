// Crashlytics on Android/iOS; a no-op on web (Crashlytics has no web SDK,
// and loading the plugin there breaks the dev compiler).
export 'crash_reporting_stub.dart'
    if (dart.library.io) 'crash_reporting_io.dart';
