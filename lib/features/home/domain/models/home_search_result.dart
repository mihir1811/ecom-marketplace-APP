import '../../../product_detail/domain/models/product_detail.dart';

/// Catalog bucket used for web-parity ranking (`useLiveSearchResults`).
enum HomeSearchKind {
  diamond,
  lab,
  melee,
  rough,
  gemstone,
  watch,
  jewelry,
  bullion,
}

/// Unified row for home real-time search across marketplace catalogs.
class HomeSearchResult {
  const HomeSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.categoryLabel,
    required this.priceLabel,
    required this.kind,
    required this.detail,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String subtitle;
  final String categoryLabel;
  final String priceLabel;
  final HomeSearchKind kind;
  final String? imageUrl;
  final ProductDetail detail;
}
