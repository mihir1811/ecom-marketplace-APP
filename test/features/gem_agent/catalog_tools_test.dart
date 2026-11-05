import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/pagination/paginated_async_notifier.dart';
import 'package:gemworld/core/pagination/prefetched_first_page.dart';
import 'package:gemworld/core/utils/active_filter_labels.dart';
import 'package:gemworld/features/bullions/domain/models/bullions_filter_state.dart';
import 'package:gemworld/features/gem_agent/domain/agent_tool.dart';
import 'package:gemworld/features/gem_agent/domain/tool_result.dart';
import 'package:gemworld/features/gem_agent/tools/bullion_search/bullion_search_tool.dart';
import 'package:gemworld/features/gem_agent/tools/catalog/catalog_args.dart';
import 'package:gemworld/features/gem_agent/tools/gem_agent_tools.dart';
import 'package:gemworld/features/gem_agent/tools/gemstone_search/gemstone_search_tool.dart';
import 'package:gemworld/features/gem_agent/tools/jewelry_search/jewelry_search_tool.dart';
import 'package:gemworld/features/gem_agent/tools/watch_search/watch_search_tool.dart';

final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  AgentToolContext ctx(List<String> said) => AgentToolContext(
    ref: container.read(_refProvider),
    cancelToken: CancelToken(),
    userUtterances: said,
  );

  test('every tool has a unique name and an object schema', () {
    final names = gemAgentTools.map((t) => t.name).toList();
    expect(names.toSet(), hasLength(names.length));
    for (final tool in gemAgentTools) {
      expect(tool.parameters['type'], 'object', reason: tool.name);
    }
  });

  group('required slots hold the search', () {
    test('gemstone needs type, then a stated origin', () {
      const tool = GemstoneSearchTool();
      expect(
        tool.checkRequired({'origin': 'natural'}, ctx(['natural stone'])),
        isA<ToolNeedsInput>(),
      );
      final guessed = tool.checkRequired({
        'origin': 'natural',
        'gemstone_types': ['Ruby'],
      }, ctx(['show me rubies']));
      expect(guessed?.missing, ['origin']);
      expect(
        tool.checkRequired({
          'origin': 'natural',
          'gemstone_types': ['Ruby'],
        }, ctx(['natural ruby'])),
        isNull,
      );
    });

    test('jewelry needs a category, bullion needs a metal', () {
      expect(
        const JewelrySearchTool().checkRequired({}, ctx(['gold jewelry'])),
        isA<ToolNeedsInput>(),
      );
      expect(
        const JewelrySearchTool().checkRequired({
          'category': 'any',
        }, ctx(['all jewelry'])),
        isNull,
      );
      expect(
        const BullionSearchTool().checkRequired({
          'metal': 'unspecified',
        }, ctx(['a coin'])),
        isA<ToolNeedsInput>(),
      );
    });
  });

  test('watch query maps vocabulary and falls back to text search', () {
    final q = const WatchSearchTool().buildQuery(
      CatalogArgs({
        'brands': ['rolex', 'Zzyzx Horology'],
        'dial_colors': ['blue'],
        'price_max': '20000',
      }),
    );
    expect(q.filters.brands, {'Rolex'});
    expect(q.filters.dialColors, {'Blue'});
    expect(q.filters.priceMax, 20000);
    expect(q.filters.searchQuery, 'Zzyzx Horology');
  });

  test('gemstone query carries sellers and listing filters', () {
    final q = const GemstoneSearchTool().buildQuery(
      CatalogArgs({
        'origin': 'natural',
        'gemstone_types': ['Ruby'],
        'exclude_sellers': ['SRK'],
        'seller_locations': ['Jaipur'],
        'quality_grade': 'aaa',
        'availability': 'On Hold',
        'price_per_carat_max': 3000,
      }),
    );
    expect(q.filters.excludedCompanyNames, ['SRK']);
    expect(q.filters.vendorLocations, ['Jaipur']);
    expect(q.filters.selectedQualityGrade, 'AAA');
    expect(q.filters.selectedAvailabilities, ['On Hold']);
    expect(q.filters.maxPricePerCarat, 3000);
    expect(q.applied['exclude_sellers'], ['SRK']);
  });

  test('watch query maps set contents, markers and listing flags', () {
    final q = const WatchSearchTool().buildQuery(
      CatalogArgs({
        'case_shapes': ['square'],
        'dial_indexes': ['roman numerals'],
        'box_included': true,
        'papers_included': true,
        'availability': 'Sold',
        'make_an_offer': true,
      }),
    );
    expect(q.filters.caseShapes, {'Square'});
    expect(q.filters.indexes, {'Roman numerals'});
    expect(q.filters.boxIncluded && q.filters.papersIncluded, isTrue);
    expect(q.filters.selectedAvailability, 'Sold');
    expect(q.filters.makeAnOffer, isTrue);
  });

  test('unknown availability is reported, not applied', () {
    final args = CatalogArgs({'metal': 'gold', 'availability': 'soon'});
    final q = const BullionSearchTool().buildQuery(args);
    expect(q.filters.selectedAvailability, 'All');
    expect(args.ignored, ['availability:soon']);
  });

  test('jewelry query maps onto marketplace filters', () {
    final args = CatalogArgs({
      'category': 'rings',
      'metals': ['rose gold', 'unobtainium'],
      'gemstones': ['diamond'],
      'stone_origin': 'lab_grown',
      'ready_to_ship': true,
      'price_max': 100000,
      'query': 'engagement',
    });
    final q = const JewelrySearchTool().buildQuery(args);
    expect(q.filters.category, 'rings');
    expect(q.filters.metals, {'ROSE_GOLD'});
    expect(q.filters.gemstones, {'DIAMOND'});
    expect(q.filters.origins, {'LAB_GROWN'});
    expect(q.filters.availability, 'ready');
    expect(q.filters.priceMax, 100000);
    expect(q.filters.searchQuery, 'engagement');
    expect(args.ignored, ['metals:unobtainium']);
  });

  test('bullion purity must belong to the metal', () {
    final gold = const BullionSearchTool().buildQuery(
      CatalogArgs({
        'metal': 'gold',
        'purity': '24K',
        'weights': ['10g'],
      }),
    );
    expect(gold.filters.metalFilter, BullionsMetalFilter.gold);
    expect(gold.filters.selectedVariants, {'24K'});
    expect(gold.filters.weightChips, {'10g'});

    final silver = const BullionSearchTool().buildQuery(
      CatalogArgs({'metal': 'silver', 'purity': '24K'}),
    );
    expect(silver.filters.selectedVariants, isEmpty);
  });

  test('prefetched page is served once, only for identical filters', () {
    const filters = BullionsFilterState(searchQuery: 'x');
    final prefetched = PrefetchedFirstPage<BullionsFilterState, int>(
      filters: filters,
      page: const PaginatedPage(items: [1], hasMore: false, totalCount: 1),
    );
    expect(prefetched.take(const BullionsFilterState()), isNull);
    expect(prefetched.take(filters)?.items, [1]);
    expect(prefetched.take(filters), isNull);
  });

  test('active filter labels add counts only for uncovered items', () {
    final labels = ActiveFilterLabels<String>()
      ..values('brand', ['Rolex', 'Omega'])
      ..range('price', min: null, max: 5000, format: (v) => '\$$v');
    final built = labels.build(
      sections: const ['brand', 'price', 'dial'],
      count: (s) => {'brand': 3, 'price': 1, 'dial': 2}[s]!,
      title: (s) => s,
    );
    expect(built, ['Rolex, Omega', 'Under \$5000.0', 'brand · 1', 'dial · 2']);
  });
}
