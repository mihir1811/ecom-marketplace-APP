import '../../../diamonds/domain/models/diamond_catalog_type.dart';
import '../../../diamonds/domain/models/diamond_filter_state.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../catalog/catalog_args.dart';

/// Diamond origin as the user stated it.
enum DiamondOrigin {
  natural,
  labGrown,
  unspecified;

  static DiamondOrigin parse(Object? value) =>
      switch (value?.toString().trim().toLowerCase()) {
        'natural' => natural,
        'lab_grown' || 'lab-grown' || 'lab grown' || 'lab' => labGrown,
        _ => unspecified,
      };
}

/// Optional numeric bounds; null means the user did not state that side.
typedef NumRange = ({double? min, double? max});

const NumRange _open = (min: null, max: null);

/// Validated, normalized `search_diamonds` arguments.
///
/// Values outside the catalog vocabulary are dropped and reported in
/// [ignored] instead of failing the whole search.
class DiamondSearchQuery {
  const DiamondSearchQuery({
    required this.origin,
    this.shapes = const [],
    this.caratMin,
    this.caratMax,
    this.colors = const [],
    this.fancyColors = const [],
    this.clarities = const [],
    this.cuts = const [],
    this.polish = const [],
    this.symmetry = const [],
    this.fluorescence = const [],
    this.labs = const [],
    this.growthMethods = const [],
    this.priceMin,
    this.priceMax,
    this.melee = false,
    this.fancyIntensities = const [],
    this.fancyOvertones = const [],
    this.fluorescenceColors = const [],
    this.treatments = const [],
    this.mineCountries = const [],
    this.roughSources = const [],
    this.girdles = const [],
    this.culets = const [],
    this.pricePerCarat = _open,
    this.length = _open,
    this.width = _open,
    this.height = _open,
    this.ratio = _open,
    this.table = _open,
    this.depth = _open,
    this.sellers = const [],
    this.excludeSellers = const [],
    this.sellerLocations = const [],
    this.excludeSellerLocations = const [],
    this.minSellerRating,
    this.availability,
    this.withImages = false,
    this.makeAnOffer = false,
    this.ignored = const [],
  });

  final DiamondOrigin origin;
  final List<String> shapes;
  final double? caratMin;
  final double? caratMax;
  final List<String> colors;
  final List<String> fancyColors;
  final List<String> clarities;
  final List<String> cuts;
  final List<String> polish;
  final List<String> symmetry;
  final List<String> fluorescence;
  final List<String> labs;
  final List<String> growthMethods;
  final double? priceMin;
  final double? priceMax;
  final bool melee;
  final List<String> fancyIntensities;
  final List<String> fancyOvertones;
  final List<String> fluorescenceColors;

  /// Finder enhancement labels (values of [treatmentNames]).
  final List<String> treatments;
  final List<String> mineCountries;
  final List<String> roughSources;
  final List<String> girdles;
  final List<String> culets;
  final NumRange pricePerCarat;

  /// Measurements in mm.
  final NumRange length;
  final NumRange width;
  final NumRange height;
  final NumRange ratio;

  /// Table and depth in %.
  final NumRange table;
  final NumRange depth;

  /// Seller company names as the user said them.
  final List<String> sellers;
  final List<String> excludeSellers;
  final List<String> sellerLocations;
  final List<String> excludeSellerLocations;
  final double? minSellerRating;
  final String? availability;
  final bool withImages;
  final bool makeAnOffer;
  final List<String> ignored;

  /// Width of the band a single carat weight maps to (2 ct → 2.00–2.09).
  static const double singleCaratBand = 0.09;

  static List<String> get shapeNames => [
    for (final s in kAllShapes) s['name']!,
  ];

  static const fancyColorNames = DiamondFilterState.fancyColors;

  /// Model-facing treatment names → finder enhancement labels. "None" is
  /// left out: the finder sends no filter for it.
  static const treatmentNames = {
    'HPHT': 'HPHT (Treatment)',
    'Irradiation': 'Irradiation',
    'Fracture Filling': 'Fracture Filling',
    'Laser Drilling': 'Laser Drilling',
    'Surface Coating': 'Surface Coating',
  };

  /// Rough sources the finder can filter on ("Others" sends nothing).
  static final roughSourceNames = [
    for (final s in DiamondFilterState.roughSources)
      if (s != 'Others') s,
  ];

  /// Fluorescence colours the finder can filter on ("None" sends nothing).
  static final fluorescenceColorNames = [
    for (final c in DiamondFilterState.fluorescenceColors)
      if (c != 'None') c,
  ];

  DiamondCatalogType get catalog => origin == DiamondOrigin.labGrown
      ? DiamondCatalogType.labGrown
      : DiamondCatalogType.natural;

  static DiamondSearchQuery parse(Map<String, Object?> args) {
    final a = CatalogArgs(args);
    final origin = DiamondOrigin.parse(args['origin']);
    final natural = origin != DiamondOrigin.labGrown;

    final shapes = <String>[];
    for (final raw in a.strings('shapes')) {
      final match =
          CatalogArgs.matchValue(raw, shapeNames) ?? _resolveShapeAlias(raw);
      if (match == null) {
        a.ignored.add('shapes:$raw');
      } else if (!shapes.contains(match)) {
        shapes.add(match);
      }
    }

    var (caratMin, caratMax) = a.range('carat');
    final carat = a.number('carat');
    if (carat != null && caratMin == null && caratMax == null) {
      caratMin = carat;
      caratMax = _round2(carat + singleCaratBand);
    }
    final (priceMin, priceMax) = a.range('price');
    NumRange range(String key) {
      final (min, max) = a.range(key);
      return (min: min, max: max);
    }

    final (sellers, excludeSellers) = a.includeExclude(
      'sellers',
      'exclude_sellers',
    );
    final (locations, excludeLocations) = a.includeExclude(
      'seller_locations',
      'exclude_seller_locations',
    );
    final rating = a.number('min_seller_rating');

    return DiamondSearchQuery(
      origin: origin,
      shapes: shapes,
      caratMin: caratMin,
      caratMax: caratMax,
      colors: a.pick('colors', DiamondFilterState.colors),
      fancyColors: a.pick('fancy_colors', fancyColorNames),
      clarities: a.pick('clarities', DiamondFilterState.clarities),
      cuts: a.pick('cuts', DiamondFilterState.cuts),
      polish: a.pick('polish', DiamondFilterState.polishingGrades),
      symmetry: a.pick('symmetry', DiamondFilterState.symmetryGrades),
      fluorescence: a.pick(
        'fluorescence',
        DiamondFilterState.fluorescenceGrades,
      ),
      labs: a.pick('labs', DiamondFilterState.labs),
      growthMethods: a.pick('growth_methods', DiamondFilterState.growthMethods),
      priceMin: priceMin,
      priceMax: priceMax,
      melee: a.flag('melee'),
      fancyIntensities: a.pick(
        'fancy_intensities',
        DiamondFilterState.intensities,
      ),
      fancyOvertones: a.pick('fancy_overtones', DiamondFilterState.overtones),
      fluorescenceColors: a.pick('fluorescence_colors', fluorescenceColorNames),
      treatments: [
        for (final t in a.pick('treatments', treatmentNames.keys))
          treatmentNames[t]!,
      ],
      mineCountries: natural
          ? a.pick('mine_countries', DiamondFilterState.countries)
          : const [],
      roughSources: natural
          ? a.pick('rough_sources', roughSourceNames)
          : const [],
      girdles: a.pick('girdles', DiamondFilterState.girdles),
      culets: a.pick('culets', DiamondFilterState.culets),
      pricePerCarat: range('price_per_carat'),
      length: range('length'),
      width: range('width'),
      height: range('height'),
      ratio: range('ratio'),
      table: range('table'),
      depth: range('depth'),
      sellers: sellers,
      excludeSellers: excludeSellers,
      sellerLocations: locations,
      excludeSellerLocations: excludeLocations,
      minSellerRating: rating == null || rating == 0
          ? null
          : rating.clamp(0.5, 5.0).toDouble(),
      availability: a.availability(),
      withImages: a.flag('with_images'),
      makeAnOffer: a.flag('make_an_offer'),
      ignored: a.ignored,
    );
  }

  /// Finder filter snapshot equivalent to this query.
  DiamondFilterState toFilters() {
    final isLab = origin == DiamondOrigin.labGrown;
    final fancy = melee
        ? [for (final c in fancyColors) c == 'Multi' ? 'Other' : c]
        : fancyColors;
    final isFancy =
        fancy.isNotEmpty ||
        fancyIntensities.isNotEmpty ||
        fancyOvertones.isNotEmpty;
    (double, double) bounds(NumRange r, double min, double max) =>
        (_clamp(r.min, min, max, min), _clamp(r.max, min, max, max));
    final ppc = bounds(
      pricePerCarat,
      DiamondFilterState.pricePerCaratMin,
      DiamondFilterState.pricePerCaratMax,
    );
    final len = bounds(length, _dimMin, _dimMax);
    final wid = bounds(width, _dimMin, _dimMax);
    final hgt = bounds(height, _dimMin, _dimMax);
    final rat = bounds(
      ratio,
      DiamondFilterState.ratioMin,
      DiamondFilterState.ratioMax,
    );
    final tbl = bounds(
      table,
      DiamondFilterState.tableMin,
      DiamondFilterState.tableMax,
    );
    final dep = bounds(
      depth,
      DiamondFilterState.depthMin,
      DiamondFilterState.depthMax,
    );
    return DiamondFilterState(
      labNatural: !isLab && melee
          ? LabNaturalType.labGrown
          : LabNaturalType.natural,
      labCategory: isLab && melee ? 'Lab Melee' : 'Lab Diamond',
      selectedGrowthMethods: isLab ? growthMethods : const [],
      shapes: shapes,
      minCarat: _clamp(
        caratMin,
        DiamondFilterState.caratMin,
        DiamondFilterState.caratMax,
        DiamondFilterState.caratMin,
      ),
      maxCarat: _clamp(
        caratMax,
        DiamondFilterState.caratMin,
        DiamondFilterState.caratMax,
        DiamondFilterState.caratMax,
      ),
      isFancyColor: isFancy,
      selectedFancyColors: fancy,
      selectedIntensities: isFancy ? fancyIntensities : const [],
      selectedOvertones: isFancy ? fancyOvertones : const [],
      selectedStandardColors: isFancy ? const [] : colors,
      selectedClarityGrades: clarities,
      selectedCuts: cuts,
      selectedPolish: polish,
      selectedSymmetry: symmetry,
      selectedFluorescence: fluorescence,
      selectedFluorescenceColors: fluorescenceColors,
      selectedEnhancements: treatments,
      selectedLabs: labs,
      selectedOrigins: isLab ? const [] : mineCountries,
      selectedRoughSources: isLab ? const [] : roughSources,
      selectedGirdles: girdles,
      selectedCulets: culets,
      minPrice: _clamp(
        priceMin,
        DiamondFilterState.priceMin,
        DiamondFilterState.priceMax,
        DiamondFilterState.priceMin,
      ),
      maxPrice: _clamp(
        priceMax,
        DiamondFilterState.priceMin,
        DiamondFilterState.priceMax,
        DiamondFilterState.priceMax,
      ),
      minPricePerCarat: ppc.$1,
      maxPricePerCarat: ppc.$2,
      minLength: len.$1,
      maxLength: len.$2,
      minWidth: wid.$1,
      maxWidth: wid.$2,
      minHeight: hgt.$1,
      maxHeight: hgt.$2,
      minRatio: rat.$1,
      maxRatio: rat.$2,
      minTable: tbl.$1,
      maxTable: tbl.$2,
      minDepth: dep.$1,
      maxDepth: dep.$2,
      companyNames: sellers,
      excludedCompanyNames: excludeSellers,
      vendorLocations: sellerLocations,
      excludedVendorLocations: excludeSellerLocations,
      minSellerRating: minSellerRating ?? 0,
      selectedAvailabilities: [?availability],
      searchByMedia: withImages,
      makeAnOffer: makeAnOffer,
    );
  }

  /// Short human description, e.g. "natural · Round · 2–2.09 ct · D–F".
  String describe() {
    final parts = <String>[
      origin == DiamondOrigin.labGrown ? 'lab-grown' : 'natural',
      if (melee) 'melee',
      if (shapes.isNotEmpty) shapes.join('/'),
      if (caratMin != null || caratMax != null) _caratLabel(),
      if (fancyColors.isNotEmpty) fancyColors.join('/'),
      if (fancyColors.isEmpty && colors.isNotEmpty) _span(colors),
      if (clarities.isNotEmpty) _span(clarities),
      if (cuts.isNotEmpty) '${cuts.join('/')} cut',
      if (labs.isNotEmpty) labs.join('/'),
      if (fluorescence.isNotEmpty) '${fluorescence.join('/')} fluor.',
      if (mineCountries.isNotEmpty) mineCountries.join('/'),
      if (sellers.isNotEmpty) 'seller ${sellers.join('/')}',
      if (excludeSellers.isNotEmpty) 'excluding ${excludeSellers.join('/')}',
      if (sellerLocations.isNotEmpty) 'in ${sellerLocations.join('/')}',
      if (excludeSellerLocations.isNotEmpty)
        'not in ${excludeSellerLocations.join('/')}',
      ?availability,
    ];
    return parts.join(' · ');
  }

  /// Machine-readable echo for the model's memory.
  Map<String, Object?> toJson() => {
    'origin': origin.name,
    if (shapes.isNotEmpty) 'shapes': shapes,
    'carat_min': ?caratMin,
    'carat_max': ?caratMax,
    if (colors.isNotEmpty) 'colors': colors,
    if (fancyColors.isNotEmpty) 'fancy_colors': fancyColors,
    if (fancyIntensities.isNotEmpty) 'fancy_intensities': fancyIntensities,
    if (fancyOvertones.isNotEmpty) 'fancy_overtones': fancyOvertones,
    if (clarities.isNotEmpty) 'clarities': clarities,
    if (cuts.isNotEmpty) 'cuts': cuts,
    if (polish.isNotEmpty) 'polish': polish,
    if (symmetry.isNotEmpty) 'symmetry': symmetry,
    if (fluorescence.isNotEmpty) 'fluorescence': fluorescence,
    if (fluorescenceColors.isNotEmpty)
      'fluorescence_colors': fluorescenceColors,
    if (labs.isNotEmpty) 'labs': labs,
    if (growthMethods.isNotEmpty) 'growth_methods': growthMethods,
    if (treatments.isNotEmpty) 'treatments': treatments,
    if (mineCountries.isNotEmpty) 'mine_countries': mineCountries,
    if (roughSources.isNotEmpty) 'rough_sources': roughSources,
    if (girdles.isNotEmpty) 'girdles': girdles,
    if (culets.isNotEmpty) 'culets': culets,
    'price_min': ?priceMin,
    'price_max': ?priceMax,
    for (final (key, r) in [
      ('price_per_carat', pricePerCarat),
      ('length', length),
      ('width', width),
      ('height', height),
      ('ratio', ratio),
      ('table', table),
      ('depth', depth),
    ]) ...{'${key}_min': ?r.min, '${key}_max': ?r.max},
    if (sellers.isNotEmpty) 'sellers': sellers,
    if (excludeSellers.isNotEmpty) 'exclude_sellers': excludeSellers,
    if (sellerLocations.isNotEmpty) 'seller_locations': sellerLocations,
    if (excludeSellerLocations.isNotEmpty)
      'exclude_seller_locations': excludeSellerLocations,
    'min_seller_rating': ?minSellerRating,
    'availability': ?availability,
    if (withImages) 'with_images': true,
    if (makeAnOffer) 'make_an_offer': true,
    if (melee) 'melee': true,
  };

  static const _dimMin = DiamondFilterState.dimensionMin;
  static const _dimMax = DiamondFilterState.dimensionMax;

  String _caratLabel() {
    String fmt(double v) =>
        v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    if (caratMin != null && caratMax != null) {
      return '${fmt(caratMin!)}–${fmt(caratMax!)} ct';
    }
    return caratMin != null
        ? '${fmt(caratMin!)}+ ct'
        : 'up to ${fmt(caratMax!)} ct';
  }

  static String _span(List<String> values) =>
      values.length == 1 ? values.first : '${values.first}–${values.last}';

  /// Catalog aliases ("RB", "Oval Cut"); the resolver's own "Round"
  /// fallback for unknown names is not treated as a match.
  static String? _resolveShapeAlias(String raw) {
    final resolved = resolveShapeSvgKey(raw);
    final key = CatalogArgs.normalize(raw);
    final isRound = key.contains('round') || key == 'rb' || key == 'br';
    if (resolved == 'Round' && !isRound) return null;
    return CatalogArgs.matchValue(resolved, shapeNames);
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  static double _clamp(double? v, double min, double max, double fallback) =>
      v == null ? fallback : v.clamp(min, max).toDouble();
}
