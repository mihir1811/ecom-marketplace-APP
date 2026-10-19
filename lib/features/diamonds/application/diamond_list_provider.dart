import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/pagination/paginated_async_notifier.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../data/repositories/diamond_repository_impl.dart';
import '../domain/models/diamond.dart';
import '../domain/models/diamond_catalog_type.dart';
import '../domain/models/sorting_criteria.dart';
import '../domain/repositories/diamond_repository.dart';
import 'diamond_results_handoff.dart';
import 'diamond_search_provider.dart';
import '../../recently_viewed/application/recently_viewed_providers.dart';

enum ViewMode { grid, list }

/// Holds the active multi-criteria sorting configuration.
/// Empty list means no sorting applied (default order).
final diamondSortingProvider = StateProvider<List<SortingCriteria>>(
  (ref) => [],
);

typedef DiamondListState = PaginatedListState<Diamond>;

extension DiamondListStateX on DiamondListState {
  List<Diamond> get diamonds => items;
}

final diamondViewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.grid);

/// Results list. Invalidated on every SHOW DIAMONDS so filters always refetch.
final diamondListProvider =
    AsyncNotifierProvider<DiamondListNotifier, DiamondListState>(
      DiamondListNotifier.new,
    );

/// Paged diamond results — uses backend `page` / `limit` + `meta.next`.
class DiamondListNotifier extends PaginatedAsyncNotifier<Diamond> {
  CancelToken? _cancelToken;

  @override
  Iterable<ProviderListenable<Object?>> get reloadTriggers => const [];

  @override
  void onResetPagination() {
    final token = _cancelToken;
    if (token != null && !token.isCancelled) {
      token.cancel('diamond-list-reset');
    }
    _cancelToken = CancelToken();
  }

  @override
  void onBeforePageLoad({required int page, required bool isFirstPage}) {
    if (isFirstPage) {
      ensureRecentlyViewedIdsLoaded(ref);
    }
  }

  @override
  Future<Result<PaginatedPage<Diamond>, Failure>> loadPage(int page) async {
    _cancelToken ??= CancelToken();
    final filters = ref.read(diamondSearchProvider);
    final sorting = ref.read(diamondSortingProvider);
    final catalog = ref.read(diamondCatalogTypeProvider);
    if (page == 1) {
      final prefetched = ref
          .read(diamondResultsHandoffProvider)
          ?.takeFirstPage(catalog, filters);
      if (prefetched != null) {
        return Success(
          PaginatedPage<Diamond>(
            items: prefetched.diamonds,
            hasMore: prefetched.hasMore,
            totalCount: prefetched.totalCount,
          ),
        );
      }
    }
    final repo = ref.read(diamondRepositoryProvider);
    final result = await repo.getDiamonds(
      filters: filters,
      catalog: catalog,
      page: page,
      pageSize: DiamondPageSize.defaultSize,
      sorting: sorting,
      cancelToken: _cancelToken,
    );
    return switch (result) {
      Success(value: final response) => Success(
        PaginatedPage<Diamond>(
          items: response.diamonds,
          hasMore: response.hasMore,
          totalCount: response.totalCount,
        ),
      ),
      ResultFailure(failure: final failure) => ResultFailure(failure),
    };
  }

  Future<void> applyFiltersAndSort() async {
    await loadFirstPage();
  }

  /// Clears search filters and reloads page 1.
  Future<void> resetFiltersAndReload() async {
    ref.read(diamondSearchProvider.notifier).reset();
    ref.read(diamondSortingProvider.notifier).state = const [];
    await loadFirstPage();
  }
}
