import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/watch_repository_impl.dart';
import '../domain/models/watch.dart';
import '../domain/models/watch_filter_state.dart';
import '../domain/repositories/watch_repository.dart';
import 'brand_watch_filter_provider.dart';
import '../../recently_viewed/application/recently_viewed_providers.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

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

/// Brand-scoped watch list — same API filters as main catalog, brand locked.
class BrandWatchListNotifier extends AsyncNotifier<BrandWatchListState>
    with DisposeTolerantAsyncNotifier<BrandWatchListState> {
  int _currentPage = 1;
  String _brandName = '';

  @override
  BrandWatchListState build() {
    _currentPage = 1;
    ref.listen(brandWatchFilterProvider, (_, __) {
      _loadFirstPage();
    });
    ref.listen(brandWatchSortProvider, (_, __) {
      _loadFirstPage();
    });
    return const BrandWatchListState(isInitialLoading: true);
  }

  void setBrandName(String brandName) {
    if (_brandName == brandName) return;
    final switchingBrand = _brandName.isNotEmpty;
    _brandName = brandName;
    if (switchingBrand) {
      ref.read(brandWatchFilterProvider.notifier).reset();
      ref.read(brandWatchSortProvider.notifier).state =
          WatchSortOption.priceHighToLow;
    }
    _loadFirstPage();
  }

  WatchFilterState _filtersForApi() {
    final filters = ref.read(brandWatchFilterProvider);
    return filters.copyWith(brands: {_brandName});
  }

  Future<void> _loadFirstPage() async {
    if (_brandName.isEmpty) return;
    ensureRecentlyViewedIdsLoaded(ref);
    _currentPage = 1;
    final repo = ref.read(watchRepositoryProvider);
    final sort = ref.read(brandWatchSortProvider);

    state = const AsyncData(BrandWatchListState(isInitialLoading: true));

    final result = await repo.getWatches(
      filters: _filtersForApi(),
      page: 1,
      pageSize: WatchPageSize.defaultSize,
      sort: sort,
    );
    if (!ref.mounted) return;

    switch (result) {
      case Success(value: final response):
        state = AsyncData(
          BrandWatchListState(
            watches: response.watches,
            hasMore: response.hasMore,
            totalCount: response.totalCount,
          ),
        );
      case ResultFailure(failure: final failure):
        state = AsyncData(
          BrandWatchListState(
            errorMessage: failure.message,
            isInitialLoading: false,
          ),
        );
    }
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    _currentPage++;

    final repo = ref.read(watchRepositoryProvider);
    final sort = ref.read(brandWatchSortProvider);

    final result = await repo.getWatches(
      filters: _filtersForApi(),
      page: _currentPage,
      pageSize: WatchPageSize.defaultSize,
      sort: sort,
    );
    if (!ref.mounted) return;

    switch (result) {
      case Success(value: final response):
        state = AsyncData(
          BrandWatchListState(
            watches: [...current.watches, ...response.watches],
            hasMore: response.hasMore,
            totalCount: response.totalCount,
          ),
        );
      case ResultFailure(failure: final failure):
        _currentPage--;
        state = AsyncData(
          current.copyWith(isLoadingMore: false, errorMessage: failure.message),
        );
    }
  }

  Future<void> refresh() async {
    await _loadFirstPage();
    if (!ref.mounted) return;
  }
}

final brandWatchListProvider =
    AsyncNotifierProvider<BrandWatchListNotifier, BrandWatchListState>(
      BrandWatchListNotifier.new,
    );
