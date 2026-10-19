import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/pagination/paginated_async_notifier.dart';
import '../../../../core/pagination/prefetched_first_page.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/active_filter_labels.dart';
import '../../../watches/application/watch_filter_provider.dart';
import '../../../watches/application/watch_list_provider.dart';
import '../../../watches/data/repositories/watch_brand_assets_data.dart';
import '../../../watches/data/repositories/watch_repository_impl.dart';
import '../../../watches/domain/models/watch.dart';
import '../../../watches/domain/models/watch_brand_categories.dart';
import '../../../watches/domain/models/watch_filter_state.dart';
import '../../../watches/domain/repositories/watch_repository.dart';
import '../../domain/agent_effect.dart';
import '../catalog/catalog_args.dart';
import '../catalog/catalog_search_tool.dart';

/// Watch search. No required slot: "show me watches" opens everything.
/// Brands/models outside the catalog fall back to free-text search.
class WatchSearchTool extends CatalogSearchTool<WatchFilterState, Watch> {
  const WatchSearchTool();

  static final List<String> _brands = {
    ...WatchFilterState.popularBrandOptions,
    ...watchBrandCategories.expand((g) => g.brands),
  }.toList();

  static final List<String> _models = {
    ...WatchCatalogBrands.modelsByBrand.values.expand((m) => m),
  }.toList();

  @override
  String get name => 'search_watches';

  @override
  String get itemNoun => 'watches';

  @override
  String get description =>
      'Search luxury watches by brand, model, style, movement, case, dial, '
      'strap, condition or price and open the results.';

  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': {
      'brands': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Brand names as said, e.g. Rolex, Omega.',
      },
      'models': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Model names, e.g. Submariner, Speedmaster.',
      },
      'styles': enumList(WatchFilterState.categoryOptions),
      'genders': enumList(WatchFilterState.genderOptions),
      'movements': enumList(WatchFilterState.movementOptions),
      'case_materials': enumList(WatchFilterState.caseMaterialOptions),
      'case_sizes': enumList(WatchFilterState.caseSizeRangeOptions),
      'dial_colors': enumList(WatchFilterState.dialColorOptions),
      'strap_materials': enumList(WatchFilterState.strapMaterialOptions),
      'conditions': enumList(WatchFilterState.conditionOptions),
      'price_min': numberField('USD.'),
      'price_max': numberField('USD.'),
      'case_shapes': enumList(WatchFilterState.caseShapeOptions),
      'dial_indexes': enumList(
        WatchFilterState.indexesOptions,
        'Hour markers on the dial.',
      ),
      'box_included': flagField('Comes with the original box.'),
      'papers_included': flagField('Comes with papers.'),
      'warranty_card_included': flagField('Comes with a warranty card.'),
      ...listingFields(),
      'query': {
        'type': 'string',
        'description': 'Free text only for details no field covers.',
      },
    },
    'additionalProperties': false,
  };

  @override
  String get promptGuidance => '''
No required slot; search right away with what the user said.
"automatic" → movements ["Automatic (Self-winding)"]; "new"/"unworn" → conditions ["New / Unworn"]; "used"/"pre-owned" → ["Pre-Owned"]; "diver"/"dive watch" → styles ["Diver"]; "42 mm" → case_sizes ["41-45 mm"].
"full set"/"box and papers" → box_included and papers_included true; "roman dial" → dial_indexes ["Roman numerals"]; "square watch" → case_shapes ["Square"]; "in stock" → availability "Available"; "negotiable" → make_an_offer.
Example: "blue dial Rolex Submariner under 20000" → search_watches {"brands":["Rolex"],"models":["Submariner"],"dial_colors":["Blue"],"price_max":20000}''';

  @override
  CatalogQuery<WatchFilterState> buildQuery(CatalogArgs args) {
    final (brands, unknownBrands) = args.split('brands', _brands);
    final (models, unknownModels) = args.split('models', _models);
    final styles = args.pick('styles', WatchFilterState.categoryOptions);
    final genders = args.pick('genders', WatchFilterState.genderOptions);
    final movements = args.pick('movements', WatchFilterState.movementOptions);
    final cases = args.pick(
      'case_materials',
      WatchFilterState.caseMaterialOptions,
    );
    final sizes = args.pick(
      'case_sizes',
      WatchFilterState.caseSizeRangeOptions,
    );
    final dials = args.pick('dial_colors', WatchFilterState.dialColorOptions);
    final straps = args.pick(
      'strap_materials',
      WatchFilterState.strapMaterialOptions,
    );
    final conditions = args.pick(
      'conditions',
      WatchFilterState.conditionOptions,
    );
    final (priceMin, priceMax) = args.range('price');
    final shapes = args.pick('case_shapes', WatchFilterState.caseShapeOptions);
    final indexes = args.pick('dial_indexes', WatchFilterState.indexesOptions);
    final box = args.flag('box_included');
    final papers = args.flag('papers_included');
    final warranty = args.flag('warranty_card_included');
    final availability = args.availability();
    final makeAnOffer = args.flag('make_an_offer');
    final query = [
      ...unknownBrands,
      ...unknownModels,
      ?args.text('query'),
    ].join(' ');

    final filters = WatchFilterState(
      searchQuery: query,
      brands: brands.toSet(),
      models: models.toSet(),
      categories: styles.toSet(),
      genders: genders.toSet(),
      movements: movements.toSet(),
      caseMaterials: cases.toSet(),
      caseSizeRanges: sizes.toSet(),
      dialColors: dials.toSet(),
      strapMaterials: straps.toSet(),
      conditions: conditions.toSet(),
      priceMin: priceMin ?? 0,
      priceMax: priceMax ?? 0,
      caseShapes: shapes.toSet(),
      indexes: indexes.toSet(),
      boxIncluded: box,
      papersIncluded: papers,
      warrantyCardIncluded: warranty,
      selectedAvailability: availability ?? 'All',
      makeAnOffer: makeAnOffer,
    );

    const n = ActiveFilterLabels.number;
    return CatalogQuery(
      filters: filters,
      description: [
        ...brands,
        ...models,
        ...styles,
        ...dials.map((d) => '$d dial'),
        ...movements,
        if (priceMin != null && priceMax != null)
          '\$${n(priceMin)}–\$${n(priceMax)}'
        else if (priceMax != null)
          'under \$${n(priceMax)}'
        else if (priceMin != null)
          'over \$${n(priceMin)}',
        if (query.isNotEmpty) '"$query"',
      ].join(' · '),
      applied: {
        if (brands.isNotEmpty) 'brands': brands,
        if (models.isNotEmpty) 'models': models,
        if (styles.isNotEmpty) 'styles': styles,
        if (genders.isNotEmpty) 'genders': genders,
        if (movements.isNotEmpty) 'movements': movements,
        if (cases.isNotEmpty) 'case_materials': cases,
        if (sizes.isNotEmpty) 'case_sizes': sizes,
        if (dials.isNotEmpty) 'dial_colors': dials,
        if (straps.isNotEmpty) 'strap_materials': straps,
        if (conditions.isNotEmpty) 'conditions': conditions,
        if (shapes.isNotEmpty) 'case_shapes': shapes,
        if (indexes.isNotEmpty) 'dial_indexes': indexes,
        if (box) 'box_included': true,
        if (papers) 'papers_included': true,
        if (warranty) 'warranty_card_included': true,
        'availability': ?availability,
        if (makeAnOffer) 'make_an_offer': true,
        if (priceMin != null) 'price_min': priceMin,
        if (priceMax != null) 'price_max': priceMax,
        if (query.isNotEmpty) 'query': query,
      },
    );
  }

  @override
  Future<Result<PaginatedPage<Watch>, Failure>> fetchFirstPage(
    Ref ref,
    WatchFilterState filters,
    CancelToken cancelToken,
  ) async {
    final result = await ref
        .read(watchRepositoryProvider)
        .getWatches(
          filters: filters,
          page: 1,
          pageSize: WatchPageSize.defaultSize,
          sort: ref.read(watchSortProvider),
          cancelToken: cancelToken,
        );
    return switch (result) {
      Success(value: final r) => Success(
        pageOf(r.watches, r.totalCount, r.hasMore),
      ),
      ResultFailure(failure: final f) => ResultFailure(f),
    };
  }

  @override
  AgentEffect present(WatchFilterState filters, PaginatedPage<Watch> page) =>
      PresentResultsEffect(
        route: AppRouteNames.watches,
        publish: (ref) => presentPrefetchedWatches(
          ref,
          PrefetchedFirstPage(filters: filters, page: page),
        ),
      );
}
