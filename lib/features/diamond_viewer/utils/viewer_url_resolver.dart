/// Normalizes API `videoURL` values into a loadable 360 viewer URL.
abstract final class ViewerUrlResolver {
  static const String s3Base =
      'https://diamondshow.s3.ap-south-1.amazonaws.com';
  static const String workshopViewBase = 'https://workshop.360view.link/view';

  /// Returns a sanitized absolute URL, or `null` when the input is unusable.
  static String? resolve(String? raw, {bool httpsOnly = true}) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final asUri = Uri.tryParse(trimmed);
    if (asUri != null && asUri.hasScheme) {
      if (httpsOnly && asUri.scheme != 'https') return null;
      if (asUri.scheme != 'http' && asUri.scheme != 'https') return null;
      if (asUri.host.isEmpty) return null;

      // Prefer the interactive workshop viewer when the API hands us an
      // analytics / data deep-link instead of the view page.
      final rewritten = _rewrite360ViewDeepLink(asUri);
      return rewritten ?? asUri.toString();
    }

    final id = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    if (id.isEmpty || id.contains(' ')) return null;

    // Bare stock ids from 360view-style APIs (e.g. 2703255-BM1665-111-A).
    if (_looksLike360ViewId(id)) {
      return '$workshopViewBase/$id';
    }

    return '$s3Base/$id';
  }

  static bool _looksLike360ViewId(String id) {
    // Typical pattern: numericPrefix-stockCode (contains hyphen, not a plain path).
    return id.contains('-') && !id.contains('/');
  }

  /// Maps analytics.360view.link?...dataUrl=https://workshop.../view/ID → view URL.
  static String? _rewrite360ViewDeepLink(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host == 'analytics.360view.link') {
      final dataUrl = uri.queryParameters['dataUrl'];
      if (dataUrl != null && dataUrl.isNotEmpty) {
        return resolve(dataUrl);
      }
    }
    return null;
  }
}
