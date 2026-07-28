import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/failure.dart';
import '../error/result.dart';
import 'paginated_list_state.dart';

/// Lightweight page payload consumed by the shared paginated notifier.
class PaginatedPage<T> {
  const PaginatedPage({
    required this.items,
    required this.hasMore,
    required this.totalCount,
  });

  final List<T> items;
  final bool hasMore;
  final int totalCount;
}

/// Shared pagination workflow for catalog providers.
abstract class PaginatedAsyncNotifier<T>
    extends AsyncNotifier<PaginatedListState<T>> {
  int _currentPage = 1;
  bool _listenersRegistered = false;

  /// Providers that should trigger a fresh first-page load.
  Iterable<ProviderListenable<Object?>> get reloadTriggers => const [];

  @override
  PaginatedListState<T> build() {
    _currentPage = 1;
    _registerReloadListeners();
    loadFirstPage();
    return PaginatedListState<T>(isInitialLoading: true);
  }

  Future<Result<PaginatedPage<T>, Failure>> loadPage(int page);

  Future<void> loadFirstPage() async {
    _currentPage = 1;
    state = AsyncData(PaginatedListState<T>(isInitialLoading: true));
    final result = await loadPage(1);
    _setFirstPage(result);
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.isInitialLoading) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true, errorMessage: null));
    _currentPage++;

    final result = await loadPage(_currentPage);
    switch (result) {
      case Success(value: final response):
        state = AsyncData(
          current.copyWith(
            items: [...current.items, ...response.items],
            hasMore: response.hasMore,
            totalCount: response.totalCount,
            isLoadingMore: false,
            isRefreshing: false,
            isInitialLoading: false,
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
    final current = state.valueOrNull ?? PaginatedListState<T>();
    _currentPage = 1;
    state = AsyncData(current.copyWith(isRefreshing: true, errorMessage: null));
    final result = await loadPage(1);
    _setFirstPage(result);
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(errorMessage: null));
  }

  void _registerReloadListeners() {
    if (_listenersRegistered) return;
    _listenersRegistered = true;
    for (final trigger in reloadTriggers) {
      ref.listen<Object?>(trigger, (_, __) {
        loadFirstPage();
      });
    }
  }

  void _setFirstPage(Result<PaginatedPage<T>, Failure> result) {
    switch (result) {
      case Success(value: final response):
        state = AsyncData(
          PaginatedListState<T>(
            items: response.items,
            hasMore: response.hasMore,
            totalCount: response.totalCount,
            isRefreshing: false,
            isInitialLoading: false,
          ),
        );
      case ResultFailure(failure: final failure):
        state = AsyncData(
          PaginatedListState<T>(
            errorMessage: failure.message,
            isRefreshing: false,
            isInitialLoading: false,
          ),
        );
    }
  }
}
