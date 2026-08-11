/// Builds in-app share deep links that open `/share/:token` in GemWorld.
abstract final class ProductShareUrls {
  /// Optional public web origin, e.g. `https://app.gemworld.com`.
  static const String webAppOrigin = String.fromEnvironment(
    'WEB_APP_ORIGIN',
    defaultValue: '',
  );

  /// Absolute URL recipients should open (rewrites API `localhost:8000` links).
  static String forToken(String token) {
    final clean = token.trim();
    if (clean.isEmpty) return '';
    final path = '/share/${Uri.encodeComponent(clean)}';

    final configured = webAppOrigin.trim().replaceAll(RegExp(r'/$'), '');
    if (configured.isNotEmpty) {
      return '$configured/#$path';
    }

    final base = Uri.base;
    if (base.hasScheme &&
        (base.scheme == 'http' || base.scheme == 'https') &&
        base.host.isNotEmpty) {
      // Flutter web defaults to hash URL strategy.
      return '${base.origin}/#$path';
    }

    return path;
  }

  /// Prefer [token] over parsing brittle API hosts (`localhost:8000`, …).
  static String rewriteApiShareUrl({
    required String token,
    String? apiShareUrl,
  }) {
    final fromToken = forToken(token);
    if (fromToken.isNotEmpty) return fromToken;
    return apiShareUrl?.trim() ?? '';
  }
}
