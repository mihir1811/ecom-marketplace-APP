import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/bullions_repository_impl.dart';
import '../domain/models/billion.dart';
import 'bullions_filter_provider.dart';

class BullionsListState {
  const BullionsListState({
    this.bullions = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isInitialLoading = false,
    this.errorMessage,
    this.totalCount = 0,
  });

  final List<Bullion> bullions;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isInitialLoading;
  final String? errorMessage;
  final int totalCount;

  BullionsListState copyWith({
    List<Bullion>? bullions,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isInitialLoading,
    String? errorMessage,
    int? totalCount,
  }) {
    return BullionsListState(
      bullions: bullions ?? this.bullions,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

final bullionsListProvider =
    AsyncNotifierProvider<BullionsListNotifier, BullionsListState>(
  BullionsListNotifier.new,
);

class BullionsListNotifier extends AsyncNotifier<BullionsListState> {
  int _currentPage = 1;

  @override
  BullionsListState build() {
    _currentPage = 1;
    ref.listen(bullionsFilterProvider, (_, __) {
      _loadFirstPage();
    });
    _loadFirstPage();
    return const BullionsListState(isInitialLoading: true);
  }

  Future<void> _loadFirstPage() async {
    _currentPage = 1;
    final filter = ref.read(bullionsFilterProvider);
    final repo = ref.read(bullionsRepositoryProvider);

    state = const AsyncData(BullionsListState(isInitialLoading: true));

    final result = await repo.searchBullions(
      filters: filter,
      page: 1,
    );

    switch (result) {
      case Success(value: final response):
        state = AsyncData(
          BullionsListState(
            bullions: response.bullions,
            hasMore: response.hasMore,
            totalCount: response.totalCount,
            isInitialLoading: false,
          ),
        );
      case ResultFailure(failure: final failure):
        state = AsyncData(
          BullionsListState(
            errorMessage: failure.message,
            isInitialLoading: false,
          ),
        );
    }
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    _currentPage++;

    final filter = ref.read(bullionsFilterProvider);
    final repo = ref.read(bullionsRepositoryProvider);

    final result = await repo.searchBullions(
      filters: filter,
      page: _currentPage,
    );

    switch (result) {
      case Success(value: final response):
        state = AsyncData(
          current.copyWith(
            bullions: [...current.bullions, ...response.bullions],
            hasMore: response.hasMore,
            totalCount: response.totalCount,
            isLoadingMore: false,
          ),
        );
      case ResultFailure(failure: final failure):
        _currentPage--;
        state = AsyncData(
          current.copyWith(
            isLoadingMore: false,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> refresh() async {
    await _loadFirstPage();
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(errorMessage: null));
  }
}

