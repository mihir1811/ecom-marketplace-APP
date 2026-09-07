/// Clean domain representation of a fine jewelry product.
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
    this.sizeOptions = const [],
    this.braceletSize,
    this.braceletLength,
    this.chainLength,
    this.necklaceLength,
    this.ringSize,
    this.badge,
    this.imageAsset,
    this.imageUrl,
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
    this.stones = const [],
    this.variants = const [],
  });

  final String id;
  final String sku;
  final String name;
  final String category;
  final String? subCategory;
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
  final List<String> sizeOptions;
  final String? braceletSize;
  final String? braceletLength;
  final String? chainLength;
  final String? necklaceLength;
  final String? ringSize;
  final String? badge;
  final String? imageAsset;
  /// Absolute network image URL from the jewellery API (preferred over [imageAsset]).
  final String? imageUrl;
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
  final List<JewelryStone> stones;
  final List<JewelryVariantOption> variants;

  /// Prefer network image when present; otherwise local asset fallback.
  String? get displayImageUrl {
    final network = imageUrl?.trim();
    if (network != null && network.isNotEmpty) return network;
    return null;
  }
}

/// One stone group on a jewellery variant.
class JewelryStone {
  const JewelryStone({
    this.type,
    this.category,
    this.shape,
    this.color,
    this.clarity,
    this.weightCt,
    this.pieces,
    this.setting,
  });

  final String? type;
  final String? category;
  final String? shape;
  final String? color;
  final String? clarity;
  final double? weightCt;
  final int? pieces;
  final String? setting;
}

/// Selectable variant option for purity / size / stone weight.
class JewelryVariantOption {
  const JewelryVariantOption({
    required this.id,
    required this.price,
    this.sku,
    this.metalPurity,
    this.sizeLabel,
    this.stoneWeightCt,
    this.metalWeightG,
    this.totalWeightG,
    this.discountAmount,
    this.discountPercent,
    this.metalPrice,
    this.stonePrice,
    this.makingCharge,
    this.metalType,
    this.metalColor,
    this.metalFinish,
    this.braceletSize,
    this.ringSize,
    this.chainLength,
    this.stoneCount,
    this.stones = const [],
  });

  final String id;
  final double price;
  final String? sku;
  final String? metalPurity;
  final String? sizeLabel;
  final double? stoneWeightCt;
  final double? metalWeightG;
  final double? totalWeightG;
  final double? discountAmount;
  final double? discountPercent;
  final double? metalPrice;
  final double? stonePrice;
  final double? makingCharge;
  final String? metalType;
  final String? metalColor;
  final String? metalFinish;
  final String? braceletSize;
  final String? ringSize;
  final String? chainLength;
  final int? stoneCount;
  final List<JewelryStone> stones;
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
