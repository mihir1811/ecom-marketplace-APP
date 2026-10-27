import 'marketplace_listing.dart';

/// Clean domain representation of a fine jewelry product.
///
/// Marketplace pieces use the listing slug as [id]: public product pages are
/// looked up by slug, so wishlists, compare and reopen-from-history all work
/// from the same key. [listingId] keeps the listing's UUID.
class Jewelry {
  const Jewelry({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    this.subCategory,
    required this.price,
    required this.metalType,
    required this.metalColor,
    required this.metalPurity,
    required this.gender,
    required this.occasion,
    required this.condition,
    required this.availability,
    required this.stoneType,
    required this.stoneCategory,
    required this.stoneShape,
    required this.certification,
    required this.metalWeightG,
    required this.stoneWeightCt,
    required this.stoneCount,
    required this.colorVariants,
    this.badge,
    this.imageAsset,
    this.imageUrl,
    this.imageUrls = const [],
    this.discount,
    this.discountAmount,
    this.metalPrice,
    this.stonePrice,
    this.makingCharge,
    this.hasMedia = true,
    this.rating,
    this.reviewCount,
    this.wishlisted = false,
    this.sellerId,
    this.description,
    this.metalFinish,
    this.style,
    this.totalWeightG,
    this.slug,
    this.listingId,
    this.maxPrice,
    this.shopName,
    this.listing,
  });

  final String id;
  final String sku;
  final String name;
  final String category;
  final String? subCategory;

  /// Lowest SKU price, in rupees for marketplace pieces.
  final double price;
  final String metalType;
  final String metalColor;
  final String metalPurity;
  final String gender;
  final String occasion;
  final String condition;
  final String availability;
  final String stoneType;
  final String stoneCategory;
  final String stoneShape;
  final String certification;
  final double metalWeightG;
  final double stoneWeightCt;
  final int stoneCount;
  final List<String> colorVariants;
  final String? badge;
  final String? imageAsset;

  /// Absolute network image URL (preferred over [imageAsset]).
  final String? imageUrl;

  /// Every photo the record carries (cards: at most two).
  final List<String> imageUrls;
  final double? discount;

  /// Absolute discount amount in listing currency (when API provides it).
  final double? discountAmount;
  final double? metalPrice;
  final double? stonePrice;
  final double? makingCharge;
  final bool hasMedia;
  final double? rating;
  final int? reviewCount;
  final bool wishlisted;
  final String? sellerId;
  final String? description;
  final String? metalFinish;
  final String? style;
  final double? totalWeightG;

  /// Marketplace listing slug (public product page key).
  final String? slug;

  /// Marketplace listing UUID (chat, orders).
  final String? listingId;

  /// Highest SKU price; above [price] the card reads "from".
  final double? maxPrice;
  final String? shopName;

  /// Full marketplace record this piece was built from.
  final MarketplaceListing? listing;

  bool get isMarketplace => listing != null;

  bool get hasPriceRange => maxPrice != null && maxPrice! > price;

  /// Prefer network image when present; otherwise local asset fallback.
  String? get displayImageUrl {
    final network = imageUrl?.trim();
    if (network != null && network.isNotEmpty) return network;
    return null;
  }
}

class JewelryListResponse {
  const JewelryListResponse({
    required this.items,
    required this.totalCount,
    required this.hasMore,
    required this.page,
  });

  final List<Jewelry> items;
  final int totalCount;
  final bool hasMore;
  final int page;
}
