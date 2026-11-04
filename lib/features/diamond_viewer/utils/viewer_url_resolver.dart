import '../../../core/utils/cdn_image_url.dart';

/// Normalizes API `videoURL` values into a loadable 360 viewer URL.
abstract final class ViewerUrlResolver {
  static const String s3Base =
      'https://diamondshow.s3.ap-south-1.amazonaws.com';
  static const String workshopViewBase = 'https://workshop.360view.link/view';
  static const String stillCdnBase = 'https://data1.360view.link/data/1/imaged';

  /// Returns a sanitized absolute URL, or `null` when the input is unusable.
  static String? resolve(String? raw, {bool httpsOnly = true}) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    // CDN still frames belong to the interactive viewer, not as a viewer page.
    final fromStill = viewerUrlFromStillAsset(trimmed);
    if (fromStill != null) return fromStill;

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

  /// True for 360view CDN still frames (listing thumbnails / gallery stills).
  static bool isStillAssetUrl(String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    if (!host.endsWith('360view.link')) return false;
    if (host == 'workshop.360view.link') return false;
    final path = uri.path.toLowerCase();
    return path.contains('/imaged/') || path.endsWith('/still.jpg');
  }

  /// Workshop viewer URL from a CDN still path.
  static String? viewerUrlFromStillAsset(String? url) {
    if (!isStillAssetUrl(url)) return null;
    final uri = Uri.tryParse(url!.trim());
    if (uri == null) return null;
    final segments = uri.pathSegments
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final imagedIdx = segments.indexWhere((s) => s.toLowerCase() == 'imaged');
    if (imagedIdx >= 0 && imagedIdx + 1 < segments.length) {
      final id = segments[imagedIdx + 1].trim();
      if (id.isNotEmpty && !_looksLikeFileName(id)) {
        return '$workshopViewBase/$id';
      }
    }
    return null;
  }

  /// Listing/gallery photo URL — see [CdnImageUrl.normalize].
  static String? normalizeImageUrl(String? raw) => CdnImageUrl.normalize(raw);

  /// Listing/gallery still when API only returns `videoURL`.
  static String? stillUrlFromViewer(String? viewerUrl) {
    final resolved = resolve(viewerUrl);
    if (resolved == null) return null;
    final uri = Uri.tryParse(resolved);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments
        .where((s) => s.trim().isNotEmpty)
        .toList();

    // diamondshow S3 viewer HTML lives at `/{id}` — still is `/StillImage/{id}.jpg`.
    if (host == CdnImageUrl.diamondshowS3Host) {
      if (segments.length == 1) {
        final id = segments.first.trim();
        if (id.isNotEmpty && !_looksLikeFileName(id)) {
          return '$s3Base/StillImage/$id.jpg';
        }
      }
      if (segments.length >= 2 &&
          segments.first.toLowerCase() == 'stillimage') {
        final file = segments[1].trim();
        if (file.isNotEmpty) {
          return CdnImageUrl.normalize('$s3Base/StillImage/$file');
        }
      }
      return null;
    }

    if (host != 'workshop.360view.link') return null;
    // /view/{id}
    final viewIdx = segments.indexWhere((s) => s.toLowerCase() == 'view');
    final id = viewIdx >= 0 && viewIdx + 1 < segments.length
        ? segments[viewIdx + 1].trim()
        : (segments.isNotEmpty ? segments.last.trim() : '');
    if (id.isEmpty || _looksLikeFileName(id)) return null;
    return '$stillCdnBase/$id/still.jpg';
  }

  static bool _looksLikeFileName(String segment) {
    final lower = segment.toLowerCase();
    return lower.contains('.') &&
        (lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp') ||
            lower.endsWith('.gif'));
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
