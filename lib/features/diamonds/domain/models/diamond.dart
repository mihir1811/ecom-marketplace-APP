class Diamond {
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

  const Diamond({
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

  Diamond copyWith({
    String? id,
    String? shape,
    double? carat,
    double? price,
    String? cut,
    String? color,
    String? clarity,
    String? certificate,
    String? imageUrl,
    double? pricePerCarat,
    String? polish,
    String? symmetry,
    String? fluorescence,
    String? lab,
    bool? hasVideo,
    bool? hasImage,
    double? discount,
  }) {
    return Diamond(
      id: id ?? this.id,
      shape: shape ?? this.shape,
      carat: carat ?? this.carat,
      price: price ?? this.price,
      cut: cut ?? this.cut,
      color: color ?? this.color,
      clarity: clarity ?? this.clarity,
      certificate: certificate ?? this.certificate,
      imageUrl: imageUrl ?? this.imageUrl,
      pricePerCarat: pricePerCarat ?? this.pricePerCarat,
      polish: polish ?? this.polish,
      symmetry: symmetry ?? this.symmetry,
      fluorescence: fluorescence ?? this.fluorescence,
      lab: lab ?? this.lab,
      hasVideo: hasVideo ?? this.hasVideo,
      hasImage: hasImage ?? this.hasImage,
      discount: discount ?? this.discount,
    );
  }
}

class DiamondListResponse {
  final List<Diamond> diamonds;
  final int totalCount;
  final bool hasMore;
  final int page;

  const DiamondListResponse({
    required this.diamonds,
    required this.totalCount,
    required this.hasMore,
    required this.page,
  });
}
