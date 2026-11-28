import 'package:flutter/widgets.dart';

import '../../../../core/catalog/catalog_purchase_policy.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../product_offer/domain/models/product_offer.dart';
import 'listing_seller_info.dart';
import 'product_jewelry_detail.dart';
import 'product_bullion_detail.dart';
import 'product_rough_detail.dart';

/// Marketplace segments that share the single product detail presentation.
enum ProductSegment {
  naturalDiamond('Natural Diamond', 'natural-diamond'),
  labGrownDiamond('Lab Grown Diamond', 'lab-grown-diamond'),
  gemstone('Gemstone', 'gemstone'),
  jewelry('Jewelry', 'jewelry'),
  watch('Watch', 'watch'),
  bullion('Bullion', 'bullion'),
  roughDiamond('Rough Diamond', 'rough-diamond');

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
    required this.displayAmount,
    this.unitLabel,
    this.unitAmountLabel,
    this.discountPercent,
    this.listAmount,
    this.displayAmountIsListPrice = false,
    this.isOnRequest = false,
  });

  final String currencySymbol;
  final String amountLabel;
  final double priceUsd;
  final double priceInr;

  /// Numeric value formatted into [amountLabel].
  final double displayAmount;

  /// e.g. `per carat`, `per gram`.
  final String? unitLabel;
  final String? unitAmountLabel;
  final double? discountPercent;

  /// Explicit list / RAP total when known (shown struck through).
  /// When null, list is inferred from [displayAmount] and [discountPercent].
  final double? listAmount;

  /// When true, [displayAmount] is the list price and discount % reduces it.
  /// When false (diamonds), [displayAmount] is already the net sale price.
  final bool displayAmountIsListPrice;

  /// Share / catalog hide-price: show [amountLabel] instead of a numeric amount.
  final bool isOnRequest;

  String get display =>
      isOnRequest ? amountLabel : '$currencySymbol$amountLabel';

  String? get unitDisplay {
    if (isOnRequest) return null;
    if (unitAmountLabel == null || unitLabel == null) return null;
    return '$currencySymbol$unitAmountLabel $unitLabel';
  }

  bool get hasDiscount {
    if (isOnRequest) return false;
    final d = discountPercent;
    if (d == null || d <= 0 || d >= 100 || displayAmount <= 0) return false;
    if (listAmount != null) return listAmount! > displayAmount;
    return true;
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

/// Named group of rows inside a tab (e.g. Basic Info under Details).
class ProductSpecTabSection {
  const ProductSpecTabSection({required this.title, required this.rows});

  final String title;
  final List<ProductSpec> rows;
}

/// One tab in the natural-diamond / gemstone / watch overview card.
class ProductSpecTab {
  const ProductSpecTab({
    required this.title,
    this.rows = const [],
    this.sections = const [],
    this.isComment = false,
    this.commentBody,
  });

  final String title;
  final List<ProductSpec> rows;

  /// When non-empty, rendered as titled cards instead of a single [rows] card.
  final List<ProductSpecTabSection> sections;
  final bool isComment;
  final String? commentBody;

  bool get hasSections => sections.isNotEmpty;
}

/// Melee lot quantity picker shown under natural melee spec tabs.
class ProductMeleeQty {
  const ProductMeleeQty({
    this.totalPcs,
    this.totalCarat,
    this.caratPerPcs,
    this.pricePerPcs,
    this.pricePerCarat,
    this.pcsApprox = false,
    this.caratApprox = false,
    this.shape,
  });

  final int? totalPcs;
  final double? totalCarat;
  final double? caratPerPcs;

  /// Display only (lot header); purchase math uses the lot totals.
  final double? pricePerPcs;
  final double? pricePerCarat;

  /// Pieces / per-piece figures estimated from the sieve chart.
  final bool pcsApprox;

  /// Carat / per-carat figures estimated from the sieve chart.
  final bool caratApprox;

  /// Display shape for the lot title ("120 pcs Round").
  final String? shape;

  /// Prefer lot totals for purchase math — `caratPerPcs` from API is often stale.
  double get resolvedCaratPerPcs {
    final pcs = totalPcs;
    final ct = totalCarat;
    if (pcs != null && pcs > 0 && ct != null && ct > 0) {
      return ct / pcs;
    }
    if (caratPerPcs != null && caratPerPcs! > 0) return caratPerPcs!;
    return 0;
  }
}

/// Tabbed grading card for natural and lab-grown diamonds (single or melee).
class ProductTabbedSpecs {
  const ProductTabbedSpecs({required this.tabs, this.meleeQty});

  final List<ProductSpecTab> tabs;
  final ProductMeleeQty? meleeQty;
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

/// Colour facts of a loose stone, so it can be drawn in its own tint.
///
/// Raw catalog wording: [grade] is a D–Z letter (diamonds) or a colour name
/// (gemstones); [species] is the gem type (`Ruby`), used when no colour is
/// given.
class ProductStoneColor {
  const ProductStoneColor({
    this.grade,
    this.fancyColor,
    this.intensity,
    this.overtone,
    this.species,
  });

  final String? grade;
  final String? fancyColor;
  final String? intensity;
  final String? overtone;
  final String? species;
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
    this.availabilityStatus,
    this.listingSeller,
    this.shapeKey,
    this.stoneColor,
    this.note,
    this.isMakeAnOfferAllowed = false,
    this.minimumOfferPrice,
    this.maxOfferAttemptsPerUser = 5,
    this.isSold = false,
    this.isOnAuction = false,
    this.naturalSpecTabs,
    this.meleeLot,
    this.jewelryDetail,
    this.bullionDetail,
    this.roughDetail,
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

  /// Raw API availability code (`yes`, `hold`, `memo`, …) for status dots.
  final String? availabilityStatus;
  final ListingSellerInfo? listingSeller;
  final List<ProductSpecSection> specSections;

  /// Shape name forwarded to the cart, which renders a shape glyph.
  final String? shapeKey;

  /// Colour of a diamond or gemstone; null for every other segment.
  final ProductStoneColor? stoneColor;
  final String? note;
  final bool isMakeAnOfferAllowed;
  final double? minimumOfferPrice;

  /// Total offers one buyer may make on this stone, any status.
  final int maxOfferAttemptsPerUser;
  final bool isSold;
  final bool isOnAuction;

  /// Overview / Advance for singles; Summary / Details for melee (natural + lab).
  final ProductTabbedSpecs? naturalSpecTabs;

  /// Melee lot totals (separable or not), for pieces / carat display.
  final ProductMeleeQty? meleeLot;

  /// Jewelry layout: choose-details + Details / Specifications / Care tabs.
  final ProductJewelryDetail? jewelryDetail;

  /// Bullion layout: Overview / Specifications / Seller tabs.
  final ProductBullionDetail? bullionDetail;

  /// Rough parcel layout: lot picker, documents and the server's buy verdict.
  final ProductRoughDetail? roughDetail;

  /// Offers are for diamonds, melee parcels, gemstones and whole rough
  /// parcels the seller opened to offers, while not sold or on auction.
  bool get canMakeAnOffer =>
      isMakeAnOfferAllowed &&
      !isSold &&
      !isOnAuction &&
      OfferProductType.supports(apiProductType);

  /// Sections in canonical group order with empty ones removed.
  List<ProductSpecSection> get orderedSpecs {
    final populated =
        specSections.where((s) => s.specs.isNotEmpty).toList(growable: false)
          ..sort((a, b) => a.group.index.compareTo(b.group.index));
    return populated;
  }

  /// Specs shown to the current viewer.
  ///
  /// Seller contact rows are business-account-only. Individual viewers never
  /// see seller contact fields. Business viewers see name-only for individual
  /// listing sellers, and contact fields for business listing sellers.
  List<ProductSpecSection> specsForViewer({required bool isSeller}) {
    if (isSeller) {
      return orderedSpecs
          .map(
            (section) => ProductSpecSection(
              section.group,
              section.specs
                  .where(
                    (spec) => _sellerMayViewSpec(spec.label, listingSeller),
                  )
                  .toList(growable: false),
            ),
          )
          .where((section) => section.specs.isNotEmpty)
          .toList(growable: false);
    }
    return orderedSpecs
        .map(
          (section) => ProductSpecSection(
            section.group,
            section.specs
                .where((spec) => !_isSellerRestrictedSpec(spec.label))
                .toList(growable: false),
          ),
        )
        .where((section) => section.specs.isNotEmpty)
        .toList(growable: false);
  }

  bool get isPurchasable => CatalogPurchasePolicy.canAddToCart(
    availabilityStatus: availabilityStatus,
    availability: availability,
  );

  String? addToCartBlockMessage({
    required String? userId,
    required String? sellerId,
  }) => CatalogPurchasePolicy.addToCartBlockMessage(
    ownListing: isOwnedByCurrentAccount(userId: userId, sellerId: sellerId),
    availabilityStatus: availabilityStatus,
    availability: availability,
  );

  bool isOwnedByCurrentAccount({
    required String? userId,
    required String? sellerId,
  }) {
    return listingSeller?.isOwnedBy(userId: userId, sellerId: sellerId) ??
        false;
  }

  WishlistCategory get wishlistCategory => switch (segment) {
    ProductSegment.naturalDiamond ||
    ProductSegment.labGrownDiamond => WishlistCategory.diamond,
    ProductSegment.gemstone => WishlistCategory.gemstone,
    ProductSegment.jewelry => WishlistCategory.jewelry,
    ProductSegment.watch => WishlistCategory.watch,
    ProductSegment.bullion => WishlistCategory.bullion,
    ProductSegment.roughDiamond => WishlistCategory.roughDiamond,
  };

  WishlistItem toWishlistItem() {
    return WishlistItem(
      id: id,
      category: wishlistCategory,
      productType: apiProductType,
      title: title,
      subtitle: subtitle,
      priceLabel: price.display,
      imageUrl: media.firstNetworkUrl,
      imageAsset: media.firstAssetPath,
    );
  }
}

bool _isSellerRestrictedSpec(String label) {
  final normalized = label.trim().toLowerCase();
  return normalized == 'seller' ||
      normalized.startsWith('seller ') ||
      normalized == 'company name' ||
      normalized == 'seller company' ||
      normalized == 'contact' ||
      normalized == 'seller contact' ||
      normalized == 'seller email' ||
      normalized == 'seller phone' ||
      normalized == 'seller location';
}

bool _sellerMayViewSpec(String label, ListingSellerInfo? seller) {
  if (_isSellerRestrictedSpec(label)) {
    if (seller?.isIndividual ?? false) {
      final normalized = label.trim().toLowerCase();
      return normalized == 'seller' ||
          normalized == 'seller name' ||
          normalized == 'company name' ||
          normalized == 'seller company';
    }
    return true;
  }
  return true;
}
