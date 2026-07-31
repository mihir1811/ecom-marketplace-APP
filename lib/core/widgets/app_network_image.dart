import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared network image with shimmer-style placeholder and graceful fallback.
///
/// On web, loads via an HTML `<img>` element ([WebHtmlElementStrategy.prefer])
/// so third-party hosts without `Access-Control-Allow-Origin` (S3, Nivoda CDN,
/// 360view stills, etc.) still render. CanvasKit/XHR fetches require CORS;
/// `<img>` display does not.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.url,
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.memCacheWidth,
    this.error,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;

  /// Shown on load failure (bad URL, 4xx/5xx, etc.).
  final Widget? error;

  bool get _supportsNetworkLoading {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (!uri.hasScheme) return true;
    if (!kIsWeb) return true;

    return switch (uri.scheme) {
      'http' || 'https' || 'data' || 'blob' => true,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsNetworkLoading) {
      return error ?? _fallback();
    }

    final image = kIsWeb ? _webImage() : _nativeImage();

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  /// HTML `<img>` path — avoids browser CORS blocks on cross-origin CDNs.
  Widget _webImage() {
    // HTML images can report unbounded intrinsics; expand into parent bounds.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : null);
        final h = height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : null);
        final image = Image.network(
          url,
          fit: fit,
          width: w,
          height: h,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholder();
          },
          errorBuilder: (_, __, ___) => error ?? _fallback(),
        );
        if (w != null && h != null) return image;
        if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
          return SizedBox.expand(child: image);
        }
        return image;
      },
    );
  }

  Widget _nativeImage() {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 280),
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => error ?? _fallback(),
    );
  }

  Widget _placeholder() => const ColoredBox(
        color: AppColors.sandSurface,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.bronze,
            ),
          ),
        ),
      );

  Widget _fallback() => const ColoredBox(
        color: AppColors.sandSurface,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.bronzeLight,
            size: 28,
          ),
        ),
      );
}
