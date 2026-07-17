import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/result.dart';
import '../data/repositories/diamond_repository_impl.dart';
import '../domain/models/diamond.dart';
import 'diamond_search_provider.dart';

enum ViewMode { grid, list }

enum DiamondSortField {
  priceLowHigh,
  priceHighLow,
  caratLowHigh,
  caratHighLow,
  pricePerCaratLowHigh,
  pricePerCaratHighLow,
  discountHighLow,
  popularity,
  newest,
  cutBestWorst,
  colorBestWorst,
  clarityBestWorst,
  shapeAZ,
}

class DiamondListState {
  final List<Diamond> diamonds;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final int totalCount;

  const DiamondListState({
    this.diamonds = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.totalCount = 0,
  });

  DiamondListState copyWith({
    List<Diamond>? diamonds,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isInitialLoading,
    bool? isRefreshing,
    String? errorMessage,
    int? totalCount,
  }) {
    return DiamondListState(
      diamonds: diamonds ?? this.diamonds,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

final diamondViewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.grid);

final diamondPrimarySortProvider = StateProvider<DiamondSortField>((ref) => DiamondSortField.priceHighLow);

final diamondSecondarySortProvider = StateProvider<DiamondSortField>((ref) => DiamondSortField.caratLowHigh);

final diamondListProvider =
    AsyncNotifierProvider<DiamondListNotifier, DiamondListState>(
  DiamondListNotifier.new,
);

class DiamondListNotifier extends AsyncNotifier<DiamondListState> {
  int _currentPage = 1;

  @override
  DiamondListState build() {
    _currentPage = 1;
    _loadFirstPage();
    return const DiamondListState(isInitialLoading: true);
  }

  Future<void> _loadFirstPage() async {
    _currentPage = 1;
    final filters = ref.read(diamondSearchProvider);
    final primarySort = ref.read(diamondPrimarySortProvider);
    final secondarySort = ref.read(diamondSecondarySortProvider);
    final repo = ref.read(diamondRepositoryProvider);

    state = const AsyncData(DiamondListState(isInitialLoading: true));

    final result = await repo.getDiamonds(
      filters: filters,
      page: 1,
      primarySort: primarySort,
      secondarySort: secondarySort,
    );

    switch (result) {
      case Success(value: final response):
        state = AsyncData(DiamondListState(
          diamonds: response.diamonds,
          hasMore: response.hasMore,
          totalCount: response.totalCount,
        ));
      case ResultFailure(failure: final failure):
        state = AsyncData(DiamondListState(
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

    final filters = ref.read(diamondSearchProvider);
    final primarySort = ref.read(diamondPrimarySortProvider);
    final secondarySort = ref.read(diamondSecondarySortProvider);
    final repo = ref.read(diamondRepositoryProvider);

    final result = await repo.getDiamonds(
      filters: filters,
      page: _currentPage,
      primarySort: primarySort,
      secondarySort: secondarySort,
    );

    switch (result) {
      case Success(value: final response):
        final updated = [...current.diamonds, ...response.diamonds];
        state = AsyncData(DiamondListState(
          diamonds: updated,
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
    _currentPage = 1;
    final filters = ref.read(diamondSearchProvider);
    final primarySort = ref.read(diamondPrimarySortProvider);
    final secondarySort = ref.read(diamondSecondarySortProvider);
    final repo = ref.read(diamondRepositoryProvider);

    state = AsyncData(
      (state.valueOrNull ?? const DiamondListState()).copyWith(isRefreshing: true),
    );

    final result = await repo.getDiamonds(
      filters: filters,
      page: 1,
      primarySort: primarySort,
      secondarySort: secondarySort,
    );

    switch (result) {
      case Success(value: final response):
        state = AsyncData(DiamondListState(
          diamonds: response.diamonds,
          hasMore: response.hasMore,
          totalCount: response.totalCount,
        ));
      case ResultFailure(failure: final failure):
        state = AsyncData(
          (state.valueOrNull ?? const DiamondListState()).copyWith(
            isRefreshing: false,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> applyFiltersAndSort() async {
    await _loadFirstPage();
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(errorMessage: null));
    }
  }
}
