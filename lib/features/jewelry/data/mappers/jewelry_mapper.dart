import '../../domain/models/jewelry.dart';
import '../../domain/models/marketplace_enums.dart';
import '../../domain/models/marketplace_listing.dart';
import 'marketplace_mapper.dart';

/// Maps marketplace listings onto the shared [Jewelry] domain model.
abstract final class JewelryMapper {
  /// A raw listing payload (card or product page).
  static Jewelry fromJson(Map<String, dynamic> json) =>
      fromListing(MarketplaceMapper.listing(json));

  static Jewelry fromListing(MarketplaceListing l) {
    final d = l.detail;
    final images = l.imageUrls;
    final metal = MarketplaceEnums.swatchLabel(d.metalType);
    final metalTones = <String>{
      if (metal.isNotEmpty) metal,
      for (final option in _metalOptions(l))
        if (_toneOf(option) case final tone?) tone,
    }.toList();
    final stoneCount = l.gemstones.fold<int>(
      0,
      (sum, g) => sum + (g.quantity ?? 0),
    );
    return Jewelry(
      id: l.slug,
      slug: l.slug,
      listingId: l.id,
      sku: l.stockNumber ?? '',
      name: l.title,
      category: l.parentCategoryName ?? l.categoryName ?? '',
      subCategory: l.parentCategoryName == null ? null : l.categoryName,
      price: l.minPrice,
      maxPrice: l.maxPrice,
      metalType: MarketplaceEnums.label(d.metalType),
      metalColor: metal,
      metalPurity: d.metalPurity ?? '',
      gender: '',
      occasion: d.occasion ?? '',
      condition: '',
      availability: _availability(l),
      stoneType: MarketplaceEnums.label(d.gemstoneOrigin),
      stoneCategory: MarketplaceEnums.label(d.primaryGemstone),
      stoneShape: d.primaryShape ?? '',
      certification: _certification(l),
      metalWeightG: d.metalWeightGrams ?? 0,
      stoneWeightCt: d.totalCaratWeight ?? 0,
      stoneCount: stoneCount,
      colorVariants: metalTones,
      imageUrl: images.isEmpty ? null : images.first,
      imageUrls: images,
      hasMedia: images.isNotEmpty || l.videoUrl != null,
      sellerId: l.shop?.sellerId,
      description: l.description,
      style: d.style,
      totalWeightG: d.grossWeightGrams,
      shopName: l.shop?.name,
      listing: l,
      rating: l.ratingCount > 0 ? l.ratingAverage : null,
      reviewCount: l.ratingCount,
    );
  }

  /// `Sold out`, `Made to order` or `In Stock` — read by status dots.
  static String _availability(MarketplaceListing l) {
    if (l.soldOut) return 'Sold Out';
    if (l.detail.isMadeToOrder) return 'Made to order';
    return 'In Stock';
  }

  static String _certification(MarketplaceListing l) {
    for (final g in l.gemstones) {
      final lab = g.certificationLab?.trim();
      if (lab != null && lab.isNotEmpty) return lab;
    }
    return '';
  }

  static Iterable<String> _metalOptions(MarketplaceListing l) sync* {
    for (final v in l.variations) {
      final name = v.name.toLowerCase();
      if (name.contains('metal') || name.contains('colo')) yield* v.options;
    }
  }

  /// "14K Rose Gold" → "Rose Gold" (for swatches over the photo).
  static String? _toneOf(String option) {
    final o = option.toLowerCase();
    if (o.contains('rose')) return 'Rose Gold';
    if (o.contains('white')) return 'White Gold';
    if (o.contains('yellow')) return 'Yellow Gold';
    if (o.contains('platinum')) return 'Platinum';
    if (o.contains('silver')) return 'Silver';
    return null;
  }
}
