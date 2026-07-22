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
    this.imageUrl,
    this.discount,
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
  final String? imageUrl;
  final double? discount;
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
