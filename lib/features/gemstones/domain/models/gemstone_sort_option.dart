/// Backend `sort_by` values for `POST /gem-stone/search` (§6 GEMSTONE_FILTERS_API).
enum GemstoneSortOption {
  newest,
  oldest,
  priceAsc,
  priceDesc,
  caratAsc,
  caratDesc,
  typeAsc,
  typeDesc;

  /// Value sent as `sort_by` in the search body.
  String get apiValue => switch (this) {
        GemstoneSortOption.newest => 'newest',
        GemstoneSortOption.oldest => 'oldest',
        GemstoneSortOption.priceAsc => 'price_asc',
        GemstoneSortOption.priceDesc => 'price_desc',
        GemstoneSortOption.caratAsc => 'carat_asc',
        GemstoneSortOption.caratDesc => 'carat_desc',
        GemstoneSortOption.typeAsc => 'type_asc',
        GemstoneSortOption.typeDesc => 'type_desc',
      };

  String get label => switch (this) {
        GemstoneSortOption.newest => 'Newest',
        GemstoneSortOption.oldest => 'Oldest',
        GemstoneSortOption.priceAsc => 'Price: Low to High',
        GemstoneSortOption.priceDesc => 'Price: High to Low',
        GemstoneSortOption.caratAsc => 'Carat: Low to High',
        GemstoneSortOption.caratDesc => 'Carat: High to Low',
        GemstoneSortOption.typeAsc => 'Type: A–Z',
        GemstoneSortOption.typeDesc => 'Type: Z–A',
      };

  /// Compact label for the listing toolbar button.
  String get shortLabel => switch (this) {
        GemstoneSortOption.newest => 'Newest',
        GemstoneSortOption.oldest => 'Oldest',
        GemstoneSortOption.priceAsc => 'Price ↑',
        GemstoneSortOption.priceDesc => 'Price ↓',
        GemstoneSortOption.caratAsc => 'Carat ↑',
        GemstoneSortOption.caratDesc => 'Carat ↓',
        GemstoneSortOption.typeAsc => 'Type A–Z',
        GemstoneSortOption.typeDesc => 'Type Z–A',
      };
}
