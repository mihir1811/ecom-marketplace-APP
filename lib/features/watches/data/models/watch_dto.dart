/// Raw watch row from `GET /watch/all` or `GET /watch/:id`.
class WatchDto {
  const WatchDto({
    required this.id,
    this.stockNumber,
    this.brand,
    this.model,
    this.referenceNumber,
    this.dialColor,
    this.caseShape,
    this.caseSize,
    this.caseMaterial,
    this.caseBack,
    this.crownType,
    this.strapMaterial,
    this.strapColor,
    this.claspType,
    this.claspMaterial,
    this.movementType,
    this.calibre,
    this.powerReserve,
    this.waterResistance,
    this.glass,
    this.complications = const [],
    this.features = const [],
    this.preciousStoneType = const [],
    this.bezelType,
    this.bezelMaterial,
    this.indexes,
    this.display,
    this.gender,
    this.collection,
    this.certification,
    this.modelYear,
    this.lugWidth,
    this.condition,
    this.price,
    this.availabilityStatus,
    this.warrantyCardIncluded,
    this.boxIncluded,
    this.papersIncluded,
    this.style = const [],
    this.image1,
    this.image2,
    this.image3,
    this.image4,
    this.image5,
    this.image6,
    this.videoURL,
    this.description,
  });

  final String id;
  final String? stockNumber;
  final String? brand;
  final String? model;
  final String? referenceNumber;
  final String? dialColor;
  final String? caseShape;
  final int? caseSize;
  final String? caseMaterial;
  final String? caseBack;
  final String? crownType;
  final String? strapMaterial;
  final String? strapColor;
  final String? claspType;
  final String? claspMaterial;
  final String? movementType;
  final String? calibre;
  final int? powerReserve;
  final String? waterResistance;
  final String? glass;
  final List<String> complications;
  final List<String> features;
  final List<String> preciousStoneType;
  final String? bezelType;
  final String? bezelMaterial;
  final String? indexes;
  final String? display;
  final String? gender;
  final String? collection;
  final String? certification;
  final int? modelYear;
  final String? lugWidth;
  final String? condition;
  final double? price;
  final String? availabilityStatus;
  final bool? warrantyCardIncluded;
  final bool? boxIncluded;
  final bool? papersIncluded;
  final List<String> style;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? image4;
  final String? image5;
  final String? image6;
  final String? videoURL;
  final String? description;

  factory WatchDto.fromJson(Map<String, dynamic> json) {
    return WatchDto(
      id: json['id']?.toString() ?? '',
      stockNumber: json['stockNumber']?.toString(),
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      referenceNumber: json['referenceNumber']?.toString(),
      dialColor: json['dialColor']?.toString(),
      caseShape: json['caseShape']?.toString(),
      caseSize: _toInt(json['caseSize']),
      caseMaterial: json['caseMaterial']?.toString(),
      caseBack: json['caseBack']?.toString(),
      crownType: json['crownType']?.toString(),
      strapMaterial: json['strapMaterial']?.toString(),
      strapColor: json['strapColor']?.toString(),
      claspType: json['claspType']?.toString(),
      claspMaterial: json['claspMaterial']?.toString(),
      movementType: json['movementType']?.toString(),
      calibre: json['calibre']?.toString(),
      powerReserve: _toInt(json['powerReserve']),
      waterResistance: json['waterResistance']?.toString(),
      glass: json['glass']?.toString(),
      complications: _toStringList(json['complications']),
      features: _toStringList(json['features']),
      preciousStoneType: _toStringList(json['preciousStoneType']),
      bezelType: json['bezelType']?.toString(),
      bezelMaterial: json['bezelMaterial']?.toString(),
      indexes: json['indexes']?.toString() ?? json['stonesOnDial']?.toString(),
      display: json['display']?.toString(),
      gender: json['gender']?.toString(),
      collection: json['collection']?.toString(),
      certification: json['certification']?.toString(),
      modelYear: _toInt(json['modelYear']),
      lugWidth: json['lugWidth']?.toString(),
      condition: json['condition']?.toString(),
      price: _toDouble(json['price']),
      availabilityStatus: json['availabilityStatus']?.toString(),
      warrantyCardIncluded: json['warrantyCardIncluded'] as bool?,
      boxIncluded: json['boxIncluded'] as bool?,
      papersIncluded: json['papersIncluded'] as bool?,
      style: _toStringList(json['style']),
      image1: json['image1']?.toString(),
      image2: json['image2']?.toString(),
      image3: json['image3']?.toString(),
      image4: json['image4']?.toString(),
      image5: json['image5']?.toString(),
      image6: json['image6']?.toString(),
      videoURL: json['videoURL']?.toString(),
      description: json['description']?.toString(),
    );
  }

  static List<String> _toStringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
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
