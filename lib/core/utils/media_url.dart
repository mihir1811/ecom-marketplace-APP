import '../network/api_config.dart';
import 'cdn_image_url.dart';

/// Resolves API-relative media paths to absolute URLs for image widgets.
abstract final class MediaUrl {
  /// Returns a loadable http(s)/data/blob URL, or null when [raw] is empty.
  static String? resolve(String? raw) {
    final cleaned = raw?.trim();
    if (cleaned == null || cleaned.isEmpty) return null;

    final lower = cleaned.toLowerCase();
    if (lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('data:') ||
        lower.startsWith('blob:')) {
      return CdnImageUrl.normalize(cleaned) ?? cleaned;
    }

    final origin = Uri.parse(ApiConfig.baseUrl).origin;
    final path = cleaned.startsWith('/') ? cleaned : '/$cleaned';
    final absolute = '$origin$path';
    return CdnImageUrl.normalize(absolute) ?? absolute;
  }
}
