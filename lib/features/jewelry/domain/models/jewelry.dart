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
    this.discount,
    this.hasMedia = true,
    this.rating,
    this.reviewCount,
    this.wishlisted = false,
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
  final double? discount;
  final bool hasMedia;
  final double? rating;
  final int? reviewCount;
  final bool wishlisted;
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
