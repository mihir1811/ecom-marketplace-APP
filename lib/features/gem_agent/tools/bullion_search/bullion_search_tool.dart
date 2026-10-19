import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/pagination/paginated_async_notifier.dart';
import '../../../../core/pagination/prefetched_first_page.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/active_filter_labels.dart';
import '../../../bullions/application/bullions_filter_provider.dart';
import '../../../bullions/application/bullions_list_provider.dart';
import '../../../bullions/data/repositories/bullions_repository_impl.dart';
import '../../../bullions/domain/models/billion.dart';
import '../../../bullions/domain/models/bullions_filter_state.dart';
import '../../../bullions/domain/repositories/bullions_repository.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../catalog/catalog_args.dart';
import '../catalog/catalog_search_tool.dart';

/// Bullion search (bars, coins, biscuits). Requires the metal (or "any").
class BullionSearchTool
    extends CatalogSearchTool<BullionsFilterState, Bullion> {
  const BullionSearchTool();

  static const _metals = {
    'gold': BullionsMetalFilter.gold,
    'silver': BullionsMetalFilter.silver,
    'platinum': BullionsMetalFilter.platinum,
    'palladium': BullionsMetalFilter.palladium,
    'copper': BullionsMetalFilter.copper,
    'any': BullionsMetalFilter.all,
  };

  static final List<String> _purities = {
    ...BullionsFilterState.metalVariants.values.expand((v) => v),
  }.toList();

  @override
  String get name => 'search_bullion';

  @override
  String get itemNoun => 'bullion items';

  @override
  String get description =>
      'Search bullion (gold, silver, platinum, palladium, copper bars, coins, '
      'biscuits) and open the results. Requires metal.';

  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': {
      'metal': {
        'type': 'string',
        'enum': [..._metals.keys, 'unspecified'],
        'description': '"any" if the user wants every metal.',
      },
      'purity': {
        'type': 'string',
        'enum': _purities,
        'description': 'Gold: 24K/22K/18K; silver: 999/925/Sterling; etc.',
      },
      'forms': enumList(BullionsFilterState.shapeOptions),
      'weights': enumList(
        BullionsFilterState.weightChipOptions,
        'Standard sizes; otherwise use weight_min/weight_max.',
      ),
      'weight_min': numberField('Grams.'),
      'weight_max': numberField('Grams.'),
      'conditions': enumList(BullionsFilterState.conditionOptions),
      'certifications': enumList(BullionsFilterState.certificationOptions),
      'mint_marks': enumList(BullionsFilterState.mintMarkOptions),
      'price_min': numberField('USD.'),
      'price_max': numberField('USD.'),
      ...listingFields(),
      'query': {
        'type': 'string',
        'description': 'Free text only for details no field covers.',
      },
    },
    'required': ['metal'],
    'additionalProperties': false,
  };

  @override
  String get promptGuidance => '''
Required: metal. If missing, call ask_user ("Which metal?", options ["Gold","Silver","Platinum","Any"]).
"10 gram" → weights ["10g"]; "1 ounce" → weights ["1oz"]; other weights → weight_min = weight_max in grams (1 kg = 1000). "bar"/"coin"/"biscuit" → forms. "pure gold" → purity "24K".
Example: "24 karat 10 gram gold coin" → search_bullion {"metal":"gold","purity":"24K","forms":["Coin"],"weights":["10g"]}''';

  @override
  ToolNeedsInput? checkRequired(
    Map<String, Object?> args,
    AgentToolContext context,
  ) {
    final raw = args['metal']?.toString().trim().toLowerCase();
    if (raw != null && _metals.containsKey(raw)) return null;
    return const ToolNeedsInput(
      question: 'Which metal are you looking for?',
      missing: ['metal'],
      options: ['Gold', 'Silver', 'Platinum', 'Any'],
    );
  }

  @override
  CatalogQuery<BullionsFilterState> buildQuery(CatalogArgs args) {
    final metal =
        _metals[args.text('metal')?.toLowerCase()] ?? BullionsMetalFilter.all;
    final variants =
        BullionsFilterState.metalVariants[metal] ?? const <String>[];
    final purity = CatalogArgs.matchValue(args.text('purity'), variants);
    final forms = args.pick('forms', BullionsFilterState.shapeOptions);
    final weights = args.pick('weights', BullionsFilterState.weightChipOptions);
    final (weightMin, weightMax) = args.range('weight');
    final conditions = args.pick(
      'conditions',
      BullionsFilterState.conditionOptions,
    );
    final certs = args.pick(
      'certifications',
      BullionsFilterState.certificationOptions,
    );
    final mints = args.pick('mint_marks', BullionsFilterState.mintMarkOptions);
    final (priceMin, priceMax) = args.range('price');
    final availability = args.availability();
    final makeAnOffer = args.flag('make_an_offer');
    final query = args.text('query') ?? '';

    final filters = BullionsFilterState(
      metalFilter: metal,
      selectedVariant: purity,
      searchQuery: query,
      shapes: forms.toSet(),
      weightChips: weights.toSet(),
      weightMin: weightMin ?? 0,
      weightMax: weightMax ?? 0,
      conditions: conditions.toSet(),
      certifications: certs.toSet(),
      mintMarks: mints.toSet(),
      selectedAvailability: availability ?? 'All',
      makeAnOffer: makeAnOffer,
      priceMin: priceMin ?? 0,
      priceMax: priceMax ?? 0,
    );

    const n = ActiveFilterLabels.number;
    return CatalogQuery(
      filters: filters,
      description: [
        ?purity,
        metal == BullionsMetalFilter.all ? 'all metals' : metal.label,
        ...forms,
        ...weights,
        if (weightMin != null || weightMax != null)
          '${n(weightMin ?? 0)}–${n(weightMax ?? weightMin ?? 0)} g',
        if (priceMax != null) 'under \$${n(priceMax)}',
      ].join(' · '),
      applied: {
        'metal': metal.name,
        'purity': ?purity,
        if (forms.isNotEmpty) 'forms': forms,
        if (weights.isNotEmpty) 'weights': weights,
        if (weightMin != null) 'weight_min': weightMin,
        if (weightMax != null) 'weight_max': weightMax,
        if (conditions.isNotEmpty) 'conditions': conditions,
        if (certs.isNotEmpty) 'certifications': certs,
        if (mints.isNotEmpty) 'mint_marks': mints,
        'availability': ?availability,
        if (makeAnOffer) 'make_an_offer': true,
        if (priceMin != null) 'price_min': priceMin,
        if (priceMax != null) 'price_max': priceMax,
        if (query.isNotEmpty) 'query': query,
      },
    );
  }

  @override
  Future<Result<PaginatedPage<Bullion>, Failure>> fetchFirstPage(
    Ref ref,
    BullionsFilterState filters,
    CancelToken cancelToken,
  ) async {
    final result = await ref
        .read(bullionsRepositoryProvider)
        .searchBullions(
          filters: filters,
          page: 1,
          pageSize: BullionPageSize.defaultSize,
          sort: ref.read(bullionsSortProvider),
          cancelToken: cancelToken,
        );
    return switch (result) {
      Success(value: final r) => Success(
        pageOf(r.bullions, r.totalCount, r.hasMore),
      ),
      ResultFailure(failure: final f) => ResultFailure(f),
    };
  }

  @override
  AgentEffect present(
    BullionsFilterState filters,
    PaginatedPage<Bullion> page,
  ) => PresentResultsEffect(
    route: AppRouteNames.bullions,
    publish: (ref) => presentPrefetchedBullions(
      ref,
      PrefetchedFirstPage(filters: filters, page: page),
    ),
  );
}
