/// Sort keys of POST /rough-diamond/search (`ppc` = price per carat).
enum RoughSortOption {
  newest('newest'),
  oldest('oldest'),
  priceAsc('price-asc'),
  priceDesc('price-desc'),
  ppcAsc('ppc-asc'),
  ppcDesc('ppc-desc'),
  caratAsc('carat-asc'),
  caratDesc('carat-desc');

  const RoughSortOption(this.apiValue);

  final String apiValue;
}
