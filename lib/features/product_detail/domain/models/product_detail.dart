import 'package:flutter/widgets.dart';

import '../../../buyer/domain/models/wishlist_item.dart';

/// Marketplace segments that share the single product detail presentation.
enum ProductSegment {
  naturalDiamond('Natural Diamond', 'natural-diamond'),
  labGrownDiamond('Lab Grown Diamond', 'lab-grown-diamond'),
  gemstone('Gemstone', 'gemstone'),
  jewelry('Jewelry', 'jewelry'),
  watch('Watch', 'watch'),
  bullion('Bullion', 'bullion');

  const ProductSegment(this.label, this.slug);

  final String label;
  final String slug;
}

enum ProductBadgeTone { neutral, accent, positive, caution }

/// Short status pill rendered under the product title.
class ProductBadge {
  const ProductBadge(this.label, {this.tone = ProductBadgeTone.neutral});

  final String label;
  final ProductBadgeTone tone;
}

/// A single hero image, sourced from the network or from bundled assets.
class ProductImage {
  const ProductImage.network(this.path) : isAsset = false;
  const ProductImage.asset(this.path) : isAsset = true;

  final String path;
  final bool isAsset;
}

enum ProductShowcaseAssetType { image, certificate, video }

class ProductShowcaseAsset {
  const ProductShowcaseAsset({
    required this.type,
    required this.label,
    this.imageIndex,
  });

  final ProductShowcaseAssetType type;
  final String label;
  final int? imageIndex;
}

/// Hero media for a product, with a typed fallback when no image exists.
class ProductMedia {
  const ProductMedia({
    required this.fallbackIcon,
    required this.fallbackTint,
    this.images = const [],
    this.imageSlots = 4,
    this.certificateLabel,
    this.certificateUrl,
    this.shapeKey,
    this.fit = BoxFit.cover,
    this.hasVideo = false,
    this.videoLabel,
    this.videoUrl,
  });

  final List<ProductImage> images;
  final int imageSlots;
  final String? certificateLabel;

  /// HTTPS certificate PDF/HTML page opened in the system browser when present.
  final String? certificateUrl;

  /// Shape name used for SVG placeholders when no product photo exists.
  final String? shapeKey;
  final IconData fallbackIcon;
  final Color fallbackTint;
  final BoxFit fit;
  final bool hasVideo;
  final String? videoLabel;

  /// Vision360 (or similar) viewer URL from API `videoURL`.
  final String? videoUrl;

  bool get hasInteractiveVideo {
    final url = videoUrl?.trim();
    return url != null && url.isNotEmpty;
  }

  String? get firstNetworkUrl {
    for (final image in images) {
      if (!image.isAsset) return image.path;
    }
    return null;
  }

  String? get firstAssetPath {
    for (final image in images) {
      if (image.isAsset) return image.path;
    }
    return null;
  }

  bool get hasCertificate {
    final url = certificateUrl?.trim();
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('www.');
  }

  /// Only real media — never pads empty image slots.
  List<ProductShowcaseAsset> get showcaseAssets {
    final assets = <ProductShowcaseAsset>[];
    final imageCount = images.length > 6 ? 6 : images.length;
    for (var i = 0; i < imageCount; i++) {
      assets.add(
        ProductShowcaseAsset(
          type: ProductShowcaseAssetType.image,
          label: '',
          imageIndex: i,
        ),
      );
    }
    // Interactive 360 stays a CTA; placeholder video tiles only when no URL.
    if (!hasInteractiveVideo && hasVideo) {
      assets.add(
        ProductShowcaseAsset(
          type: ProductShowcaseAssetType.video,
          label: videoLabel ?? 'Video',
        ),
      );
    }
    return assets;
  }

  ProductImage? imageAt(int index) {
    if (images.isEmpty) return null;
    return images[index % images.length];
  }
}

/// Price block content. [priceUsd] / [priceInr] exist so any segment can be
/// handed to the shared cart regardless of the currency it is quoted in.
class ProductPrice {
  const ProductPrice({
    required this.currencySymbol,
    required this.amountLabel,
    required this.priceUsd,
    required this.priceInr,
    this.unitLabel,
    this.unitAmountLabel,
    this.discountPercent,
  });

  final String currencySymbol;
  final String amountLabel;
  final double priceUsd;
  final double priceInr;

  /// e.g. `per carat`, `per gram`.
  final String? unitLabel;
  final String? unitAmountLabel;
  final double? discountPercent;

  String get display => '$currencySymbol$amountLabel';

  String? get unitDisplay {
    if (unitAmountLabel == null || unitLabel == null) return null;
    return '$currencySymbol$unitAmountLabel $unitLabel';
  }
}

/// One of the four value-defining attributes shown in the key facts grid.
class ProductHighlight {
  const ProductHighlight(this.label, this.value);

  final String label;
  final String value;
}

/// Grading authority and report reference used for the trust row.
class ProductCertification {
  const ProductCertification({
    required this.authority,
    this.referenceLabel,
    this.referenceValue,
    this.certificateUrl,
    this.certificateLabel,
  });

  final String authority;
  final String? referenceLabel;
  final String? referenceValue;

  /// Opens in the system browser via the "View certification" action.
  final String? certificateUrl;
  final String? certificateLabel;

  bool get hasCertificateLink {
    final url = certificateUrl?.trim();
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('www.');
  }
}

enum ProductStockTone { available, limited, unavailable }

class ProductAvailability {
  const ProductAvailability({
    required this.label,
    required this.tone,
    this.detail,
  });

  final String label;
  final ProductStockTone tone;
  final String? detail;
}

/// Fixed vocabulary of specification groups. Declaration order is the order
/// sections appear on screen, which is what keeps every segment consistent.
enum ProductSpecGroup {
  essentials('Essentials'),
  quality('Quality & Grading'),
  material('Material & Composition'),
  measurements('Measurements'),
  provenance('Certification & Provenance'),
  inclusions('Included & Options');

  const ProductSpecGroup(this.title);

  final String title;
}

class ProductSpec {
  const ProductSpec(this.label, this.value);

  final String label;
  final String value;
}

class ProductSpecSection {
  const ProductSpecSection(this.group, this.specs);

  final ProductSpecGroup group;
  final List<ProductSpec> specs;
}

/// Builds a spec section from an ordered map, dropping blank or null values so
/// segments never render empty rows.
ProductSpecSection specSection(
  ProductSpecGroup group,
  Map<String, Object?> entries,
) {
  final specs = <ProductSpec>[];
  entries.forEach((label, value) {
    if (value == null) return;
    final text = value is String ? value.trim() : value.toString().trim();
    if (text.isEmpty) return;
    if (text == 'N/A' ||
        text == '-' ||
        text == '—' ||
        text == '–' ||
        text.toLowerCase() == 'n/a') {
      return;
    }
    if (text == 'Not available') return;
    specs.add(ProductSpec(label, text));
  });
  return ProductSpecSection(group, specs);
}

/// Segment-agnostic product detail view model.
///
/// Every segment maps onto this same shape so the detail screen renders an
/// identical structure whether the product is a diamond, a watch or a gold bar.
class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.segment,
    required this.apiProductType,
    required this.title,
    required this.subtitle,
    required this.referenceLabel,
    required this.referenceValue,
    required this.media,
    required this.price,
    required this.highlights,
    required this.specSections,
    this.badges = const [],
    this.certification,
    this.availability,
    this.shapeKey,
    this.note,
  });

  final String id;
  final ProductSegment segment;

  /// Backend cart `productType` (`diamond`, `jewellery`, …).
  final String apiProductType;
  final String title;
  final String subtitle;

  /// Label/value for the seller-facing identifier (`SKU`, `Stock ID`).
  final String referenceLabel;
  final String referenceValue;

  final List<ProductBadge> badges;
  final ProductMedia media;
  final ProductPrice price;

  /// Exactly four attributes that drive the buying decision for the segment.
  final List<ProductHighlight> highlights;

  final ProductCertification? certification;
  final ProductAvailability? availability;
  final List<ProductSpecSection> specSections;

  /// Shape name forwarded to the cart, which renders a shape glyph.
  final String? shapeKey;
  final String? note;

  /// Sections in canonical group order with empty ones removed.
  List<ProductSpecSection> get orderedSpecs {
    final populated =
        specSections.where((s) => s.specs.isNotEmpty).toList(growable: false)
          ..sort((a, b) => a.group.index.compareTo(b.group.index));
    return populated;
  }

  bool get isPurchasable =>
      availability?.tone != ProductStockTone.unavailable;

  WishlistCategory get wishlistCategory => switch (segment) {
        ProductSegment.naturalDiamond ||
        ProductSegment.labGrownDiamond =>
          WishlistCategory.diamond,
        ProductSegment.gemstone => WishlistCategory.gemstone,
        ProductSegment.jewelry => WishlistCategory.jewelry,
        ProductSegment.watch => WishlistCategory.watch,
        ProductSegment.bullion => WishlistCategory.bullion,
      };

  WishlistItem toWishlistItem() {
    return WishlistItem(
      id: id,
      category: wishlistCategory,
      title: title,
      subtitle: subtitle,
      priceLabel: price.display,
      imageUrl: media.firstNetworkUrl,
      imageAsset: media.firstAssetPath,
    );
  }

}
