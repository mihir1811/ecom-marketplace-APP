import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/watch_repository_impl.dart';
import '../domain/models/watch.dart';
import 'watch_filter_provider.dart';

class WatchListState {
  const WatchListState({
    this.watches = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.totalCount = 0,
  });

  final List<Watch> watches;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final int totalCount;

  WatchListState copyWith({
    List<Watch>? watches,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isInitialLoading,
    bool? isRefreshing,
    String? errorMessage,
    int? totalCount,
  }) {
    return WatchListState(
      watches: watches ?? this.watches,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

final watchListProvider =
    AsyncNotifierProvider<WatchListNotifier, WatchListState>(
  WatchListNotifier.new,
);

class WatchListNotifier extends AsyncNotifier<WatchListState> {
  int _currentPage = 1;

  @override
  WatchListState build() {
    _currentPage = 1;
    ref.listen(watchFilterProvider, (_, __) {
      _loadFirstPage();
    });
    ref.listen(watchSortProvider, (_, __) {
      _loadFirstPage();
    });
    _loadFirstPage();
    return const WatchListState(isInitialLoading: true);
  }

  Future<void> _loadFirstPage() async {
    _currentPage = 1;
    final filters = ref.read(watchFilterProvider);
    final sort = ref.read(watchSortProvider);
    final repo = ref.read(watchRepositoryProvider);

    state = const AsyncData(WatchListState(isInitialLoading: true));

    final result = await repo.getWatches(
      filters: filters,
      page: 1,
      sort: sort,
    );

    switch (result) {
      case Success(value: final response):
        state = AsyncData(WatchListState(
          watches: response.watches,
          hasMore: response.hasMore,
          totalCount: response.totalCount,
        ));
      case ResultFailure(failure: final failure):
        state = AsyncData(WatchListState(
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

    final filters = ref.read(watchFilterProvider);
    final sort = ref.read(watchSortProvider);
    final repo = ref.read(watchRepositoryProvider);

    final result = await repo.getWatches(
      filters: filters,
      page: _currentPage,
      sort: sort,
    );

    switch (result) {
      case Success(value: final response):
        state = AsyncData(WatchListState(
          watches: [...current.watches, ...response.watches],
          hasMore: response.hasMore,
          totalCount: response.totalCount,
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

  void clearError() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(errorMessage: null));
    }
  }
}
