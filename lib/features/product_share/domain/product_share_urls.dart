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

    // Native / unknown host: keep a path recipients can open once the web
    // app is deployed; prefer setting WEB_APP_ORIGIN for production shares.
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

  /// Extracts a share token from API path URLs or in-app hash URLs.
  static String tokenFromShareUrl(String shareUrl) {
    final uri = Uri.tryParse(shareUrl.trim());
    if (uri == null) return '';

    final fragment = uri.fragment.trim();
    if (fragment.isNotEmpty) {
      final fragPath = fragment.startsWith('/') ? fragment : '/$fragment';
      final fragUri = Uri.tryParse(fragPath);
      final fromFrag = _tokenFromPathSegments(fragUri?.pathSegments ?? const []);
      if (fromFrag.isNotEmpty) return fromFrag;
    }

    return _tokenFromPathSegments(uri.pathSegments);
  }

  static String _tokenFromPathSegments(List<String> segments) {
    if (segments.isEmpty) return '';
    final idx = segments.lastIndexOf('share');
    if (idx >= 0 && idx + 1 < segments.length) {
      return Uri.decodeComponent(segments[idx + 1]);
    }
    return Uri.decodeComponent(segments.last);
  }
}
