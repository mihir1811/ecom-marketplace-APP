/// Raw gemstone row from `POST /gem-stone/search` or `GET /gem-stone/:id`.
class GemstoneDto {
  const GemstoneDto({
    required this.id,
    this.stockNumber,
    this.gemsType,
    this.subType,
    this.shape,
    this.primaryColor,
    this.colorIntensity,
    this.colorModifier,
    this.clarity,
    this.cut,
    this.qualityGrade,
    this.totalCarat,
    this.caratPerPcs,
    this.quantity,
    this.pricePerCarat,
    this.pricePerPcs,
    this.totalPrice,
    this.discount,
    this.certificateCompanyName,
    this.certificateNumber,
    this.certification,
    this.origin,
    this.treatment,
    this.measurement,
    this.ratio,
    this.hardness,
    this.availability,
    this.isSeparable,
    this.lotType,
    this.image1,
    this.image2,
    this.image3,
    this.image4,
    this.image5,
    this.image6,
    this.videoURL,
    this.isOnAuction,
    this.isSold,
    this.tags,
  });

  final String id;
  final String? stockNumber;
  final String? gemsType;
  final String? subType;
  final String? shape;
  final String? primaryColor;
  final String? colorIntensity;
  final String? colorModifier;
  final String? clarity;
  final String? cut;
  final String? qualityGrade;
  final double? totalCarat;
  final double? caratPerPcs;
  final int? quantity;
  final double? pricePerCarat;
  final double? pricePerPcs;
  final double? totalPrice;
  final double? discount;
  final String? certificateCompanyName;
  final String? certificateNumber;

  /// May be a report URL (http/https) or legacy certification text.
  final String? certification;
  final String? origin;
  final String? treatment;
  final String? measurement;
  final String? ratio;
  final double? hardness;
  final String? availability;
  final String? isSeparable;
  final String? lotType;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? image4;
  final String? image5;
  final String? image6;
  final String? videoURL;
  final bool? isOnAuction;
  final bool? isSold;
  final String? tags;

  factory GemstoneDto.fromJson(Map<String, dynamic> json) {
    return GemstoneDto(
      id: json['id']?.toString() ?? '',
      stockNumber: json['stockNumber']?.toString(),
      gemsType: json['gemsType']?.toString(),
      subType: json['subType']?.toString(),
      shape: json['shape']?.toString(),
      primaryColor: json['primaryColor']?.toString(),
      colorIntensity: json['colorIntensity']?.toString(),
      colorModifier: json['colorModifier']?.toString(),
      clarity: json['clarity']?.toString(),
      cut: json['cut']?.toString(),
      qualityGrade: json['qualityGrade']?.toString(),
      totalCarat: _toDouble(json['totalCarat']),
      caratPerPcs: _toDouble(json['caratPerPcs']),
      quantity: _toInt(json['quantity']),
      pricePerCarat: _toDouble(json['pricePerCarat']),
      pricePerPcs: _toDouble(json['pricePerPcs']),
      totalPrice: _toDouble(json['totalPrice']),
      discount: _toDouble(json['discount']),
      certificateCompanyName: json['certificateCompanyName']?.toString(),
      certificateNumber: json['certificateNumber']?.toString(),
      certification: json['certification']?.toString(),
      origin: json['origin']?.toString(),
      treatment: json['treatment']?.toString(),
      measurement: json['measurement']?.toString(),
      ratio: json['ratio']?.toString(),
      hardness: _toDouble(json['hardness']),
      availability: json['availability']?.toString(),
      isSeparable: json['isSeparable']?.toString(),
      lotType: json['lotType']?.toString(),
      image1: json['image1']?.toString(),
      image2: json['image2']?.toString(),
      image3: json['image3']?.toString(),
      image4: json['image4']?.toString(),
      image5: json['image5']?.toString(),
      image6: json['image6']?.toString(),
      videoURL: json['videoURL']?.toString(),
      isOnAuction: json['isOnAuction'] as bool?,
      isSold: json['isSold'] as bool?,
      tags: json['tags']?.toString(),
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
