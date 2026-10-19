import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/pagination/paginated_async_notifier.dart';
import '../../../../core/pagination/prefetched_first_page.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/active_filter_labels.dart';
import '../../../jewelry/application/jewelry_filter_provider.dart';
import '../../../jewelry/application/jewelry_list_provider.dart';
import '../../../jewelry/data/repositories/jewelry_repository_impl.dart';
import '../../../jewelry/domain/models/jewelry.dart';
import '../../../jewelry/domain/models/jewelry_filter_state.dart';
import '../../../jewelry/domain/repositories/jewelry_repository.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../catalog/catalog_args.dart';
import '../catalog/catalog_search_tool.dart';

/// Jewelry search. Requires the jewelry type (rings, earrings…, or any).
class JewelrySearchTool extends CatalogSearchTool<JewelryFilterState, Jewelry> {
  const JewelrySearchTool();

  /// Model-facing category → finder category (null = every category).
  static const _categories = {
    'rings': 'Rings',
    'earrings': 'Earrings',
    'necklaces': 'Necklaces',
    'bracelets': 'Bracelets',
    'chains': 'Chains',
    'accessories': 'All Accessories',
    'any': null,
  };

  static final List<String> _styles = {
    ...JewelryFilterState.subCategoriesByParent.values.expand((s) => s),
  }.toList();

  @override
  String get name => 'search_jewelry';

  @override
  String get itemNoun => 'jewelry pieces';

  @override
  String get description =>
      'Search jewelry (rings, earrings, necklaces, bracelets, chains, '
      'accessories) and open the results. Requires category.';

  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': {
      'category': {
        'type': 'string',
        'enum': [..._categories.keys, 'unspecified'],
        'description': '"any" if the user wants all jewelry.',
      },
      'styles': enumList(_styles, 'Sub-type, e.g. Engagement, Stud, Tennis.'),
      'genders': enumList(JewelryFilterState.genderOptions),
      'occasions': enumList(JewelryFilterState.occasionOptions),
      'metal_colors': enumList(JewelryFilterState.metalColorOptions),
      'metal_purities': enumList(JewelryFilterState.metalPurityOptions),
      'metal_types': enumList(JewelryFilterState.metalTypeOptions),
      'stone_type': {
        'type': 'string',
        'enum': ['natural', 'lab_grown'],
      },
      'stone_categories': enumList(JewelryFilterState.stoneCategoryOptions),
      'stone_shapes': enumList(JewelryFilterState.stoneShapeOptions),
      'ring_sizes': enumList(JewelryFilterState.ringSizeOptions),
      'price_min': numberField('USD.'),
      'price_max': numberField('USD.'),
      ...listingFields(),
      'query': {
        'type': 'string',
        'description': 'Free text only for details no field covers.',
      },
    },
    'required': ['category'],
    'additionalProperties': false,
  };

  @override
  String get promptGuidance => '''
Required: category. If the user did not name a jewelry type, call ask_user ("What type of jewelry?", options ["Rings","Earrings","Necklaces","Bracelets"]). Use "any" only if they want all jewelry.
"gold" → metal_colors ["Yellow Gold"]; "18 karat" → metal_purities ["18K"]; "diamond ring" → stone_categories ["Diamond"]; "engagement ring" → category rings, styles ["Engagement"].
Example: "18k rose gold diamond engagement ring" → search_jewelry {"category":"rings","styles":["Engagement"],"metal_colors":["Rose Gold"],"metal_purities":["18K"],"stone_categories":["Diamond"]}''';

  @override
  ToolNeedsInput? checkRequired(
    Map<String, Object?> args,
    AgentToolContext context,
  ) {
    final raw = args['category']?.toString().trim().toLowerCase();
    if (raw != null && _categories.containsKey(raw)) return null;
    return const ToolNeedsInput(
      question: 'What type of jewelry are you looking for?',
      missing: ['category'],
      options: ['Rings', 'Earrings', 'Necklaces', 'Bracelets'],
    );
  }

  @override
  CatalogQuery<JewelryFilterState> buildQuery(CatalogArgs args) {
    final category = _categories[args.text('category')?.toLowerCase()];
    final allowedStyles = category == null
        ? _styles
        : JewelryFilterState.subCategoriesFor(category);
    final styles = args.pick('styles', allowedStyles);
    final genders = args.pick('genders', JewelryFilterState.genderOptions);
    final occasions = args.pick(
      'occasions',
      JewelryFilterState.occasionOptions,
    );
    final colors = args.pick(
      'metal_colors',
      JewelryFilterState.metalColorOptions,
    );
    final purities = args.pick(
      'metal_purities',
      JewelryFilterState.metalPurityOptions,
    );
    final metals = args.pick(
      'metal_types',
      JewelryFilterState.metalTypeOptions,
    );
    final stoneType = switch (args.text('stone_type')) {
      'natural' => 'Natural',
      'lab_grown' => 'Lab-Grown',
      _ => null,
    };
    final stones = args.pick(
      'stone_categories',
      JewelryFilterState.stoneCategoryOptions,
    );
    final shapes = args.pick(
      'stone_shapes',
      JewelryFilterState.stoneShapeOptions,
    );
    final ringSizes = args.pick(
      'ring_sizes',
      JewelryFilterState.ringSizeOptions,
    );
    final (priceMin, priceMax) = args.range('price');
    final availability = args.availability();
    final makeAnOffer = args.flag('make_an_offer');
    final query = args.text('query') ?? '';

    final filters = JewelryFilterState(
      searchQuery: query,
      category: category,
      subCategories: styles.toSet(),
      genders: genders.toSet(),
      occasions: occasions.toSet(),
      metalColors: colors.toSet(),
      metalPurities: purities.toSet(),
      metalTypes: metals.toSet(),
      stoneType: stoneType,
      stoneCategories: stones.toSet(),
      stoneShapes: shapes.toSet(),
      ringSizes: ringSizes.toSet(),
      selectedAvailability: availability ?? 'All',
      makeAnOffer: makeAnOffer,
      priceMin: (priceMin ?? JewelryFilterState.priceMinLimit).clamp(
        JewelryFilterState.priceMinLimit,
        JewelryFilterState.priceMaxLimit,
      ),
      priceMax: (priceMax ?? JewelryFilterState.priceMaxLimit).clamp(
        JewelryFilterState.priceMinLimit,
        JewelryFilterState.priceMaxLimit,
      ),
    );

    const n = ActiveFilterLabels.number;
    return CatalogQuery(
      filters: filters,
      description: [
        ...purities,
        ...colors,
        ...metals,
        ...stones,
        ...styles,
        category ?? 'all jewelry',
        if (priceMax != null) 'under \$${n(priceMax)}',
      ].join(' · '),
      applied: {
        'category': category ?? 'any',
        if (styles.isNotEmpty) 'styles': styles,
        if (genders.isNotEmpty) 'genders': genders,
        if (occasions.isNotEmpty) 'occasions': occasions,
        if (colors.isNotEmpty) 'metal_colors': colors,
        if (purities.isNotEmpty) 'metal_purities': purities,
        if (metals.isNotEmpty) 'metal_types': metals,
        if (stoneType != null) 'stone_type': stoneType,
        if (stones.isNotEmpty) 'stone_categories': stones,
        if (shapes.isNotEmpty) 'stone_shapes': shapes,
        if (ringSizes.isNotEmpty) 'ring_sizes': ringSizes,
        'availability': ?availability,
        if (makeAnOffer) 'make_an_offer': true,
        if (priceMin != null) 'price_min': priceMin,
        if (priceMax != null) 'price_max': priceMax,
        if (query.isNotEmpty) 'query': query,
      },
    );
  }

  @override
  Future<Result<PaginatedPage<Jewelry>, Failure>> fetchFirstPage(
    Ref ref,
    JewelryFilterState filters,
    CancelToken cancelToken,
  ) async {
    final result = await ref
        .read(jewelryRepositoryProvider)
        .getJewelry(
          filters: filters,
          page: 1,
          pageSize: JewelryPageSize.defaultSize,
          sort: ref.read(jewelrySortProvider),
          cancelToken: cancelToken,
        );
    return switch (result) {
      Success(value: final r) => Success(
        pageOf(r.items, r.totalCount, r.hasMore),
      ),
      ResultFailure(failure: final f) => ResultFailure(f),
    };
  }

  @override
  AgentEffect present(
    JewelryFilterState filters,
    PaginatedPage<Jewelry> page,
  ) => PresentResultsEffect(
    route: AppRouteNames.jewelryListing,
    publish: (ref) => presentPrefetchedJewelry(
      ref,
      PrefetchedFirstPage(filters: filters, page: page),
    ),
  );
}
