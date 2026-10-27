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
import '../../../jewelry/domain/models/marketplace_enums.dart';
import '../../../jewelry/domain/repositories/jewelry_repository.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../catalog/catalog_args.dart';
import '../catalog/catalog_search_tool.dart';

/// Jewelry marketplace search. Requires the jewelry type (rings, earrings…,
/// or any).
class JewelrySearchTool extends CatalogSearchTool<JewelryFilterState, Jewelry> {
  const JewelrySearchTool();

  /// Model-facing category → marketplace category slug (null = all).
  static const _categories = {
    'rings': 'rings',
    'earrings': 'earrings',
    'necklaces': 'necklaces',
    'bracelets': 'bracelets',
    'any': null,
  };

  @override
  String get name => 'search_jewelry';

  @override
  String get itemNoun => 'jewelry pieces';

  @override
  String get description =>
      'Search the jewelry marketplace (rings, earrings, necklaces, '
      'bracelets) and open the results. Requires category.';

  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': {
      'category': {
        'type': 'string',
        'enum': [..._categories.keys, 'unspecified'],
        'description': '"any" if the user wants all jewelry.',
      },
      'metals': enumList(MarketplaceEnums.metals),
      'gemstones': enumList(MarketplaceEnums.gemstones, 'Main or any stone.'),
      'stone_origin': {
        'type': 'string',
        'enum': ['natural', 'lab_grown'],
      },
      'styles': textList('Design words, e.g. Halo, Solitaire, Kundan.'),
      'occasions': textList('e.g. Wedding, Engagement, Everyday.'),
      'shapes': textList('Stone shapes, e.g. Round, Pear, Oval.'),
      'ready_to_ship': flagField('Only in-stock pieces, not made to order.'),
      'price_min': numberField('INR.'),
      'price_max': numberField('INR.'),
      'query': {
        'type': 'string',
        'description':
            'Free text for sub-types and details no field covers '
            '("engagement ring", "jhumka", "mangalsutra").',
      },
    },
    'required': ['category'],
    'additionalProperties': false,
  };

  @override
  String get promptGuidance => '''
Required: category. If the user did not name a jewelry type, call ask_user ("What type of jewelry?", options ["Rings","Earrings","Necklaces","Bracelets"]). Use "any" only if they want all jewelry.
"gold" → metals ["YELLOW_GOLD"]; "silver" → metals ["STERLING_SILVER"]; "diamond ring" → category rings, gemstones ["DIAMOND"]; "lab diamond" → stone_origin "lab_grown"; sub-types like "engagement ring" or "jhumka" go in query. Prices are rupees.
Example: "rose gold lab diamond engagement ring under 1 lakh" → search_jewelry {"category":"rings","metals":["ROSE_GOLD"],"gemstones":["DIAMOND"],"stone_origin":"lab_grown","query":"engagement","price_max":100000}''';

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
    final metals = args.pick('metals', MarketplaceEnums.metals);
    final gemstones = args.pick('gemstones', MarketplaceEnums.gemstones);
    final origin = switch (args.text('stone_origin')) {
      'natural' => 'NATURAL',
      'lab_grown' => 'LAB_GROWN',
      _ => null,
    };
    final styles = args.strings('styles');
    final occasions = args.strings('occasions');
    final shapes = args.strings('shapes');
    final ready = args.flag('ready_to_ship');
    final (priceMin, priceMax) = args.range('price');
    final query = args.text('query') ?? '';

    final filters = JewelryFilterState(
      searchQuery: query,
      category: category,
      metals: metals.toSet(),
      gemstones: gemstones.toSet(),
      origins: {?origin},
      styles: styles.toSet(),
      occasions: occasions.toSet(),
      shapes: shapes.toSet(),
      priceMin: priceMin,
      priceMax: priceMax,
      availability: ready ? JewelryAvailability.ready : null,
    );

    const n = ActiveFilterLabels.number;
    return CatalogQuery(
      filters: filters,
      description: [
        ...metals.map(MarketplaceEnums.label),
        if (origin != null) MarketplaceEnums.label(origin),
        ...gemstones.map(MarketplaceEnums.label),
        ...styles,
        if (query.isNotEmpty) query,
        category ?? 'all jewelry',
        if (priceMax != null) 'under ₹${n(priceMax)}',
      ].join(' · '),
      applied: {
        'category': category ?? 'any',
        if (metals.isNotEmpty) 'metals': metals,
        if (gemstones.isNotEmpty) 'gemstones': gemstones,
        'stone_origin': ?origin,
        if (styles.isNotEmpty) 'styles': styles,
        if (occasions.isNotEmpty) 'occasions': occasions,
        if (shapes.isNotEmpty) 'shapes': shapes,
        if (ready) 'ready_to_ship': true,
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
