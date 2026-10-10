/// Central API host configuration for catalog HTTP calls.
abstract final class ApiConfig {
  /// Override via `.env` / CI: `--dart-define-from-file=.env`
  /// or `--dart-define=API_BASE_URL=https://host/api/v1`.
  ///
  /// Default is the shared API host (not localhost) so physical-device /
  /// release builds work without dart-defines. Localhost only works on the
  /// machine running the backend.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://15.252.107.13:3000/api/v1',
  );

  /// Socket.IO origin (API host without `/api/v1`).
  static String get socketBaseUrl {
    final uri = Uri.parse(baseUrl);
    final path = uri.path.replaceAll(RegExp(r'/api/v1/?$'), '');
    return uri
        .replace(path: path.isEmpty ? '' : path)
        .toString()
        .replaceAll(RegExp(r'/$'), '');
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
