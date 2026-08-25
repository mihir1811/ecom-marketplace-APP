import 'package:flutter/foundation.dart';

import '../../../core/network/api_config.dart';

/// Builds in-app share deep links that open `/share/:token` in GemWorld.
abstract final class ProductShareUrls {
  /// Optional public web origin, e.g. `https://app.gemworld.com`.
  static const String webAppOrigin = String.fromEnvironment(
    'WEB_APP_ORIGIN',
    defaultValue: '',
  );

  /// Absolute URL recipients should open (rewrites API `localhost:8000` links).
  static String forToken(String token, {String? apiShareUrl}) {
    final clean = token.trim();
    if (clean.isEmpty) return '';
    final path = '/share/${Uri.encodeComponent(clean)}';
    final origin = publicWebOrigin(apiShareUrl: apiShareUrl);
    if (origin == null) return path;
    return '$origin/#$path';
  }

  /// Prefer [token] over parsing brittle API hosts (`localhost:8000`, …).
  static String rewriteApiShareUrl({
    required String token,
    String? apiShareUrl,
  }) {
    final fromToken = forToken(token, apiShareUrl: apiShareUrl);
    if (fromToken.startsWith('http://') || fromToken.startsWith('https://')) {
      return fromToken;
    }
    final api = apiShareUrl?.trim() ?? '';
    if (api.startsWith('http://') || api.startsWith('https://')) {
      return forToken(
        token.isEmpty ? tokenFromShareUrl(api) : token,
        apiShareUrl: api,
      );
    }
    return fromToken.isNotEmpty ? fromToken : api;
  }

  /// Origin used for copied/shared links. Never omit this on native.
  static String? publicWebOrigin({String? apiShareUrl}) {
    final configured = webAppOrigin.trim().replaceAll(RegExp(r'/$'), '');
    if (configured.isNotEmpty) return configured;

    if (kIsWeb) {
      final base = Uri.base;
      if (_isHttpOrigin(base)) return base.origin;
    }

    final fromApi = _httpOrigin(apiShareUrl, allowLoopback: kIsWeb);
    if (fromApi != null) return fromApi;

    return _httpOrigin(ApiConfig.baseUrl, allowLoopback: true);
  }

  static bool _isHttpOrigin(Uri uri) {
    return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  static bool _isLoopback(String host) {
    final h = host.toLowerCase();
    return h == 'localhost' || h == '127.0.0.1' || h == '::1' || h == '0.0.0.0';
  }

  static String? _httpOrigin(String? raw, {required bool allowLoopback}) {
    if (raw == null || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !_isHttpOrigin(uri)) return null;
    if (!allowLoopback && _isLoopback(uri.host)) return null;
    return uri.origin;
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
