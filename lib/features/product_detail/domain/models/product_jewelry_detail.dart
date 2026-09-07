/// Jewelry-only layout data for the product detail screen (after seller).
class ProductJewelryDetail {
  const ProductJewelryDetail({
    required this.description,
    required this.category,
    required this.gender,
    required this.occasion,
    required this.styleNo,
    required this.metalType,
    required this.metalColor,
    required this.metalPurity,
    required this.metalWeightG,
    required this.stoneWeightCt,
    required this.stoneCount,
    required this.price,
    required this.currencySymbol,
    this.metalFinish,
    this.style,
    this.totalWeightG,
    this.braceletSize,
    this.ringSize,
    this.chainLength,
    this.discountAmount,
    this.discountPercent,
    this.metalPrice,
    this.stonePrice,
    this.makingCharge,
    this.purityOptions = const [],
    this.sizeOptions = const [],
    this.stoneWeightOptions = const [],
    this.stones = const [],
    this.variants = const [],
    this.materialLabel,
  });

  final String description;
  final String category;
  final String gender;
  final String occasion;
  final String styleNo;
  final String metalType;
  final String metalColor;
  final String metalPurity;
  final String? metalFinish;
  final String? style;
  final double metalWeightG;
  final double? totalWeightG;
  final double stoneWeightCt;
  final int stoneCount;
  final String? braceletSize;
  final String? ringSize;
  final String? chainLength;
  final double price;
  final String currencySymbol;
  final double? discountAmount;
  final double? discountPercent;
  final double? metalPrice;
  final double? stonePrice;
  final double? makingCharge;
  final List<String> purityOptions;
  final List<String> sizeOptions;
  final List<String> stoneWeightOptions;
  final List<ProductJewelryStone> stones;
  final List<ProductJewelryVariant> variants;
  final String? materialLabel;

  String get sizeLabel =>
      braceletSize ?? ringSize ?? chainLength ?? '';
}

class ProductJewelryStone {
  const ProductJewelryStone({
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

class ProductJewelryVariant {
  const ProductJewelryVariant({
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
  final List<ProductJewelryStone> stones;
}
