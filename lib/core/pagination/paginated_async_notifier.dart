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
///
/// Loads one page at a time, appends on scroll, and discards stale responses
/// when a newer first-page/refresh request supersedes an in-flight fetch.
abstract class PaginatedAsyncNotifier<T>
    extends AsyncNotifier<PaginatedListState<T>> {
  int _currentPage = 1;
  int _epoch = 0;
  Future<void>? _inFlightNextPage;

  /// Providers that should trigger a fresh first-page load.
  Iterable<ProviderListenable<Object?>> get reloadTriggers => const [];

  /// Called before a first-page load so subclasses can cancel network work.
  void onResetPagination() {}

  /// Called before each page fetch (including page 1).
  void onBeforePageLoad({required int page, required bool isFirstPage}) {}

  @override
  PaginatedListState<T> build() {
    for (final trigger in reloadTriggers) {
      ref.watch(trigger);
    }
    _currentPage = 1;
    _epoch = 0;
    _inFlightNextPage = null;
    ref.onDispose(() {
      _epoch++;
      onResetPagination();
    });
    loadFirstPage();
    return PaginatedListState<T>(isInitialLoading: true);
  }

  Future<Result<PaginatedPage<T>, Failure>> loadPage(int page);

  Future<void> loadFirstPage() async {
    final epoch = ++_epoch;
    _currentPage = 1;
    _inFlightNextPage = null;
    onResetPagination();
    onBeforePageLoad(page: 1, isFirstPage: true);

    state = AsyncData(PaginatedListState<T>(isInitialLoading: true));
    final result = await loadPage(1);
    if (epoch != _epoch) return;
    _setFirstPage(result);
  }

  Future<void> loadNextPage() {
    final current = state.valueOrNull;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.isInitialLoading ||
        current.isRefreshing) {
      return _inFlightNextPage ?? Future<void>.value();
    }
    if (_inFlightNextPage != null) return _inFlightNextPage!;

    _inFlightNextPage = _loadNextPageBody(current);
    return _inFlightNextPage!;
  }

  Future<void> _loadNextPageBody(PaginatedListState<T> current) async {
    final epoch = _epoch;
    final nextPage = _currentPage + 1;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, errorMessage: null),
    );
    onBeforePageLoad(page: nextPage, isFirstPage: false);

    try {
      final result = await loadPage(nextPage);
      if (epoch != _epoch) return;

      switch (result) {
        case Success(value: final response):
          _currentPage = nextPage;
          state = AsyncData(
            current.copyWith(
              items: [...current.items, ...response.items],
              hasMore: response.hasMore && response.items.isNotEmpty,
              totalCount: response.totalCount,
              isLoadingMore: false,
              isRefreshing: false,
              isInitialLoading: false,
            ),
          );
        case ResultFailure(failure: final failure):
          if (_isCancelledFailure(failure)) {
            state = AsyncData(current.copyWith(isLoadingMore: false));
            return;
          }
          state = AsyncData(
            current.copyWith(
              isLoadingMore: false,
              errorMessage: failure.message,
            ),
          );
      }
    } finally {
      _inFlightNextPage = null;
    }
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? PaginatedListState<T>();
    final epoch = ++_epoch;
    _currentPage = 1;
    _inFlightNextPage = null;
    onResetPagination();
    onBeforePageLoad(page: 1, isFirstPage: true);

    state = AsyncData(
      current.copyWith(isRefreshing: true, errorMessage: null),
    );
    final result = await loadPage(1);
    if (epoch != _epoch) return;
    _setFirstPage(result);
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(errorMessage: null));
  }

  void _setFirstPage(Result<PaginatedPage<T>, Failure> result) {
    switch (result) {
      case Success(value: final response):
        state = AsyncData(
          PaginatedListState<T>(
            items: response.items,
            hasMore: response.hasMore && response.items.isNotEmpty,
            totalCount: response.totalCount,
            isRefreshing: false,
            isInitialLoading: false,
          ),
        );
      case ResultFailure(failure: final failure):
        if (_isCancelledFailure(failure)) {
          // Keep showing the loading shell; a newer in-flight load owns the UI.
          return;
        }
        state = AsyncData(
          PaginatedListState<T>(
            errorMessage: failure.message,
            isRefreshing: false,
            isInitialLoading: false,
          ),
        );
    }
  }

  bool _isCancelledFailure(Failure failure) {
    return failure is NetworkFailure && failure.isCancelled;
  }
}
