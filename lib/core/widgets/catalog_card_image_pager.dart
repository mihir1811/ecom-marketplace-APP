import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_network_image.dart';

/// Deduplicates and normalizes catalog listing image URLs.
List<String> catalogListingImageUrls({
  String? imageUrl,
  List<String> imageUrls = const [],
}) {
  final seen = <String>{};
  final out = <String>[];
  void add(String? raw) {
    final url = raw?.trim() ?? '';
    if (url.isEmpty || !seen.add(url)) return;
    out.add(url);
  }

  for (final url in imageUrls) {
    add(url);
  }
  add(imageUrl);
  return out;
}

/// Listing-card media: single image, or horizontal swipe when multiple URLs.
///
/// No page dots or counters — swipe only.
class CatalogCardImagePager extends StatelessWidget {
  const CatalogCardImagePager({
    required this.imageUrls,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.memCacheWidth = 400,
    this.backgroundColor,
    super.key,
  });

  final List<String> imageUrls;
  final Widget fallback;
  final BoxFit fit;
  final int memCacheWidth;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.surface(context);
    if (imageUrls.isEmpty) return fallback;

    Widget page(String url) {
      return AppNetworkImage(
        url: url,
        fit: fit,
        memCacheWidth: memCacheWidth,
        error: fallback,
      );
    }

    if (imageUrls.length == 1) {
      return ColoredBox(color: bg, child: SizedBox.expand(child: page(imageUrls.first)));
    }

    return ColoredBox(
      color: bg,
      child: PageView.builder(
        itemCount: imageUrls.length,
        allowImplicitScrolling: true,
        itemBuilder: (context, index) => page(imageUrls[index]),
      ),
    );
  }
}
