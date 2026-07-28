/// Generic state model for paginated catalog/list screens.
class PaginatedListState<T> {
  const PaginatedListState({
    this.items = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.totalCount = 0,
  });

  final List<T> items;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final int totalCount;

  PaginatedListState<T> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isInitialLoading,
    bool? isRefreshing,
    String? errorMessage,
    int? totalCount,
  }) {
    return PaginatedListState<T>(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}
