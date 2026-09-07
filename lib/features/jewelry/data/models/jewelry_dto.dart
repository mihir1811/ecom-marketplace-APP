/// Raw jewellery product from `GET /jewellery` / `GET /jewellery/:id`.
class JewelryDto {
  const JewelryDto({
    required this.id,
    this.productTitle,
    this.style,
    this.theme,
    this.occasion,
    this.gender,
    this.description,
    this.deliveryTime,
    this.tags,
    this.videoURL,
    this.isOnAuction,
    this.sellerId,
    this.variants = const [],
    this.subcategory,
  });

  final String id;
  final String? productTitle;
  final String? style;
  final String? theme;
  final String? occasion;
  final String? gender;
  final String? description;
  final String? deliveryTime;
  final String? tags;
  final String? videoURL;
  final bool? isOnAuction;
  final String? sellerId;
  final List<JewelryVariantDto> variants;
  final JewelrySubcategoryDto? subcategory;

  factory JewelryDto.fromJson(Map<String, dynamic> json) {
    final variantsJson = json['variants'];
    final variants = <JewelryVariantDto>[];
    if (variantsJson is List) {
      for (final item in variantsJson) {
        if (item is Map<String, dynamic>) {
          variants.add(JewelryVariantDto.fromJson(item));
        }
      }
    }

    final subJson = json['subcategory'];
    return JewelryDto(
      id: json['id']?.toString() ?? '',
      productTitle: json['productTitle']?.toString(),
      style: json['style']?.toString(),
      theme: json['theme']?.toString(),
      occasion: json['occasion']?.toString(),
      gender: json['gender']?.toString(),
      description: json['description']?.toString(),
      deliveryTime: json['deliveryTime']?.toString(),
      tags: json['tags']?.toString(),
      videoURL: json['videoURL']?.toString(),
      isOnAuction: json['isOnAuction'] as bool?,
      sellerId: json['sellerId']?.toString(),
      variants: variants,
      subcategory: subJson is Map<String, dynamic>
          ? JewelrySubcategoryDto.fromJson(subJson)
          : null,
    );
  }
}

class JewelrySubcategoryDto {
  const JewelrySubcategoryDto({
    required this.id,
    this.name,
    this.category,
  });

  final String id;
  final String? name;
  final JewelryCategoryDto? category;

  factory JewelrySubcategoryDto.fromJson(Map<String, dynamic> json) {
    final catJson = json['category'];
    return JewelrySubcategoryDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      category: catJson is Map<String, dynamic>
          ? JewelryCategoryDto.fromJson(catJson)
          : null,
    );
  }
}

class JewelryCategoryDto {
  const JewelryCategoryDto({
    required this.id,
    this.name,
    this.imageUrl,
  });

  final String id;
  final String? name;
  final String? imageUrl;

  factory JewelryCategoryDto.fromJson(Map<String, dynamic> json) {
    return JewelryCategoryDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class JewelryVariantDto {
  const JewelryVariantDto({
    required this.id,
    this.stockNumber,
    this.metalType,
    this.metalColor,
    this.metalPurity,
    this.metalFinish,
    this.plating,
    this.metalWeight,
    this.ringSize,
    this.braceletSize,
    this.chainLength,
    this.discount,
    this.totalPrice,
    this.totalMetalPrice,
    this.totalStonePrice,
    this.totalMakingCharge,
    this.metalPricePerGram,
    this.stonePricePerCarat,
    this.makingPricePerGram,
    this.totalJewelryWeight,
    this.condition,
    this.available,
    this.isSold,
    this.certificateCompanyName,
    this.totalStoneCarat,
    this.totalStonePcs,
    this.image1,
    this.image2,
    this.image3,
    this.image4,
    this.image5,
    this.image6,
    this.stones = const [],
  });

  final String id;
  final String? stockNumber;
  final String? metalType;
  final String? metalColor;
  final String? metalPurity;
  final String? metalFinish;
  final String? plating;
  final double? metalWeight;
  final String? ringSize;
  final String? braceletSize;
  final String? chainLength;
  final double? discount;
  final double? totalPrice;
  final double? totalMetalPrice;
  final double? totalStonePrice;
  final double? totalMakingCharge;
  final double? metalPricePerGram;
  final double? stonePricePerCarat;
  final double? makingPricePerGram;
  final double? totalJewelryWeight;
  final String? condition;
  final String? available;
  final bool? isSold;
  final String? certificateCompanyName;
  final double? totalStoneCarat;
  final int? totalStonePcs;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? image4;
  final String? image5;
  final String? image6;
  final List<JewelryStoneDto> stones;

  factory JewelryVariantDto.fromJson(Map<String, dynamic> json) {
    final stonesJson = json['stones'];
    final stones = <JewelryStoneDto>[];
    if (stonesJson is List) {
      for (final item in stonesJson) {
        if (item is Map<String, dynamic>) {
          stones.add(JewelryStoneDto.fromJson(item));
        }
      }
    }

    return JewelryVariantDto(
      id: json['id']?.toString() ?? '',
      stockNumber: json['stockNumber']?.toString(),
      metalType: json['metalType']?.toString(),
      metalColor: json['metalColor']?.toString(),
      metalPurity: json['metalPurity']?.toString(),
      metalFinish: json['metalFinish']?.toString(),
      plating: json['plating']?.toString(),
      metalWeight: _toDouble(json['metalWeight']),
      ringSize: json['ringSize']?.toString(),
      braceletSize: json['braceletSize']?.toString(),
      chainLength: json['chainLength']?.toString(),
      discount: _toDouble(json['discount']),
      totalPrice: _toDouble(json['totalPrice']),
      totalMetalPrice: _toDouble(json['totalMetalPrice']),
      totalStonePrice: _toDouble(json['totalStonePrice']),
      totalMakingCharge: _toDouble(json['totalMakingCharge']),
      metalPricePerGram: _toDouble(json['metalPricePerGram']),
      stonePricePerCarat: _toDouble(json['stonePricePerCarat']),
      makingPricePerGram: _toDouble(json['makingPricePerGram']),
      totalJewelryWeight: _toDouble(json['totalJewelryWeight']),
      condition: json['condition']?.toString(),
      available: json['available']?.toString(),
      isSold: json['isSold'] as bool?,
      certificateCompanyName: json['certificateCompanyName']?.toString(),
      totalStoneCarat: _toDouble(json['totalStoneCarat']),
      totalStonePcs: _toInt(json['totalStonePcs']),
      image1: json['image1']?.toString(),
      image2: json['image2']?.toString(),
      image3: json['image3']?.toString(),
      image4: json['image4']?.toString(),
      image5: json['image5']?.toString(),
      image6: json['image6']?.toString(),
      stones: stones,
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class JewelryStoneDto {
  const JewelryStoneDto({
    this.centerStoneType,
    this.centerStoneCategory,
    this.centerStoneShape,
    this.centerStoneColor,
    this.centerStoneClarity,
    this.centerStoneWeight,
    this.centerStonePcs,
  });

  final String? centerStoneType;
  final String? centerStoneCategory;
  final String? centerStoneShape;
  final String? centerStoneColor;
  final String? centerStoneClarity;
  final double? centerStoneWeight;
  final int? centerStonePcs;

  factory JewelryStoneDto.fromJson(Map<String, dynamic> json) {
    return JewelryStoneDto(
      centerStoneType: json['centerStoneType']?.toString(),
      centerStoneCategory: json['centerStoneCategory']?.toString(),
      centerStoneShape: json['centerStoneShape']?.toString(),
      centerStoneColor: json['centerStoneColor']?.toString(),
      centerStoneClarity: json['centerStoneClarity']?.toString(),
      centerStoneWeight: JewelryVariantDto._toDouble(json['centerStoneWeight']),
      centerStonePcs: JewelryVariantDto._toInt(json['centerStonePcs']),
    );
  }
}
