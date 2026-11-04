/// Central API host configuration for catalog HTTP calls.
abstract final class ApiConfig {
  /// Override via `.env` / CI: `--dart-define-from-file=.env`
  /// or `--dart-define=API_BASE_URL=https://host/api/v1`.
  ///
  /// Default is the production API over HTTPS so release builds work without
  /// dart-defines. Localhost only works on the machine running the backend.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.gemworld.in/api/v1',
  );

  /// Production API host. Its nginx does not forward WebSocket upgrades yet,
  /// so sockets for this host go to [_productionSocketOrigin] instead.
  static const String _productionApiHost = 'api.gemworld.in';

  /// Direct origin of the production API (behind the nginx above).
  /// Remove once nginx forwards `Upgrade`/`Connection` headers; sockets then
  /// follow [baseUrl] like every other host.
  static const String _productionSocketOrigin = 'http://15.252.107.13:3000';

  /// Optional explicit Socket.IO origin (`--dart-define=SOCKET_BASE_URL=...`).
  static const String _socketOverride = String.fromEnvironment(
    'SOCKET_BASE_URL',
  );

  /// Socket.IO origin (API host without `/api/v1`).
  static String get socketBaseUrl {
    if (_socketOverride.isNotEmpty) return _socketOverride;
    final uri = Uri.parse(baseUrl);
    if (uri.host == _productionApiHost) return _productionSocketOrigin;
    final path = uri.path.replaceAll(RegExp(r'/api/v1/?$'), '');
    return uri
        .replace(path: path.isEmpty ? '' : path)
        .toString()
        .replaceAll(RegExp(r'/$'), '');
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
