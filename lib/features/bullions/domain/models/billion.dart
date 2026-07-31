/// Domain model for a single bullion listing (metal bar/coin).
enum BullionMetal {
  gold,
  silver,
  platinum,
  palladium,
  copper;
}

/// Clean domain model used by UI and providers.
class Bullion {
  const Bullion({
    required this.id,
    required this.metal,
    required this.name,
    required this.presetVariant,
    required this.shape,
    required this.weightLabel,
    required this.weightGrams,
    required this.purity,
    required this.price,
    required this.quantityAvailable,
    required this.condition,
    required this.certification,
    required this.mintMark,
    required this.lengthMm,
    required this.widthMm,
    required this.heightMm,
    this.stockNumber,
    this.demention,
    this.availability = 'Available',
    this.mintYear,
    this.imageUrl,
    this.imageUrls = const [],
  });

  final String id;
  final BullionMetal metal;
  final String name;
  final String presetVariant;
  final String shape;
  final String weightLabel;
  final double weightGrams;

  /// Purity expressed in parts per thousand (e.g. 999.9).
  final double purity;
  final double price;
  final int quantityAvailable;
  final String condition;
  final String certification;
  final String mintMark;
  final double lengthMm;
  final double widthMm;
  final double heightMm;
  final String? stockNumber;

  /// API field spelling (`demention`) — free-text dimensions.
  final String? demention;
  final String availability;
  final int? mintYear;
  final String? imageUrl;
  final List<String> imageUrls;

  String? get renderableImageUrl {
    final value = imageUrl;
    if (value == null || value.isEmpty || value.startsWith('mock://')) {
      return null;
    }
    return value;
  }
}
