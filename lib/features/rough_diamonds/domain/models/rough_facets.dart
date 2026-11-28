/// One filter chip value with how many parcels carry it.
class RoughFacetValue {
  const RoughFacetValue(this.value, this.count);

  final String value;
  final int count;
}

/// Low / high limits of a numeric filter, for slider and field hints.
class RoughFacetRange {
  const RoughFacetRange(this.min, this.max);

  final double min;
  final double max;
}

/// GET /rough-diamond/filters: chip values with counts (sorted by count)
/// and the numeric limits of the parcels on sale.
class RoughFacets {
  const RoughFacets({
    this.total = 0,
    this.values = const {},
    this.ranges = const {},
  });

  static const empty = RoughFacets();

  final int total;

  /// Facet key (`crystalShape`, `colorRange`, `sieveSize`, …) → values.
  final Map<String, List<RoughFacetValue>> values;

  /// Range key (`carat`, `price`, `pricePerCarat`, `pieces`, `avgCarat`).
  final Map<String, RoughFacetRange> ranges;

  List<RoughFacetValue> of(String key) => values[key] ?? const [];
}
