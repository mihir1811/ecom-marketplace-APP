import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared network image with shimmer-style placeholder and graceful fallback.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.url,
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.memCacheWidth,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;

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
      return _fallback();
    }

    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 280),
      placeholder: (_, __) => const ColoredBox(
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
      ),
      errorWidget: (_, __, ___) => _fallback(),
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

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
