/// Clean domain representation of a gemstone listing item.
class Gemstone {
  const Gemstone({
    required this.id,
    required this.type,
    required this.carat,
    required this.price,
    required this.origin,
    required this.color,
    required this.clarity,
    required this.treatment,
    required this.shape,
    required this.hardness,
    required this.lab,
    required this.dimensions,
    this.cut,
    this.certificate,
    this.certificateUrl,
    this.imageUrl,
    this.discount,
    this.stockNumber,
    this.subType,
    this.qualityGrade,
    this.pricePerCarat,
    this.pricePerPcs,
    this.caratPerPcs,
    this.quantity,
    this.colorIntensity,
    this.imageUrls = const [],
    this.isSeparable = false,
    this.isOnAuction = false,
    this.isSold = false,
    this.availability,
    this.videoUrl,
  });

  final String id;
  final String type;
  final double carat;
  final double price;
  final String origin;
  final String color;
  final String clarity;
  final String treatment;
  final String shape;
  final double hardness;
  final String lab;
  final String dimensions;
  final String? cut;
  final String? certificate;

  /// Viewable lab report URL when API `certification` is an http(s) link.
  final String? certificateUrl;
  final String? imageUrl;
  final double? discount;
  final String? stockNumber;
  final String? subType;
  final String? qualityGrade;
  final double? pricePerCarat;
  final double? pricePerPcs;
  final double? caratPerPcs;
  final int? quantity;
  final String? colorIntensity;
  final List<String> imageUrls;
  final bool isSeparable;
  final bool isOnAuction;
  final bool isSold;
  final String? availability;
  final String? videoUrl;

  /// True when [imageUrl] is a remote http(s) URL.
  bool get hasNetworkImage {
    final url = imageUrl?.trim() ?? '';
    return url.startsWith('http://') || url.startsWith('https://');
  }
}

class GemstoneListResponse {
  const GemstoneListResponse({
    required this.gemstones,
    required this.totalCount,
    required this.hasMore,
    required this.page,
  });

  final List<Gemstone> gemstones;
  final int totalCount;
  final bool hasMore;
  final int page;
}
