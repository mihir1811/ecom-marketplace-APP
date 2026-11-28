import 'rough_parcel.dart';

/// Sections of the rough filter screen, in screen order.
enum RoughFilterSection {
  crystal,
  sizePrice,
  colorClarity,
  quality,
  parcel,
  origin,
  listing,
}

/// Numeric range filters; each sends `<key>Min` / `<key>Max`.
enum RoughRange {
  carat('carat', 'carat'),
  avgCarat('avgCarat', 'avgCarat'),
  pieces('pieces', 'pieces'),
  price('price', 'price'),
  pricePerCarat('pricePerCarat', 'pricePerCarat');

  const RoughRange(this.apiPrefix, this.facetKey);

  /// Body key prefix (`caratMin`, `caratMax`, …).
  final String apiPrefix;

  /// Key under `ranges` in GET /rough-diamond/filters.
  final String facetKey;
}

/// Search filters for POST /rough-diamond/search. Every list filter is kept
/// under its API key so the body is built without a per-field mapping.
class RoughFilterState {
  const RoughFilterState({
    this.diamondType = RoughDiamondType.natural,
    this.lists = const {},
    this.flags = const {},
    this.ranges = const {},
    this.yieldMin = 0,
    this.search = '',
  });

  final RoughDiamondType diamondType;

  /// API list key → picked values (`crystalShape`, `colorWords`, …).
  final Map<String, Set<String>> lists;

  /// Boolean API keys sent as `true` (`separableOnly`, `withImages`, …).
  final Set<String> flags;

  /// Range → (min, max); 0 means no bound on that side.
  final Map<RoughRange, (double, double)> ranges;

  /// Minimum estimated yield (%); 0 means any.
  final double yieldMin;
  final String search;

  // List keys, grouped as the screen shows them.
  static const crystalKeys = [
    'crystalShape',
    'crystalCondition',
    'transparency',
    'surfaceCondition',
    'growthType',
  ];
  static const colorClarityKeys = [
    'colorGrades',
    'colorWords',
    'clarityGrades',
    'clarityWords',
    'colorDistribution',
    'fluorescence',
  ];
  static const qualityKeys = [
    'roughQuality',
    'manufacturingPotential',
    'compositionType',
  ];
  static const parcelKeys = ['parcelType', 'sieveSizes'];
  static const originKeys = ['countryOfOrigin', 'kpStatus', 'deliveryTerms'];

  static const parcelFlags = ['separableOnly'];
  static const originFlags = ['inspectionAllowed', 'labReportOnly'];
  static const listingFlags = [
    'withImages',
    'withVideo',
    'makeAnOfferOnly',
    'onAuctionOnly',
  ];

  /// D–Z colour grades a parcel's range can cover.
  static const colorGradeOptions = [
    'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  /// FL–I3 clarity grades a parcel's range can cover.
  static const clarityGradeOptions = [
    'FL', 'IF', 'VVS1', 'VVS2', 'VS1', 'VS2', //
    'SI1', 'SI2', 'SI3', 'I1', 'I2', 'I3',
  ];

  Set<String> listOf(String key) => lists[key] ?? const {};

  (double, double) rangeOf(RoughRange r) => ranges[r] ?? (0, 0);

  bool flag(String key) => flags.contains(key);

  RoughFilterState copyWith({
    RoughDiamondType? diamondType,
    Map<String, Set<String>>? lists,
    Set<String>? flags,
    Map<RoughRange, (double, double)>? ranges,
    double? yieldMin,
    String? search,
  }) {
    return RoughFilterState(
      diamondType: diamondType ?? this.diamondType,
      lists: lists ?? this.lists,
      flags: flags ?? this.flags,
      ranges: ranges ?? this.ranges,
      yieldMin: yieldMin ?? this.yieldMin,
      search: search ?? this.search,
    );
  }

  RoughFilterState toggle(String key, String value) {
    final next = {...listOf(key)};
    if (!next.remove(value)) next.add(value);
    return copyWith(lists: {...lists, key: next});
  }

  RoughFilterState setFlag(String key, bool on) {
    final next = {...flags};
    on ? next.add(key) : next.remove(key);
    return copyWith(flags: next);
  }

  RoughFilterState setRange(RoughRange r, double min, double max) =>
      copyWith(ranges: {...ranges, r: (min < 0 ? 0 : min, max < 0 ? 0 : max)});

  /// Filters cleared; the tab and the search text stay.
  RoughFilterState cleared() =>
      RoughFilterState(diamondType: diamondType, search: search);

  /// Lab-only and natural-only filters dropped when the tab changes.
  RoughFilterState withType(RoughDiamondType type) {
    if (type == diamondType) return this;
    final next = {...lists};
    if (type == RoughDiamondType.natural) {
      next.remove('growthType');
    } else {
      next
        ..remove('countryOfOrigin')
        ..remove('kpStatus');
    }
    return copyWith(diamondType: type, lists: next);
  }
}

/// Active-filter counts per section, for the toolbar badge and the index.
class RoughFilterSummary {
  const RoughFilterSummary._(this._counts);

  factory RoughFilterSummary.of(RoughFilterState s) {
    int lists(List<String> keys) =>
        keys.fold(0, (n, k) => n + s.listOf(k).length);
    int flags(List<String> keys) => keys.where(s.flag).length;
    var ranges = 0;
    for (final r in RoughRange.values) {
      final (min, max) = s.rangeOf(r);
      if (min > 0 || max > 0) ranges++;
    }
    if (s.yieldMin > 0) ranges++;
    return RoughFilterSummary._({
      RoughFilterSection.crystal: lists(RoughFilterState.crystalKeys),
      RoughFilterSection.sizePrice: ranges,
      RoughFilterSection.colorClarity: lists(RoughFilterState.colorClarityKeys),
      RoughFilterSection.quality: lists(RoughFilterState.qualityKeys),
      RoughFilterSection.parcel:
          lists(RoughFilterState.parcelKeys) +
          flags(RoughFilterState.parcelFlags),
      RoughFilterSection.origin:
          lists(RoughFilterState.originKeys) +
          flags(RoughFilterState.originFlags),
      RoughFilterSection.listing: flags(RoughFilterState.listingFlags),
    });
  }

  final Map<RoughFilterSection, int> _counts;

  int count(RoughFilterSection s) => _counts[s] ?? 0;

  int get total => _counts.values.fold(0, (a, b) => a + b);
}
