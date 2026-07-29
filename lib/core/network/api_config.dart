/// Central API host configuration for catalog HTTP calls.
abstract final class ApiConfig {
  /// Override at build time: `--dart-define=API_BASE_URL=https://host/api/v1`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://15.252.107.13:3000/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
