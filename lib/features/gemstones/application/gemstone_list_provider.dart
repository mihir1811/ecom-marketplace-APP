import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/pagination/paginated_async_notifier.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../data/repositories/gemstone_repository_impl.dart';
import '../domain/models/gemstone.dart';
import '../domain/models/gemstone_sort_option.dart';
import '../domain/repositories/gemstone_repository.dart';
import 'gemstone_search_provider.dart';
import '../../recently_viewed/application/recently_viewed_providers.dart';

enum GemstoneViewMode { grid, list }

typedef GemstoneListState = PaginatedListState<Gemstone>;

extension GemstoneListStateX on GemstoneListState {
  List<Gemstone> get gemstones => items;
}

final gemstoneViewModeProvider =
    StateProvider<GemstoneViewMode>((ref) => GemstoneViewMode.grid);

final gemstoneSortProvider =
    StateProvider<GemstoneSortOption>((ref) => GemstoneSortOption.newest);

/// Results list. Uses backend `page` / `limit` + `meta.next` for infinite scroll.
final gemstoneListProvider =
    AsyncNotifierProvider<GemstoneListNotifier, GemstoneListState>(
  GemstoneListNotifier.new,
);

class GemstoneListNotifier extends PaginatedAsyncNotifier<Gemstone> {
  CancelToken? _cancelToken;

  @override
  Iterable<ProviderListenable<Object?>> get reloadTriggers => [
        gemstoneSortProvider,
      ];

  @override
  void onResetPagination() {
    final token = _cancelToken;
    if (token != null && !token.isCancelled) {
      token.cancel('gemstone-list-reset');
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
  Future<Result<PaginatedPage<Gemstone>, Failure>> loadPage(int page) async {
    _cancelToken ??= CancelToken();
    final filters = ref.read(gemstoneSearchProvider);
    final sort = ref.read(gemstoneSortProvider);
    final repo = ref.read(gemstoneRepositoryProvider);
    final result = await repo.getGemstones(
      filters: filters,
      page: page,
      pageSize: GemstonePageSize.defaultSize,
      sortBy: sort.apiValue,
      cancelToken: _cancelToken,
    );
    return switch (result) {
      Success(value: final response) => Success(
          PaginatedPage<Gemstone>(
            items: response.gemstones,
            hasMore: response.hasMore,
            totalCount: response.totalCount,
          ),
        ),
      ResultFailure(failure: final failure) => ResultFailure(failure),
    };
  }

  Future<void> applyFiltersAndReload() async {
    await loadFirstPage();
  }
}
