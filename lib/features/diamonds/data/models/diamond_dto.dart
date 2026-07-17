class DiamondDto {
  final String id;
  final String shape;
  final double carat;
  final double price;
  final String cut;
  final String color;
  final String clarity;
  final String certificate;
  final String? imageUrl;
  final double? pricePerCarat;
  final String? polish;
  final String? symmetry;
  final String? fluorescence;
  final String? lab;
  final bool hasVideo;
  final bool hasImage;
  final double? discount;

  const DiamondDto({
    required this.id,
    required this.shape,
    required this.carat,
    required this.price,
    required this.cut,
    required this.color,
    required this.clarity,
    required this.certificate,
    this.imageUrl,
    this.pricePerCarat,
    this.polish,
    this.symmetry,
    this.fluorescence,
    this.lab,
    this.hasVideo = false,
    this.hasImage = false,
    this.discount,
  });

  factory DiamondDto.fromJson(Map<String, dynamic> json) {
    return DiamondDto(
      id: json['id'] as String,
      shape: json['shape'] as String,
      carat: (json['carat'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      cut: json['cut'] as String,
      color: json['color'] as String,
      clarity: json['clarity'] as String,
      certificate: json['certificate'] as String,
      imageUrl: json['imageUrl'] as String?,
      pricePerCarat: (json['pricePerCarat'] as num?)?.toDouble(),
      polish: json['polish'] as String?,
      symmetry: json['symmetry'] as String?,
      fluorescence: json['fluorescence'] as String?,
      lab: json['lab'] as String?,
      hasVideo: json['hasVideo'] as bool? ?? false,
      hasImage: json['hasImage'] as bool? ?? false,
      discount: (json['discount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shape': shape,
      'carat': carat,
      'price': price,
      'cut': cut,
      'color': color,
      'clarity': clarity,
      'certificate': certificate,
      'imageUrl': imageUrl,
      'pricePerCarat': pricePerCarat,
      'polish': polish,
      'symmetry': symmetry,
      'fluorescence': fluorescence,
      'lab': lab,
      'hasVideo': hasVideo,
      'hasImage': hasImage,
      'discount': discount,
    };
  }
}
