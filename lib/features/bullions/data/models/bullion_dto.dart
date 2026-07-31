/// Raw bullion row from `GET /bullion/all` or `GET /bullion/:id`.
class BullionDto {
  const BullionDto({
    required this.id,
    this.sellerId,
    this.stockNumber,
    this.metalTypeId,
    this.metalShapeId,
    this.metalFinenessId,
    this.metalWeight,
    this.price,
    this.quantity,
    this.design,
    this.demention,
    this.condition,
    this.mintMark,
    this.mintYear,
    this.serialNumber,
    this.certificateNumber,
    this.certification,
    this.availability,
    this.image1,
    this.image2,
    this.image3,
    this.image4,
    this.image5,
    this.image6,
    this.metalTypeName,
    this.metalShapeName,
    this.metalFinenessValue,
  });

  final String id;
  final String? sellerId;
  final String? stockNumber;
  final String? metalTypeId;
  final String? metalShapeId;
  final String? metalFinenessId;
  final double? metalWeight;
  final double? price;
  final int? quantity;
  final String? design;
  final String? demention;
  final String? condition;
  final String? mintMark;
  final int? mintYear;
  final String? serialNumber;
  final String? certificateNumber;
  final String? certification;
  final String? availability;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? image4;
  final String? image5;
  final String? image6;
  final String? metalTypeName;
  final String? metalShapeName;
  final String? metalFinenessValue;

  factory BullionDto.fromJson(Map<String, dynamic> json) {
    final metalType = json['metalType'];
    final metalShape = json['metalShape'];
    final metalFineness = json['metalFineness'];

    return BullionDto(
      id: json['id']?.toString() ?? '',
      sellerId: json['sellerId']?.toString(),
      stockNumber: json['stockNumber']?.toString(),
      metalTypeId: json['metalTypeId']?.toString(),
      metalShapeId: json['metalShapeId']?.toString(),
      metalFinenessId: json['metalFinenessId']?.toString(),
      metalWeight: _toDouble(json['metalWeight']),
      price: _toDouble(json['price']),
      quantity: _toInt(json['quantity']),
      design: json['design']?.toString(),
      demention: json['demention']?.toString(),
      condition: json['condition']?.toString(),
      mintMark: json['mintMark']?.toString(),
      mintYear: _toInt(json['mintYear']),
      serialNumber: json['serialNumber']?.toString(),
      certificateNumber: json['certificateNumber']?.toString(),
      certification: json['certification']?.toString(),
      availability: json['availability']?.toString(),
      image1: json['image1']?.toString(),
      image2: json['image2']?.toString(),
      image3: json['image3']?.toString(),
      image4: json['image4']?.toString(),
      image5: json['image5']?.toString(),
      image6: json['image6']?.toString(),
      metalTypeName: metalType is Map<String, dynamic>
          ? metalType['name']?.toString()
          : null,
      metalShapeName: metalShape is Map<String, dynamic>
          ? metalShape['name']?.toString()
          : null,
      metalFinenessValue: metalFineness is Map<String, dynamic>
          ? metalFineness['value']?.toString()
          : null,
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
