import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/watch_repository_impl.dart';
import '../domain/models/brand_watch_state.dart';
import '../domain/models/watch.dart';
import '../domain/models/watch_filter_state.dart';
import '../domain/repositories/watch_repository.dart';
import 'brand_watch_filter_provider.dart';

class BrandWatchListState {
  const BrandWatchListState({
    this.watches = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isInitialLoading = false,
    this.errorMessage,
    this.totalCount = 0,
  });

  final List<Watch> watches;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isInitialLoading;
  final String? errorMessage;
  final int totalCount;

  BrandWatchListState copyWith({
    List<Watch>? watches,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isInitialLoading,
    String? errorMessage,
    int? totalCount,
  }) {
    return BrandWatchListState(
      watches: watches ?? this.watches,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// Notifier for the brand-specific watch list.
/// Uses a StateProvider to track which brand is currently being viewed.
class BrandWatchListNotifier extends AsyncNotifier<BrandWatchListState> {
  int _currentPage = 1;
  String _brandName = '';

  @override
  BrandWatchListState build() {
    _currentPage = 1;
    ref.listen(brandWatchFilterProvider, (_, __) {
      _loadFirstPage();
    });
    return const BrandWatchListState(isInitialLoading: true);
  }

  void setBrandName(String brandName) {
    if (_brandName != brandName) {
      _brandName = brandName;
      _loadFirstPage();
    }
  }

  Future<void> _loadFirstPage() async {
    if (_brandName.isEmpty) return;
    _currentPage = 1;
    final filterState = ref.read(brandWatchFilterProvider);
    final repo = ref.read(watchRepositoryProvider);

    state = const AsyncData(BrandWatchListState(isInitialLoading: true));

    // First, get all watches for this brand using the existing filter system
    final brandFilters = WatchFilterState(brands: {_brandName});
    final result = await repo.getWatches(
      filters: brandFilters,
      page: 1,
      pageSize: WatchPageSize.defaultSize,
      sort: _mapSort(filterState.sort),
    );

    switch (result) {
      case Success(value: final response):
        // Apply brand-specific filters (style and price range)
        final filtered =
            _applyBrandFilters(response.watches, filterState);
        final sorted = _applySort(filtered, filterState.sort);
        state = AsyncData(BrandWatchListState(
          watches: sorted,
          hasMore: response.hasMore,
          totalCount: filtered.length,
        ));
      case ResultFailure(failure: final failure):
        state = AsyncData(BrandWatchListState(
          errorMessage: failure.message,
          isInitialLoading: false,
        ));
    }
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    _currentPage++;

    final filterState = ref.read(brandWatchFilterProvider);
    final repo = ref.read(watchRepositoryProvider);
    final brandFilters = WatchFilterState(brands: {_brandName});

    final result = await repo.getWatches(
      filters: brandFilters,
      page: _currentPage,
      pageSize: WatchPageSize.defaultSize,
      sort: _mapSort(filterState.sort),
    );

    switch (result) {
      case Success(value: final response):
        final filtered =
            _applyBrandFilters(response.watches, filterState);
        final sorted = _applySort(filtered, filterState.sort);
        state = AsyncData(BrandWatchListState(
          watches: [...current.watches, ...sorted],
          hasMore: response.hasMore,
          totalCount: current.totalCount + filtered.length,
        ));
      case ResultFailure(failure: final failure):
        _currentPage--;
        state = AsyncData(current.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        ));
    }
  }

  Future<void> refresh() async {
    await _loadFirstPage();
  }

  List<Watch> _applyBrandFilters(
      List<Watch> watches, BrandWatchFilterState filter) {
    return watches.where((w) {
      // Style filter (maps to category)
      if (filter.selectedStyles.isNotEmpty &&
          !filter.selectedStyles.contains(w.category)) {
        return false;
      }

      // Price range filter
      final minPrice = double.tryParse(filter.priceMin);
      final maxPrice = double.tryParse(filter.priceMax);
      if (minPrice != null && w.price < minPrice) return false;
      if (maxPrice != null && w.price > maxPrice) return false;

      return true;
    }).toList();
  }

  List<Watch> _applySort(List<Watch> watches, BrandWatchSortOption sort) {
    final sorted = List<Watch>.from(watches);
    switch (sort) {
      case BrandWatchSortOption.priceHighToLow:
        sorted.sort((a, b) => b.price.compareTo(a.price));
      case BrandWatchSortOption.priceLowToHigh:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case BrandWatchSortOption.newest:
        sorted.sort((a, b) => b.year.compareTo(a.year));
    }
    return sorted;
  }

  WatchSortOption _mapSort(BrandWatchSortOption sort) {
    return switch (sort) {
      BrandWatchSortOption.priceHighToLow => WatchSortOption.priceHighToLow,
      BrandWatchSortOption.priceLowToHigh => WatchSortOption.priceLowToHigh,
      BrandWatchSortOption.newest => WatchSortOption.newest,
    };
  }
}

final brandWatchListProvider =
    AsyncNotifierProvider<BrandWatchListNotifier, BrandWatchListState>(
  BrandWatchListNotifier.new,
);
