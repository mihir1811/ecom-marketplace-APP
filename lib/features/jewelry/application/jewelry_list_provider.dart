import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/jewelry_repository_impl.dart';
import '../domain/models/jewelry.dart';
import 'jewelry_filter_provider.dart';

class JewelryListState {
  const JewelryListState({
    this.items = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isInitialLoading = false,
    this.errorMessage,
    this.totalCount = 0,
  });

  final List<Jewelry> items;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isInitialLoading;
  final String? errorMessage;
  final int totalCount;

  JewelryListState copyWith({
    List<Jewelry>? items,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isInitialLoading,
    String? errorMessage,
    int? totalCount,
  }) {
    return JewelryListState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

final jewelryListProvider =
    AsyncNotifierProvider<JewelryListNotifier, JewelryListState>(
  JewelryListNotifier.new,
);

class JewelryListNotifier extends AsyncNotifier<JewelryListState> {
  int _currentPage = 1;

  @override
  JewelryListState build() {
    _currentPage = 1;
    ref.listen(jewelryFilterProvider, (_, __) {
      _loadFirstPage();
    });
    ref.listen(jewelrySortProvider, (_, __) {
      _loadFirstPage();
    });
    _loadFirstPage();
    return const JewelryListState(isInitialLoading: true);
  }

  Future<void> _loadFirstPage() async {
    _currentPage = 1;
    final filters = ref.read(jewelryFilterProvider);
    final sort = ref.read(jewelrySortProvider);
    final repo = ref.read(jewelryRepositoryProvider);

    state = const AsyncData(JewelryListState(isInitialLoading: true));

    final result = await repo.getJewelry(
      filters: filters,
      page: 1,
      sort: sort,
    );

    switch (result) {
      case Success(value: final response):
        state = AsyncData(JewelryListState(
          items: response.items,
          hasMore: response.hasMore,
          totalCount: response.totalCount,
        ));
      case ResultFailure(failure: final failure):
        state = AsyncData(JewelryListState(
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

    final filters = ref.read(jewelryFilterProvider);
    final sort = ref.read(jewelrySortProvider);
    final repo = ref.read(jewelryRepositoryProvider);

    final result = await repo.getJewelry(
      filters: filters,
      page: _currentPage,
      sort: sort,
    );

    switch (result) {
      case Success(value: final response):
        state = AsyncData(JewelryListState(
          items: [...current.items, ...response.items],
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
}
