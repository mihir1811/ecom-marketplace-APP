import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/pagination/paginated_async_notifier.dart';
import '../../../../core/pagination/prefetched_first_page.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/active_filter_labels.dart';
import '../../../gemstones/application/gemstone_list_provider.dart';
import '../../../gemstones/data/repositories/gemstone_repository_impl.dart';
import '../../../gemstones/domain/models/gemstone.dart';
import '../../../gemstones/domain/models/gemstone_filter_state.dart';
import '../../../gemstones/domain/repositories/gemstone_repository.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../catalog/catalog_args.dart';
import '../catalog/catalog_search_tool.dart';
import '../catalog/origin_slot.dart';

/// Coloured gemstone search (ruby, sapphire, emerald…). Requires origin and
/// gemstone type; opens gemstone results with the first page prefetched.
class GemstoneSearchTool
    extends CatalogSearchTool<GemstoneFilterState, Gemstone> {
  const GemstoneSearchTool();

  static const _caratBand = 0.09;

  @override
  String get name => 'search_gemstones';

  @override
  String get itemNoun => 'gemstones';

  @override
  String get description =>
      'Search coloured gemstones (ruby, sapphire, emerald, tanzanite…) and '
      'open the results. Requires origin and gemstone type. Not for diamonds.';

  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': {
      'origin': StoneOrigin.schema,
      'gemstone_types': enumList(GemstoneFilterState.allGemstoneTypes),
      'shapes': enumList(GemstoneFilterState.shapes),
      'carat': numberField('One stated weight, e.g. 3 for "3 carat".'),
      'carat_min': numberField(),
      'carat_max': numberField(),
      'colors': enumList(GemstoneFilterState.colors),
      'clarities': enumList(GemstoneFilterState.clarities),
      'cut_grades': enumList(GemstoneFilterState.cutGrades),
      'certifications': enumList(GemstoneFilterState.certifications),
      'treatments': enumList(GemstoneFilterState.treatments),
      'origin_countries': enumList(
        GemstoneFilterState.origins,
        'Mine origin, e.g. Burma, Colombia (natural only).',
      ),
      'price_min': numberField('Total price, USD.'),
      'price_max': numberField('Total price, USD.'),
      'melee': {
        'type': 'boolean',
        'description': 'True only for melee / small parcels.',
      },
      'color_intensities': enumList(GemstoneFilterState.colorIntensities),
      'quality_grade': {
        'type': 'string',
        'enum': GemstoneFilterState.qualityGrades,
        'description': 'One trade grade, e.g. AAA.',
      },
      'fluorescence': enumList(GemstoneFilterState.fluorescenceGrades),
      'fluorescence_color': {
        'type': 'string',
        'enum': [
          for (final c in GemstoneFilterState.fluorescenceColors)
            if (c != 'None') c,
        ],
      },
      'price_per_carat_min': numberField('USD per carat.'),
      'price_per_carat_max': numberField('USD per carat.'),
      'length_min': numberField('mm.'),
      'length_max': numberField('mm.'),
      'width_min': numberField('mm.'),
      'width_max': numberField('mm.'),
      'height_min': numberField('mm.'),
      'height_max': numberField('mm.'),
      ...sellerFields(),
      'with_images': flagField('Only listings with photos.'),
      ...listingFields(),
    },
    'required': ['origin', 'gemstone_types'],
    'additionalProperties': false,
  };

  @override
  String get promptGuidance => '''
Required: origin and gemstone_types. Ask with ask_user for whichever is missing (origin options ["Natural","Lab-grown"]). Never assume natural.
"unheated" → treatments ["None"]; "Burmese ruby" → origin_countries ["Burma"]; "Colombian emerald" → ["Colombia"].
Carat, price, seller ("except SRK" → exclude_sellers), location, availability and offer rules match search_diamonds. "vivid"/"intense" colour wording → color_intensities only when it matches a listed value.
Example: "natural 3 carat oval sapphire" → search_gemstones {"origin":"natural","gemstone_types":["Sapphire"],"shapes":["Oval"],"carat":3}''';

  @override
  ToolNeedsInput? checkRequired(
    Map<String, Object?> args,
    AgentToolContext context,
  ) {
    final types = CatalogArgs(
      args,
    ).pick('gemstone_types', GemstoneFilterState.allGemstoneTypes);
    if (types.isEmpty) {
      return const ToolNeedsInput(
        question: 'Which gemstone are you looking for?',
        missing: ['gemstone_types'],
        options: ['Ruby', 'Sapphire', 'Emerald', 'Tanzanite'],
      );
    }
    return StoneOrigin.require(
      StoneOrigin.parse(args['origin']),
      context.userUtterances,
      noun: 'gemstone',
    );
  }

  @override
  CatalogQuery<GemstoneFilterState> buildQuery(CatalogArgs args) {
    final lab = StoneOrigin.parse(args.text('origin')) == StoneOrigin.labGrown;
    final melee = args.flag('melee');
    final types = args.pick(
      'gemstone_types',
      GemstoneFilterState.allGemstoneTypes,
    );
    final shapes = args.pick('shapes', GemstoneFilterState.shapes);
    var (caratMin, caratMax) = args.range('carat');
    final carat = args.number('carat');
    if (carat != null && caratMin == null && caratMax == null) {
      caratMin = carat;
      caratMax = carat + _caratBand;
    }
    final (priceMin, priceMax) = args.range('price');
    final colors = args.pick('colors', GemstoneFilterState.colors);
    final clarities = args.pick('clarities', GemstoneFilterState.clarities);
    final cuts = args.pick('cut_grades', GemstoneFilterState.cutGrades);
    final certs = args.pick(
      'certifications',
      GemstoneFilterState.certifications,
    );
    final treatments = args.pick('treatments', GemstoneFilterState.treatments);
    final countries = lab
        ? const <String>[]
        : args.pick('origin_countries', GemstoneFilterState.origins);
    final intensities = args.pick(
      'color_intensities',
      GemstoneFilterState.colorIntensities,
    );
    final grade = CatalogArgs.matchValue(
      args.text('quality_grade'),
      GemstoneFilterState.qualityGrades,
    );
    final fluorescence = args.pick(
      'fluorescence',
      GemstoneFilterState.fluorescenceGrades,
    );
    final fluoColor = CatalogArgs.matchValue(
      args.text('fluorescence_color'),
      GemstoneFilterState.fluorescenceColors.where((c) => c != 'None'),
    );
    final (ppcMin, ppcMax) = args.range('price_per_carat');
    final (lengthMin, lengthMax) = args.range('length');
    final (widthMin, widthMax) = args.range('width');
    final (heightMin, heightMax) = args.range('height');
    final (sellers, excludeSellers) = args.includeExclude(
      'sellers',
      'exclude_sellers',
    );
    final (locations, excludeLocations) = args.includeExclude(
      'seller_locations',
      'exclude_seller_locations',
    );
    final availability = args.availability();
    final withImages = args.flag('with_images');
    final makeAnOffer = args.flag('make_an_offer');

    double clampCarat(double? v, double fallback) => v == null
        ? fallback
        : v.clamp(GemstoneFilterState.caratMin, GemstoneFilterState.caratMax);
    double clampPrice(double? v, double fallback) => v == null
        ? fallback
        : v.clamp(
            GemstoneFilterState.priceMin,
            GemstoneFilterState.totalPriceMax,
          );
    double clampPpc(double? v, double fallback) => v == null
        ? fallback
        : v.clamp(
            GemstoneFilterState.priceMin,
            GemstoneFilterState.pricePerPieceMax,
          );
    double clampDim(double? v, double fallback) => v == null
        ? fallback
        : v.clamp(
            GemstoneFilterState.dimensionMin,
            GemstoneFilterState.dimensionMax,
          );
    const dimMin = GemstoneFilterState.dimensionMin;
    const dimMax = GemstoneFilterState.dimensionMax;

    final filters = GemstoneFilterState(
      stoneType: lab ? 'Lab Grown' : 'Natural',
      lotType: melee ? 'Melee' : 'Single',
      selectedGemstoneTypes: types,
      selectedShapes: shapes,
      minTotalCarat: melee
          ? GemstoneFilterState.caratMin
          : clampCarat(caratMin, GemstoneFilterState.caratMin),
      maxTotalCarat: melee
          ? GemstoneFilterState.caratMax
          : clampCarat(caratMax, GemstoneFilterState.caratMax),
      minTotalPrice: clampPrice(priceMin, GemstoneFilterState.priceMin),
      maxTotalPrice: clampPrice(priceMax, GemstoneFilterState.totalPriceMax),
      selectedColors: colors,
      selectedClarities: clarities,
      selectedCutGrades: cuts,
      selectedCertifications: certs,
      selectedTreatments: treatments,
      selectedOriginCountries: countries,
      selectedIntensities: intensities,
      selectedQualityGrade: grade,
      selectedFluorescence: fluorescence,
      selectedFluorescenceColor: fluoColor,
      minPricePerCarat: clampPpc(ppcMin, GemstoneFilterState.priceMin),
      maxPricePerCarat: clampPpc(ppcMax, GemstoneFilterState.pricePerPieceMax),
      minLength: clampDim(lengthMin, dimMin),
      maxLength: clampDim(lengthMax, dimMax),
      minWidth: clampDim(widthMin, dimMin),
      maxWidth: clampDim(widthMax, dimMax),
      minHeight: clampDim(heightMin, dimMin),
      maxHeight: clampDim(heightMax, dimMax),
      companyNames: sellers,
      excludedCompanyNames: excludeSellers,
      vendorLocations: locations,
      excludedVendorLocations: excludeLocations,
      selectedAvailabilities: [?availability],
      searchByMedia: withImages,
      makeAnOffer: makeAnOffer,
    );

    const n = ActiveFilterLabels.number;
    return CatalogQuery(
      filters: filters,
      description: [
        lab ? 'lab-grown' : 'natural',
        types.join('/'),
        if (shapes.isNotEmpty) shapes.join('/'),
        if (!melee && (caratMin != null || caratMax != null))
          '${n(caratMin ?? GemstoneFilterState.caratMin)}–'
              '${n(caratMax ?? GemstoneFilterState.caratMax)} ct',
        if (colors.isNotEmpty) colors.join('/'),
        if (countries.isNotEmpty) countries.join('/'),
        ?grade,
        if (sellers.isNotEmpty) 'seller ${sellers.join('/')}',
        if (excludeSellers.isNotEmpty) 'excluding ${excludeSellers.join('/')}',
        if (locations.isNotEmpty) 'in ${locations.join('/')}',
        if (excludeLocations.isNotEmpty) 'not in ${excludeLocations.join('/')}',
        ?availability,
      ].join(' · '),
      applied: {
        'origin': lab ? 'lab_grown' : 'natural',
        'gemstone_types': types,
        if (shapes.isNotEmpty) 'shapes': shapes,
        if (caratMin != null) 'carat_min': caratMin,
        if (caratMax != null) 'carat_max': caratMax,
        if (priceMin != null) 'price_min': priceMin,
        if (priceMax != null) 'price_max': priceMax,
        if (colors.isNotEmpty) 'colors': colors,
        if (clarities.isNotEmpty) 'clarities': clarities,
        if (cuts.isNotEmpty) 'cut_grades': cuts,
        if (certs.isNotEmpty) 'certifications': certs,
        if (treatments.isNotEmpty) 'treatments': treatments,
        if (countries.isNotEmpty) 'origin_countries': countries,
        if (melee) 'melee': true,
        if (intensities.isNotEmpty) 'color_intensities': intensities,
        'quality_grade': ?grade,
        if (fluorescence.isNotEmpty) 'fluorescence': fluorescence,
        'fluorescence_color': ?fluoColor,
        'price_per_carat_min': ?ppcMin,
        'price_per_carat_max': ?ppcMax,
        'length_min': ?lengthMin,
        'length_max': ?lengthMax,
        'width_min': ?widthMin,
        'width_max': ?widthMax,
        'height_min': ?heightMin,
        'height_max': ?heightMax,
        if (sellers.isNotEmpty) 'sellers': sellers,
        if (excludeSellers.isNotEmpty) 'exclude_sellers': excludeSellers,
        if (locations.isNotEmpty) 'seller_locations': locations,
        if (excludeLocations.isNotEmpty)
          'exclude_seller_locations': excludeLocations,
        'availability': ?availability,
        if (withImages) 'with_images': true,
        if (makeAnOffer) 'make_an_offer': true,
      },
    );
  }

  @override
  Future<Result<PaginatedPage<Gemstone>, Failure>> fetchFirstPage(
    Ref ref,
    GemstoneFilterState filters,
    CancelToken cancelToken,
  ) async {
    final result = await ref
        .read(gemstoneRepositoryProvider)
        .getGemstones(
          filters: filters,
          page: 1,
          pageSize: GemstonePageSize.defaultSize,
          sortBy: ref.read(gemstoneSortProvider).apiValue,
          cancelToken: cancelToken,
        );
    return switch (result) {
      Success(value: final r) => Success(
        pageOf(r.gemstones, r.totalCount, r.hasMore),
      ),
      ResultFailure(failure: final f) => ResultFailure(f),
    };
  }

  @override
  AgentEffect present(
    GemstoneFilterState filters,
    PaginatedPage<Gemstone> page,
  ) => PresentResultsEffect(
    route: AppRouteNames.gemstoneResults,
    publish: (ref) => presentPrefetchedGemstones(
      ref,
      PrefetchedFirstPage(filters: filters, page: page),
    ),
  );
}
