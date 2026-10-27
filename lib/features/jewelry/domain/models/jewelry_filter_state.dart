/// Immutable filter state for the jewelry marketplace listing.
///
/// Mirrors `GET /marketplace/listings` query params: [category] is a parent
/// category slug (null shows every category) and [subCategory] narrows it to
/// one of its styles. Metal / gemstone / origin hold API enum values; style,
/// occasion and shape hold free-text facet values.
class JewelryFilterState {
  const JewelryFilterState({
    this.searchQuery = '',
    this.category,
    this.subCategory,
    this.shop,
    this.tag,
    this.metals = const {},
    this.gemstones = const {},
    this.origins = const {},
    this.styles = const {},
    this.occasions = const {},
    this.shapes = const {},
    this.priceMin,
    this.priceMax,
    this.availability,
  });

  final String searchQuery;
  final String? category;
  final String? subCategory;

  /// Shop slug: only that shop's listings.
  final String? shop;

  /// One exact tag.
  final String? tag;
  final Set<String> metals;
  final Set<String> gemstones;
  final Set<String> origins;
  final Set<String> styles;
  final Set<String> occasions;
  final Set<String> shapes;

  /// Rupees, compared with each listing's lowest price; null = no bound.
  final double? priceMin;
  final double? priceMax;

  /// [JewelryAvailability.ready] or [JewelryAvailability.madeToOrder].
  final String? availability;

  /// Category slug sent to the API.
  String? get categorySlug {
    final sub = subCategory?.trim();
    if (sub != null && sub.isNotEmpty) return sub;
    final c = category?.trim();
    return c == null || c.isEmpty ? null : c;
  }

  bool get hasPrice => priceMin != null || priceMax != null;

  /// Filters chosen on the filter screen (search, category, style chip and
  /// shop are shown elsewhere and not counted).
  int get activeCount =>
      metals.length +
      gemstones.length +
      origins.length +
      styles.length +
      occasions.length +
      shapes.length +
      (hasPrice ? 1 : 0) +
      (availability != null ? 1 : 0) +
      (tag != null ? 1 : 0);

  JewelryFilterState copyWith({
    String? searchQuery,
    String? category,
    bool clearCategory = false,
    String? subCategory,
    bool clearSubCategory = false,
    String? shop,
    bool clearShop = false,
    String? tag,
    bool clearTag = false,
    Set<String>? metals,
    Set<String>? gemstones,
    Set<String>? origins,
    Set<String>? styles,
    Set<String>? occasions,
    Set<String>? shapes,
    double? priceMin,
    double? priceMax,
    bool clearPrice = false,
    String? availability,
    bool clearAvailability = false,
  }) {
    return JewelryFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : (category ?? this.category),
      subCategory: clearSubCategory || clearCategory
          ? null
          : (subCategory ?? this.subCategory),
      shop: clearShop ? null : (shop ?? this.shop),
      tag: clearTag ? null : (tag ?? this.tag),
      metals: metals ?? this.metals,
      gemstones: gemstones ?? this.gemstones,
      origins: origins ?? this.origins,
      styles: styles ?? this.styles,
      occasions: occasions ?? this.occasions,
      shapes: shapes ?? this.shapes,
      priceMin: clearPrice ? null : (priceMin ?? this.priceMin),
      priceMax: clearPrice ? null : (priceMax ?? this.priceMax),
      availability: clearAvailability
          ? null
          : (availability ?? this.availability),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is JewelryFilterState &&
      other.searchQuery == searchQuery &&
      other.category == category &&
      other.subCategory == subCategory &&
      other.shop == shop &&
      other.tag == tag &&
      _sameSet(other.metals, metals) &&
      _sameSet(other.gemstones, gemstones) &&
      _sameSet(other.origins, origins) &&
      _sameSet(other.styles, styles) &&
      _sameSet(other.occasions, occasions) &&
      _sameSet(other.shapes, shapes) &&
      other.priceMin == priceMin &&
      other.priceMax == priceMax &&
      other.availability == availability;

  @override
  int get hashCode => Object.hash(
    searchQuery,
    category,
    subCategory,
    shop,
    tag,
    Object.hashAllUnordered(metals),
    Object.hashAllUnordered(gemstones),
    Object.hashAllUnordered(origins),
    Object.hashAllUnordered(styles),
    Object.hashAllUnordered(occasions),
    Object.hashAllUnordered(shapes),
    priceMin,
    priceMax,
    availability,
  );

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

/// `availability` query values.
abstract final class JewelryAvailability {
  /// In stock and not made to order.
  static const ready = 'ready';
  static const madeToOrder = 'made_to_order';
}

/// `sort` query values; the API defaults to relevance with a search, else
/// newest.
enum JewelrySortOption {
  relevance('relevance'),
  newest('newest'),
  priceAsc('price_asc'),
  priceDesc('price_desc'),
  popular('popular');

  const JewelrySortOption(this.apiValue);

  final String apiValue;
}

enum JewelryViewMode { list, grid }
