/// Raw diamond / melee diamond row from listing or detail APIs.
class DiamondDto {
  const DiamondDto({
    required this.id,
    required this.isMelee,
    this.stockNumber,
    this.shape,
    this.color,
    this.colorFrom,
    this.colorTo,
    this.clarity,
    this.clarityMin,
    this.clarityMax,
    this.cut,
    this.cutFrom,
    this.cutTo,
    this.polish,
    this.polishFrom,
    this.polishTo,
    this.symmetry,
    this.symmetryFrom,
    this.symmetryTo,
    this.caratWeight,
    this.caratWeightPerpcs,
    this.totalCaratWeight,
    this.totalPcs,
    this.pricePerCarat,
    this.pricePerPcs,
    this.totalPrice,
    this.rap,
    this.discount,
    this.certificateCompanyName,
    this.certificateNumber,
    this.certification,
    this.growthType,
    this.fluorescenceIntensity,
    this.fluorescenceIntensityFrom,
    this.fluorescenceColor,
    this.measurement,
    this.measurementMin,
    this.measurementMax,
    this.ratio,
    this.table,
    this.depth,
    this.shade,
    this.fancyColor,
    this.fancyIntencity,
    this.fancyOvertone,
    this.origin,
    this.roughSource,
    this.enhancement,
    this.treatment,
    this.comment,
    this.gridleCondition,
    this.culetCondition,
    this.milky,
    this.eyeClean,
    this.bgm,
    this.ha,
    this.sieveSizeMin,
    this.sieveSizeMax,
    this.isSeparable,
    this.available,
    this.image1,
    this.image2,
    this.image3,
    this.image4,
    this.image5,
    this.image6,
    this.videoURL,
    this.isOnAuction,
    this.isSold,
    this.isMakeAnOfferAllowed,
    this.minimumOfferPrice,
    this.sellerCompanyName,
    this.sellerCity,
    this.sellerCountry,
    this.seller,
  });

  final String id;
  final bool isMelee;
  final String? stockNumber;
  final String? shape;
  final String? color;
  final String? colorFrom;
  final String? colorTo;
  final String? clarity;
  final String? clarityMin;
  final String? clarityMax;
  final String? cut;
  final String? cutFrom;
  final String? cutTo;
  final String? polish;
  final String? polishFrom;
  final String? polishTo;
  final String? symmetry;
  final String? symmetryFrom;
  final String? symmetryTo;
  final double? caratWeight;
  final double? caratWeightPerpcs;
  final double? totalCaratWeight;
  final int? totalPcs;
  final double? pricePerCarat;
  final double? pricePerPcs;
  final double? totalPrice;
  final double? rap;
  final double? discount;
  final String? certificateCompanyName;
  final String? certificateNumber;
  final String? certification;
  final String? growthType;
  final String? fluorescenceIntensity;
  final String? fluorescenceIntensityFrom;
  final String? fluorescenceColor;
  final String? measurement;
  final String? measurementMin;
  final String? measurementMax;
  final String? ratio;
  final String? table;
  final String? depth;
  final String? shade;
  final String? fancyColor;
  final String? fancyIntencity;
  final String? fancyOvertone;
  final String? origin;
  final String? roughSource;
  final String? enhancement;
  final String? treatment;
  final String? comment;
  final String? gridleCondition;
  final String? culetCondition;
  final String? milky;
  final bool? eyeClean;
  final bool? bgm;
  final bool? ha;
  final String? sieveSizeMin;
  final String? sieveSizeMax;
  final String? isSeparable;
  final String? available;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? image4;
  final String? image5;
  final String? image6;
  final String? videoURL;
  final bool? isOnAuction;
  final bool? isSold;
  final bool? isMakeAnOfferAllowed;
  final double? minimumOfferPrice;
  final String? sellerCompanyName;
  final String? sellerCity;
  final String? sellerCountry;
  final Map<String, dynamic>? seller;

  factory DiamondDto.fromJson(
    Map<String, dynamic> json, {
    required bool isMelee,
  }) {
    final seller = json['seller'];
    final sellerMap = seller is Map<String, dynamic> ? seller : null;

    return DiamondDto(
      id: json['id']?.toString() ?? '',
      isMelee: isMelee,
      stockNumber: json['stockNumber']?.toString(),
      shape: json['shape']?.toString(),
      color: json['color']?.toString(),
      colorFrom: json['colorFrom']?.toString(),
      colorTo: json['colorTo']?.toString(),
      clarity: json['clarity']?.toString(),
      clarityMin: json['clarityMin']?.toString(),
      clarityMax: json['clarityMax']?.toString(),
      cut: json['cut']?.toString(),
      cutFrom: json['cutFrom']?.toString(),
      cutTo: json['cutTo']?.toString(),
      polish: json['polish']?.toString(),
      polishFrom: json['polishFrom']?.toString(),
      polishTo: json['polishTo']?.toString(),
      symmetry: json['symmetry']?.toString(),
      symmetryFrom: json['symmetryFrom']?.toString(),
      symmetryTo: json['symmetryTo']?.toString(),
      caratWeight: _toDouble(json['caratWeight']),
      caratWeightPerpcs: _toDouble(json['caratWeightPerpcs']),
      totalCaratWeight: _toDouble(json['totalCaratWeight']),
      totalPcs: _toInt(json['totalPcs']),
      pricePerCarat: _toDouble(json['pricePerCarat']),
      pricePerPcs: _toDouble(json['pricePerPcs']),
      totalPrice: _toDouble(json['totalPrice']),
      rap: _toDouble(json['rap']),
      discount: _toDouble(json['discount']),
      certificateCompanyName: json['certificateCompanyName']?.toString(),
      certificateNumber: json['certificateNumber']?.toString(),
      certification: json['certification']?.toString(),
      growthType: json['growthType']?.toString(),
      fluorescenceIntensity: json['fluorescenceIntensity']?.toString(),
      fluorescenceIntensityFrom:
          json['fluoreScenceIntensityFrom']?.toString() ??
              json['fluorescenceIntensityFrom']?.toString(),
      fluorescenceColor: json['fluorescenceColor']?.toString() ??
          json['fluoreScenceColorFrom']?.toString(),
      measurement: json['measurement']?.toString(),
      measurementMin: json['measurementMin']?.toString(),
      measurementMax: json['measurementMax']?.toString(),
      ratio: json['ratio']?.toString(),
      table: json['table']?.toString(),
      depth: json['depth']?.toString(),
      shade: json['shade']?.toString(),
      fancyColor: json['fancyColor']?.toString() ??
          json['fancyColorFrom']?.toString(),
      fancyIntencity: json['fancyIntencity']?.toString() ??
          json['fancyIntencityFrom']?.toString(),
      fancyOvertone: json['fancyOvertone']?.toString(),
      origin: json['origin']?.toString(),
      roughSource: json['roughSource']?.toString(),
      enhancement: json['enhancement']?.toString(),
      treatment: json['treatment']?.toString(),
      comment: json['comment']?.toString() ?? json['description']?.toString(),
      gridleCondition: json['gridleCondition']?.toString(),
      culetCondition: json['culetCondition']?.toString(),
      milky: json['milky']?.toString(),
      eyeClean: json['eyeClean'] as bool?,
      bgm: json['BGM'] as bool?,
      ha: json['HA'] as bool?,
      sieveSizeMin: json['sieveSizeMin']?.toString(),
      sieveSizeMax: json['sieveSizeMax']?.toString(),
      isSeparable: json['isSeparable']?.toString(),
      available: json['available']?.toString(),
      image1: json['image1']?.toString(),
      image2: json['image2']?.toString(),
      image3: json['image3']?.toString(),
      image4: json['image4']?.toString(),
      image5: json['image5']?.toString(),
      image6: json['image6']?.toString(),
      videoURL: json['videoURL']?.toString(),
      isOnAuction: json['isOnAuction'] as bool?,
      isSold: json['isSold'] as bool?,
      isMakeAnOfferAllowed: json['isMakeAnOfferAllowed'] as bool?,
      minimumOfferPrice: _toDouble(json['minimumOfferPrice']),
      sellerCompanyName: sellerMap?['companyName']?.toString(),
      sellerCity: sellerMap?['city']?.toString(),
      sellerCountry: sellerMap?['country']?.toString(),
      seller: sellerMap,
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
