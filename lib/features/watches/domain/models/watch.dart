/// Clean domain representation of a luxury watch.
class Watch {
  const Watch({
    required this.id,
    required this.brand,
    required this.model,
    required this.collection,
    required this.year,
    required this.price,
    required this.condition,
    required this.caseSizeMm,
    required this.caseSizeRange,
    required this.caseMaterial,
    required this.caseShape,
    required this.caseBack,
    required this.dialColor,
    required this.strapColor,
    required this.strapMaterial,
    required this.crownType,
    required this.claspType,
    required this.claspMaterial,
    required this.movement,
    required this.gender,
    required this.waterResistanceM,
    required this.glassMaterial,
    required this.lugWidth,
    required this.powerReserveRange,
    required this.certification,
    required this.bezelType,
    required this.bezelMaterial,
    required this.configurations,
    required this.materials,
    required this.preciousStoneTypes,
    required this.indexes,
    required this.category,
    required this.availabilityStatus,
    this.imageUrl,
    this.hasVideo = false,
    this.boxIncluded = false,
    this.papersIncluded = false,
    this.warrantyCardIncluded = false,
    this.discount,
    this.inStock = true,
    this.sellerId,
  });

  final String id;
  final String brand;
  final String model;
  final String collection;
  final int year;
  final double price;
  final String condition;
  final int caseSizeMm;
  final String caseSizeRange;
  final String caseMaterial;
  final String caseShape;
  final String caseBack;
  final String dialColor;
  final String strapColor;
  final String strapMaterial;
  final String crownType;
  final String claspType;
  final String claspMaterial;
  final String movement;
  final String gender;
  final int waterResistanceM;
  final String glassMaterial;
  final String lugWidth;
  final String powerReserveRange;
  final String certification;
  final String bezelType;
  final String bezelMaterial;
  final List<String> configurations;
  final List<String> materials;
  final List<String> preciousStoneTypes;
  final String indexes;
  final String category;
  final String availabilityStatus;
  final String? imageUrl;
  final bool hasVideo;
  final bool boxIncluded;
  final bool papersIncluded;
  final bool warrantyCardIncluded;
  final double? discount;
  final bool inStock;
  final String? sellerId;

  String? get renderableImageUrl {
    final value = imageUrl;
    if (value == null || value.isEmpty || value.startsWith('mock://')) {
      return null;
    }
    return value;
  }

  bool get fullSetIncluded =>
      boxIncluded && papersIncluded && warrantyCardIncluded;

  String get detailLine => '$collection · $year';

  String get specsLine =>
      '${caseSizeMm}mm · $caseMaterial · $dialColor Dial';
}

class WatchListResponse {
  const WatchListResponse({
    required this.watches,
    required this.totalCount,
    required this.hasMore,
    required this.page,
  });

  final List<Watch> watches;
  final int totalCount;
  final bool hasMore;
  final int page;
}
