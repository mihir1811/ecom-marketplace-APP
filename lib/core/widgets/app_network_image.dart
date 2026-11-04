import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';

import '../theme/app_colors.dart';
import '../utils/cdn_image_url.dart';
import 'fit_resize_image.dart';

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
    this.placeholder,
    this.fullResolution = false,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;

  /// Shown on load failure (bad URL, 4xx/5xx, etc.).
  final Widget? error;

  /// Shown while loading; defaults to a small spinner.
  final Widget? placeholder;

  /// Keep the full-resolution decode, for zoomable viewers. Otherwise, when
  /// [memCacheWidth] is not given, the image is decoded at the size it is
  /// laid out at (see [FitResizeImage]).
  final bool fullResolution;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = CdnImageUrl.normalize(url) ?? url;
    if (!_supportsNetworkLoading(resolvedUrl)) {
      return error ?? _fallback(context);
    }

    final image = kIsWeb ? _webImage(resolvedUrl) : _nativeImage(resolvedUrl);

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  bool _supportsNetworkLoading(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) return false;
    if (!uri.hasScheme) return true;
    if (!kIsWeb) return true;

    return switch (uri.scheme) {
      'http' || 'https' || 'data' || 'blob' => true,
      _ => false,
    };
  }

  /// HTML `<img>` path — avoids browser CORS blocks on cross-origin CDNs.
  Widget _webImage(String imageUrl) {
    // HTML images can report unbounded intrinsics; expand into parent bounds.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w =
            width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : null);
        final h =
            height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : null);
        final image = Image.network(
          imageUrl,
          fit: fit,
          width: w,
          height: h,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholder(context);
          },
          errorBuilder: (context, __, ___) => error ?? _fallback(context),
        );
        if (w != null && h != null) return image;
        if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
          return SizedBox.expand(child: image);
        }
        return image;
      },
    );
  }

  Widget _nativeImage(String imageUrl) {
    if (memCacheWidth == null && !fullResolution) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = width ?? constraints.maxWidth;
          final h = height ?? constraints.maxHeight;
          if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
            return _cachedImage(imageUrl);
          }
          final dpr = MediaQuery.devicePixelRatioOf(context);
          // Same widget and settings CachedNetworkImage uses internally, with
          // the decode sized to the box.
          return OctoImage(
            image: FitResizeImage(
              CachedNetworkImageProvider(imageUrl),
              width: (w * dpr).ceil(),
              height: (h * dpr).ceil(),
              fit: fit,
            ),
            placeholderBuilder: (context) => _placeholder(context),
            errorBuilder: (context, _, _) => error ?? _fallback(context),
            fadeOutDuration: const Duration(milliseconds: 1000),
            fadeOutCurve: Curves.easeOut,
            fadeInDuration: const Duration(milliseconds: 280),
            fadeInCurve: Curves.easeIn,
            width: width,
            height: height,
            fit: fit,
            filterQuality: FilterQuality.low,
          );
        },
      );
    }
    return _cachedImage(imageUrl);
  }

  Widget _cachedImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 280),
      placeholder: (context, __) => _placeholder(context),
      errorWidget: (context, __, ___) => error ?? _fallback(context),
    );
  }

  Widget _placeholder(BuildContext context) =>
      placeholder ??
      ColoredBox(
        color: AppColors.surface(context),
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

  Widget _fallback(BuildContext context) => ColoredBox(
    color: AppColors.surface(context),
    child: Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.bronzeLight,
        size: 28,
      ),
    ),
  );
}
