# Diamond Listings Results Screen — Performance Specification

**Author**: Performance Benchmarker  
**Target App**: GemWorld Flutter Marketplace  
**Status**: Final  
**Date**: 2026-07-15

---

## 1. List Virtualization Strategy

### 1.1 Builder Widgets — Never Eager Build

Both view modes **must** use lazy builders — never `ListView(children: [...])` or `GridView(children: [...])`.

```dart
// ✅ Correct — list mode
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => DiamondListCard(item: items[index]),
)

// ✅ Correct — grid mode
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.72,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  ),
  itemCount: items.length,
  itemBuilder: (context, index) => DiamondGridCard(item: items[index]),
)
```

### 1.2 CustomScrollView with Slivers

Use `CustomScrollView` with `SliverToBoxAdapter` for header sections and `SliverList` / `SliverGrid` for results. This enables the filter chips + sort bar + results to scroll as a single unit without nesting scrollables.

```dart
CustomScrollView(
  controller: _scrollController,
  slivers: [
    // Fixed header slivers
    SliverToBoxAdapter(child: FilterChipsRow(filters: activeFilters)),
    SliverToBoxAdapter(child: SortBar(...)),
    SliverToBoxAdapter(child: ResultsCountLabel(count: totalResults)),
    // Scrollable results — switches between list/grid
    if (isGridView)
      SliverGrid(...)
    else
      SliverList(...),
    // Bottom loading indicator
    if (isLoadingMore)
      const SliverToBoxAdapter(child: BottomShimmerLoader()),
  ],
)
```

### 1.3 Stable Keys — ValueKey per Diamond

Every diamond item **must** use `ValueKey(diamond.id)` for efficient element diffing. Never use an index-based key.

```dart
// ✅ Correct
SliverList(
  delegate: SliverChildBuilderDelegate(
    (context, index) {
      final diamond = items[index];
      return DiamondGridCard(key: ValueKey(diamond.id), diamond: diamond);
    },
    childCount: items.length,
  ),
)
```

### 1.4 Fixed Item Dimensions

Use `itemExtent` for list mode (fixed card height) and `childAspectRatio` for grid mode. This allows Flutter to compute layout without measuring each child.

- **List card height**: 120px (`itemExtent: 120.0`)
- **Grid card aspect ratio**: 0.72 (width / height)

---

## 2. Pagination Architecture

### 2.1 Page Configuration

| Parameter | Value |
|-----------|-------|
| Page size | 20 items |
| Scroll trigger distance | 300px from bottom |
| Max concurrent requests | 1 |
| Request timeout | 30s |
| Retry policy | 2 retries, exponential backoff |

### 2.2 Scroll Listener Guard

Attach a listener on `ScrollController`. Fire next page only when:
1. `_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300.0`
2. `!isLoadingMore` guard is `true`
3. `hasMore` is `true`

```dart
void _onScroll() {
  if (_isLoadingMore || !_hasMore) return;
  final maxScroll = _scrollController.position.maxScrollExtent;
  final currentScroll = _scrollController.position.pixels;
  if (currentScroll >= maxScroll - 300.0) {
    ref.read(diamondListProvider.notifier).loadNextPage();
  }
}
```

### 2.3 Duplicate Request Guard

The `DiamondListNotifier` **must** guard against duplicate concurrent requests:

```dart
class DiamondListNotifier extends AsyncNotifier<DiamondListState> {
  Future<void> loadNextPage() async {
    final state = super.state;
    if (state is AsyncLoading || (state.hasValue && state.value!.isLoadingMore)) return;
    if (state.hasValue && !state.value!.hasMore) return;

    state = AsyncLoading(
      // Keep previous data visible while loading
      state.hasValue ? state.value : null,
    );

    // ... fetch next page
  }
}
```

### 2.4 Pagination State Model

```dart
@freezed
class DiamondListState with _$DiamondListState {
  const factory DiamondListState({
    required List<DiamondSummary> items,
    required int currentPage,
    required bool hasMore,
    required bool isLoadingMore,
    String? errorMessage,
  }) = _DiamondListState;

  const DiamondListState._();

  bool get isEmpty => items.isEmpty && !isLoadingMore;
}
```

### 2.5 Bottom Loading Indicator

Show a compact shimmer at the bottom of the list while loading the next page. Do **not** show a full-screen loader.

```dart
class BottomShimmerLoader extends StatelessWidget {
  const BottomShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
```

---

## 3. Image Performance

### 3.1 Always Use cached_network_image

**Never** use bare `Image.network()`. Always use `CachedNetworkImage` with explicit dimensions.

**Add to pubspec.yaml:**
```yaml
dependencies:
  cached_network_image: ^3.4.1
```

### 3.2 Explicit Memory Cache Dimensions

Every diamond image **must** set `memCacheWidth` and `memCacheHeight` to prevent loading full-resolution images into memory for thumbnails.

```dart
// ✅ Grid thumbnail — small cache size
CachedNetworkImage(
  imageUrl: diamond.thumbnailUrl,
  width: 140,
  height: 140,
  memCacheWidth: 280,   // 2x for retina
  memCacheHeight: 280,
  fit: BoxFit.contain,
  placeholder: (ctx, url) => const DiamondSvgPlaceholder(),
  errorWidget: (ctx, url, err) => const DiamondSvgPlaceholder(),
)

// ✅ List thumbnail — medium cache size
CachedNetworkImage(
  imageUrl: diamond.thumbnailUrl,
  width: 100,
  height: 100,
  memCacheWidth: 200,
  memCacheHeight: 200,
  fit: BoxFit.contain,
  placeholder: (ctx, url) => const DiamondSvgPlaceholder(),
  errorWidget: (ctx, url, err) => const DiamondSvgPlaceholder(),
)
```

### 3.3 Thumbnail vs Full-Size URL Strategy

The API response must provide two image URLs per diamond:

```dart
class DiamondSummary {
  final String id;
  final String thumbnailUrl;  // 300x300 CDN thumbnail
  final String imageUrl;      // Full-size for detail page
  // ...
}
```

- **List/Grid** → always use `thumbnailUrl`
- **Detail page** → use `imageUrl`

### 3.4 Placeholder Widget

Create a reusable `DiamondSvgPlaceholder` widget that renders a diamond outline SVG from `assets/shapes/` while the network image loads.

```dart
class DiamondSvgPlaceholder extends StatelessWidget {
  const DiamondSvgPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: SvgPicture.asset(
          'assets/shapes/diamond_outline.svg',
          width: 32,
          height: 32,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurfaceVariant,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
```

### 3.5 Cache Limits

Configure `CachedNetworkImage` globally with a max memory cache of 100MB:

```dart
// In main.dart or app bootstrap
import 'package:cached_network_image/cached_network_image.dart';

void bootstrapCache() {
  CacheManagerConfig.defaultCacheManager = CacheManager(
    Config(
      'cached_images',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 500,
      repo: JsonCacheInfoRepository(),
      fileService: ImageFileService(),
    ),
  );
}
```

---

## 4. State Update Isolation

### 4.1 Narrow .select() Calls — Never Watch the Whole State

Every `Consumer` widget must use `.select()` to listen only to the slice of state it needs. A single giant `Consumer` watching the entire `AsyncValue<DiamondListState>` is **forbidden**.

```dart
// ✅ FilterChipsRow only watches active filters from the filter state
Consumer(
  builder: (context, ref, child) {
    final filterState = ref.watch(diamondSearchProvider.select((s) => s.activeFilters));
    return FilterChipsRow(filters: filterState);
  },
)

// ✅ SortBar watches only sort order
Consumer(
  builder: (context, ref, child) {
    final sort = ref.watch(diamondSortProvider);
    return SortBar(currentSort: sort);
  },
)

// ✅ Grid/List toggle watches only view mode
Consumer(
  builder: (context, ref, child) {
    final viewMode = ref.watch(diamondListViewModeProvider);
    return ViewToggleButton(viewMode: viewMode);
  },
)
```

### 4.2 Independent Providers

Split the monolithic state into independent providers:

```dart
// --- File: lib/features/diamonds/application/diamond_list_providers.dart ---

/// View mode toggle — never triggers a network request
final diamondListViewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.grid);

/// Sort order — triggers a new list fetch
final diamondSortProvider = StateProvider<DiamondSort>((ref) => DiamondSort.priceLowHigh);

/// Paginated list state — fetches from API
final diamondListProvider = AsyncNotifierProvider<DiamondListNotifier, DiamondListState>(
  DiamondListNotifier.new,
);

/// Extracted active filter summary — derived from search provider
final activeFilterChipsProvider = Provider<List<FilterChipData>>((ref) {
  final filterState = ref.watch(diamondSearchProvider);
  return filterState.activeFilters; // logic in DiamondFilterState
});
```

### 4.3 Grid/List Toggle Rebuild Isolation

When the user toggles between grid and list, **only** the sliver content rebuilds. The header chips, sort bar, and results count remain unchanged.

```dart
// In the screen build method:
final viewMode = ref.watch(diamondListViewModeProvider);
// No other rebuild — only the SliverList/SliverGrid branch below changes
```

### 4.4 Sort Change Isolation

Changing sort should **not** rebuild filter chips or the view toggle. It should only:
1. Set the sort value in `diamondSortProvider`
2. Reset the list to page 1
3. Fetch new sorted results

---

## 5. Rebuild Minimization

### 5.1 Const Constructors

Every widget in the listing screen **must** have a `const` constructor. This includes:
- `DiamondGridCard`
- `DiamondListCard`
- `FilterChipsRow`
- `SortBar`
- `ResultsCountLabel`
- `BottomShimmerLoader`
- `DiamondSvgPlaceholder`

```dart
class DiamondGridCard extends StatelessWidget {
  const DiamondGridCard({super.key, required this.diamond});
  final DiamondSummary diamond;
  // ...
}
```

### 5.2 AppBar/Header — No Scroll Rebuild

The `AppBar` title and the `Scaffold` shell must not rebuild when the user scrolls the results list. Use a plain `AppBar` outside the `CustomScrollView`.

### 5.3 RepaintBoundary

Wrap animated or frequently repainting sections with `RepaintBoundary`:

```dart
RepaintBoundary(
  child: AnimatedSwitcher(
    duration: Duration(milliseconds: 200),
    child: isGridView ? _buildGrid() : _buildList(),
  ),
)
```

### 5.4 Avoid Opacity for Show/Hide

**Never** use `Opacity` widget for conditional visibility. Use `AnimatedSwitcher` or conditional `if` in the widget tree.

```dart
// ❌ Bad — Opacity still renders the widget
Opacity(opacity: isLoading ? 0.0 : 1.0, child: list)

// ✅ Good — conditional build
if (!isLoading) list else shimmer
```

### 5.5 Diamond Card — Pure Widget, No Side Effects

Diamond cards must be pure presentation widgets with no providers, no API calls, and no mutation logic. Tap handlers should be passed via constructor callbacks.

---

## 6. Memory Management

### 6.1 ScrollController Disposal

`ScrollController` **must** be created in `initState` and disposed in `dispose`. Use `ConsumerStatefulWidget`.

```dart
class DiamondListingsScreen extends ConsumerStatefulWidget {
  const DiamondListingsScreen({super.key});
  @override
  ConsumerState<DiamondListingsScreen> createState() => _DiamondListingsScreenState();
}

class _DiamondListingsScreenState extends ConsumerState<DiamondListingsScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  // ...
}
```

### 6.2 Image Cache Limit

Set `CachedNetworkImage` cache limits as described in §3.5. Additionally, consider using `ImageCache` from `painting.dart`:

```dart
// In app bootstrap
PaintingBinding.instance.imageCache.maximumSize = 500;       // max 500 entries
PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB
```

### 6.3 Pagination Memory Eviction

If the list grows beyond 5 pages (100 items), evict the earliest pages from the in-memory list but keep them in the Hive disk cache (see §12.4). Only the last 5 pages (100 items) should be held in the `items` list at any time.

```dart
// Inside DiamondListNotifier.loadNextPage
const maxCachedPages = 5;
const pageSize = 20;

if (newState.items.length > maxCachedPages * pageSize) {
  final excess = newState.items.length - maxCachedPages * pageSize;
  newState.items.removeRange(0, excess);
  // Items are still accessible from disk cache for scroll-back
}
```

### 6.4 Lazy Detail Data

Diamond detail data (full description, certificate images, seller info) must **not** be loaded until the user taps a card to navigate to the detail screen. Summary data only in the list.

---

## 7. Initial Load Optimization

### 7.1 Skeleton Shimmer

Show a skeleton shimmer immediately while the API call is in flight. The shimmer must match the grid/list layout (8 skeleton grid cards or 5 skeleton list cards).

```dart
class DiamondGridShimmer extends StatelessWidget {
  const DiamondGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 8,
      itemBuilder: (ctx, i) => const ShimmerCard(),
    );
  }
}
```

### 7.2 Debounce Filter Changes

When filters change on the search screen, debounce by **400ms** before navigating to or re-fetching the listings screen.

```dart
// In DiamondSearchNotifier or a dedicated debounce provider
class FilterDebounceNotifier extends StateNotifier<Timer?> {
  FilterDebounceNotifier() : super(null);

  void schedule(Duration duration, VoidCallback action) {
    state?.cancel();
    state = Timer(duration, action);
  }
}
```

### 7.3 Keep Previous Results Visible

When re-fetching due to filter/sort changes, keep the previous result list visible with a loading overlay instead of blanking the screen.

```dart
// ✅ AsyncLoading preserves previous value
state = AsyncLoading(state.value);
```

---

## 8. Provider Structure

### 8.1 Complete Provider File

Create `lib/features/diamonds/application/diamond_list_providers.dart`:

```dart
// --- Independence boundaries ---
// 1. ViewMode — never triggers network
// 2. DiamondSort — triggers re-fetch w/ new sort
// 3. DiamondListState — paginated fetch, debounced
// 4. ActiveFilterChips — derived from search state only

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/diamond_filter_state.dart';

// ─── Enums / Types ───────────────────────────────────────────

enum ViewMode { grid, list }

enum DiamondSort {
  priceLowHigh('Price: Low → High', 'price_asc'),
  priceHighLow('Price: High → Low', 'price_desc'),
  caratLowHigh('Carat: Low → High', 'carat_asc'),
  caratHighLow('Carat: High → Low', 'carat_desc'),
  newest('Newest First', 'newest'),
  discount('Biggest Discount', 'discount');

  final String label;
  final String apiValue;
  const DiamondSort(this.label, this.apiValue);
}

// ─── Independent Providers ──────────────────────────────────

final diamondListViewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.grid);

final diamondSortProvider = StateProvider<DiamondSort>((ref) => DiamondSort.priceLowHigh);

final diamondListProvider = AsyncNotifierProvider<DiamondListNotifier, DiamondListState>(
  DiamondListNotifier.new,
);

// ─── Derived Active Filter Chips ────────────────────────────

class FilterChipData {
  final String label;
  final String filterKey;
  final VoidCallback onDismiss;
  const FilterChipData({required this.label, required this.filterKey, required this.onDismiss});
}

final activeFilterChipsProvider = Provider<List<FilterChipData>>((ref) {
  final filterState = ref.watch(diamondSearchProvider);
  final chips = <FilterChipData>[];
  // Build chips from non-default filter values...
  return chips;
});
```

### 8.2 DiamondListNotifier

```dart
class DiamondListNotifier extends AsyncNotifier<DiamondListState> {
  @override
  DiamondListState build() {
    ref.listen(diamondSearchProvider, (prev, next) => _onFilterOrSortChanged());
    ref.listen(diamondSortProvider, (prev, next) => _onFilterOrSortChanged());
    _fetchFirstPage();
    return const DiamondListState(
      items: [],
      currentPage: 0,
      hasMore: true,
      isLoadingMore: false,
    );
  }

  Future<void> _onFilterOrSortChanged() async {
    // Cancel any in-flight request
    // Reset to page 1
    // Fetch new results
  }

  Future<void> loadNextPage() async { /* ... */ }
  Future<void> refresh() async {
    state = const AsyncLoading();
    // Reset and re-fetch
  }
}
```

---

## 9. Scroll Performance

### 9.1 ScrollController Listener Cleanup

Attach listener in `initState`, remove in `dispose`. Never create a new `ScrollController` in the build method.

### 9.2 addAutomaticKeepAlives

Set `addAutomaticKeepAlives: true` on `SliverChildBuilderDelegate` so that items that temporarily leave the viewport (e.g., during a view-mode toggle) are preserved:

```dart
SliverList(
  delegate: SliverChildBuilderDelegate(
    (ctx, index) => DiamondListCard(key: ValueKey(items[index].id), diamond: items[index]),
    childCount: items.length,
    addAutomaticKeepAlives: true,
  ),
)
```

### 9.3 Viewport Recycling

Flutter's `SliverList` / `SliverGrid` already recycle children that leave the viewport. Ensure no `AutomaticKeepAliveClientMixin` is used in diamond cards (they should be ephemeral).

---

## 10. Build Method Size Limits

| Widget | Max build method lines |
|--------|-----------------------|
| `DiamondListingsScreen` | 300 lines |
| `DiamondGridCard` | 80 lines |
| `DiamondListCard` | 100 lines |
| `FilterChipsRow` | 50 lines |
| `SortBar` | 60 lines |
| `ResultsCountLabel` | 30 lines |
| `BottomShimmerLoader` | 20 lines |

Extract sub-widgets into private methods or separate files when limits are exceeded.

---

## 11. Metrics to Measure

### 11.1 Baseline Thresholds

| Metric | Target | Measurement Tool |
|--------|--------|-----------------|
| Time to first frame (TTF) | < 300ms | Flutter DevTools Timeline |
| Scroll jank (frames > 16ms) | < 1% of frames | `ProfileMode`, DevTools |
| Memory (100+ items loaded) | < 80MB | DevTools Memory view |
| Image decode time (grid) | < 50ms per image | `CacheManager` logging |
| Image decode time (list) | < 40ms per image | `CacheManager` logging |
| Provider rebuild count (sort toggle) | ≤ 3 rebuilds | `ProviderObserver` |
| Provider rebuild count (filter toggle) | ≤ 5 rebuilds | `ProviderObserver` |

### 11.2 ProviderObserver for Rebuild Tracking

```dart
class RebuildTracker extends ProviderObserver {
  int totalRebuilds = 0;
  final Map<String, int> rebuildCounts = {};

  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue, Object? newValue, ProviderContainer container) {
    totalRebuilds++;
    rebuildCounts[provider.name ?? provider.runtimeType.toString()] =
        (rebuildCounts[provider.name ?? provider.runtimeType.toString()] ?? 0) + 1;
  }
}
```

---

## 12. Network Performance

### 12.1 Request Deduplication

When a new filter or sort is applied while a previous request is still in flight, cancel the previous request using Dio's `CancelToken`.

```dart
class DiamondListNotifier extends AsyncNotifier<DiamondListState> {
  CancelToken? _cancelToken;

  Future<void> _fetchFirstPage() async {
    _cancelToken?.cancel('New request initiated');
    _cancelToken = CancelToken();

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '/diamonds',
        queryParameters: _buildQueryParams(page: 1),
        cancelToken: _cancelToken,
      );
      // Handle response...
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return; // silently ignore
      // Handle error...
    }
  }
}
```

### 12.2 Timeout

Set a **30-second timeout** for the list endpoint via Dio instance configuration:

```dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 10),
  ));
  return dio;
});
```

### 12.3 Retry with Exponential Backoff

Wrap the list API call with `RetryInterceptor` from `dio_smart_retry` or implement manually:

```dart
import 'package:dio_smart_retry/dio_smart_retry.dart';

dio.interceptors.add(RetryInterceptor(
  dio: dio,
  retries: 2,
  retryDelays: const [
    Duration(seconds: 1),
    Duration(seconds: 3),
  ],
  retryableExtraStatuses: {408, 500, 502, 503, 504},
));
```

### 12.4 Response Caching (Hive Disk Cache)

For offline support and faster re-visits, cache paginated diamond list responses using Hive:

```dart
// In-memory + disk cache layer
class DiamondListCache {
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox('diamond_list_cache');
  }

  String _cacheKey(DiamondFilterState filters, DiamondSort sort, int page) {
    return '${filters.hashCode}_${sort.apiValue}_$page';
  }

  Future<void> cachePage(DiamondFilterState filters, DiamondSort sort, int page, List<DiamondSummary> items) async {
    final key = _cacheKey(filters, sort, page);
    await _box.put(key, items.map((e) => e.toJson()).toList());
  }

  List<DiamondSummary>? getCachedPage(DiamondFilterState filters, DiamondSort sort, int page) {
    final key = _cacheKey(filters, sort, page);
    final data = _box.get(key) as List<dynamic>?;
    if (data == null) return null;
    return data.cast<Map<String, dynamic>>().map((json) => DiamondSummary.fromJson(json)).toList();
  }
}
```

### 12.5 Network Request Lifecycle Diagram

```
Filter/Sort Change
       │
       ▼
  Cancel previous CancelToken (if any)
       │
       ▼
  Reset page to 1
       │
       ▼
  Check Hive cache for page 1
       │
       ├── HIT ──► Use cached data, fetch next pages in background
       │
       └── MISS ──► Fetch from API (30s timeout, 2 retries)
                      │
                      ▼
                 Success? ──► Merge into state, cache to Hive
                      │
                   Failure? ──► Show error (keep previous data if available)
```

---

## 13. File Structure

Add the following files for the listings feature:

```
lib/features/diamonds/
├── application/
│   ├── diamond_search_provider.dart       (existing)
│   └── diamond_list_providers.dart        (NEW — providers from §8)
├── domain/
│   ├── models/
│   │   ├── diamond_filter_state.dart       (existing)
│   │   └── diamond_summary.dart            (NEW — response DTO)
├── data/
│   ├── diamond_list_repository.dart        (NEW — API calls)
│   └── diamond_list_cache.dart             (NEW — Hive cache)
└── presentation/
    ├── screens/
    │   ├── diamond_search_screen.dart       (existing)
    │   └── diamond_listings_screen.dart     (NEW — results screen)
    └── widgets/
        ├── filter_chip.dart                 (existing)
        ├── diamond_grid_card.dart           (NEW)
        ├── diamond_list_card.dart           (NEW)
        ├── filter_chips_row.dart            (NEW)
        ├── sort_bar.dart                    (NEW)
        ├── results_count_label.dart         (NEW)
        ├── bottom_shimmer_loader.dart       (NEW)
        └── diamond_svg_placeholder.dart     (NEW)
```

---

## 14. Dependency Checklist

Add to `pubspec.yaml` before implementation:

```yaml
dependencies:
  cached_network_image: ^3.4.1
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  dio_smart_retry: ^6.0.0   # optional, for retry interceptor
```

---

## 15. Acceptance Criteria

| # | Criterion | Pass/Fail |
|---|-----------|-----------|
| 1 | `ListView.builder` / `GridView.builder` used exclusively — no eager children | |
| 2 | `CachedNetworkImage` used for all diamond images — no bare `Image.network` | |
| 3 | All `Consumer` widgets use `.select()` — no giant state watches | |
| 4 | `ScrollController` created in initState, disposed in dispose | |
| 5 | Pagination guard prevents duplicate concurrent requests | |
| 6 | Sort/ViewMode changes rebuild only affected sections (validated via `ProviderObserver`) | |
| 7 | Shimmer skeleton shown during initial load; previous data kept during re-fetch | |
| 8 | Memory stays below 80MB with 100+ items loaded | |
| 9 | Scroll jank < 1% of frames in profile mode | |
| 10 | Network timeout 30s, retry 2x with exponential backoff | |

---

*End of Performance Specification — implement against these thresholds exactly.*
