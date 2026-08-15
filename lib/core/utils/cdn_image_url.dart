/// Fixes known CDN path casing so catalog thumbs load (S3 keys are case-sensitive).
///
/// Diamond listing APIs often return `.../stillimage/{id}.jpg` which 403s; the
/// bucket object lives under `StillImage`.
abstract final class CdnImageUrl {
  static const String diamondshowS3Host =
      'diamondshow.s3.ap-south-1.amazonaws.com';

  static String? normalize(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return trimmed;

    if (uri.host.toLowerCase() != diamondshowS3Host) return trimmed;

    final segments =
        uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
    var changed = false;
    for (var i = 0; i < segments.length; i++) {
      if (segments[i].toLowerCase() == 'stillimage') {
        segments[i] = 'StillImage';
        changed = true;
      }
    }
    if (!changed) return trimmed;
    return uri.replace(pathSegments: segments).toString();
  }
}
