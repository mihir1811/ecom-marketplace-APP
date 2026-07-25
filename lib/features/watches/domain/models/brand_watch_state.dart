/// Simplified filter state for the brand-specific watch screen.
/// Only two filters: style and price range (min/max text inputs).
class BrandWatchFilterState {
  const BrandWatchFilterState({
    this.selectedStyles = const {},
    this.priceMin = '',
    this.priceMax = '',
    this.sort = BrandWatchSortOption.priceHighToLow,
  });

  final Set<String> selectedStyles;
  final String priceMin;
  final String priceMax;
  final BrandWatchSortOption sort;

  static const styleOptions = [
    'Luxury',
    'Vintage',
    'Dress',
    'Diver',
    'Sport',
    'GMT',
    'Chronograph',
  ];

  bool get hasActiveFilters =>
      selectedStyles.isNotEmpty ||
      priceMin.trim().isNotEmpty ||
      priceMax.trim().isNotEmpty;

  BrandWatchFilterState copyWith({
    Set<String>? selectedStyles,
    String? priceMin,
    String? priceMax,
    BrandWatchSortOption? sort,
  }) {
    return BrandWatchFilterState(
      selectedStyles: selectedStyles ?? this.selectedStyles,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      sort: sort ?? this.sort,
    );
  }
}

enum BrandWatchSortOption {
  priceHighToLow,
  priceLowToHigh,
  newest,
}

extension BrandWatchSortOptionLabel on BrandWatchSortOption {
  String get label => switch (this) {
        BrandWatchSortOption.priceHighToLow => 'Price: High to Low',
        BrandWatchSortOption.priceLowToHigh => 'Price: Low to High',
        BrandWatchSortOption.newest => 'Newest',
      };
}
