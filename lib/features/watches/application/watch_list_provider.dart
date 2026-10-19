import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/pagination/paginated_async_notifier.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../../../core/pagination/prefetched_first_page.dart';
import '../../../core/error/result.dart';
import '../data/repositories/watch_repository_impl.dart';
import '../domain/models/watch.dart';
import '../domain/models/watch_filter_state.dart';
import '../domain/repositories/watch_repository.dart';
import 'watch_filter_provider.dart';
import '../../recently_viewed/application/recently_viewed_providers.dart';

typedef WatchListState = PaginatedListState<Watch>;

extension WatchListStateX on WatchListState {
  List<Watch> get watches => items;
}

/// First page fetched outside the screen (e.g. Gem Agent), served once.
final watchPrefetchProvider =
    StateProvider<PrefetchedFirstPage<WatchFilterState, Watch>?>(
      (ref) => null,
    );

/// Applies [prefetched]'s filters; the list reloads and shows its page.
void presentPrefetchedWatches(
  Ref ref,
  PrefetchedFirstPage<WatchFilterState, Watch> prefetched,
) {
  ref.read(watchPrefetchProvider.notifier).state = prefetched;
  ref.read(watchFilterProvider.notifier).replaceWith(prefetched.filters);
}

final watchListProvider =
    AsyncNotifierProvider<WatchListNotifier, WatchListState>(
  WatchListNotifier.new,
);

class WatchListNotifier extends PaginatedAsyncNotifier<Watch> {
  CancelToken? _cancelToken;

  @override
  Iterable<ProviderListenable<Object?>> get reloadTriggers => [
    watchFilterProvider,
    watchSortProvider,
  ];

  @override
  void onResetPagination() {
    final token = _cancelToken;
    if (token != null && !token.isCancelled) {
      token.cancel('watch-list-reset');
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
  Future<Result<PaginatedPage<Watch>, Failure>> loadPage(int page) async {
    _cancelToken ??= CancelToken();
    final filters = ref.read(watchFilterProvider);
    final sort = ref.read(watchSortProvider);
    if (page == 1) {
      final prefetched = ref.read(watchPrefetchProvider)?.take(filters);
      if (prefetched != null) return Success(prefetched);
    }
    final repo = ref.read(watchRepositoryProvider);
    final result = await repo.getWatches(
      filters: filters,
      page: page,
      pageSize: WatchPageSize.defaultSize,
      sort: sort,
      cancelToken: _cancelToken,
    );
    return switch (result) {
      Success(value: final response) => Success(
          PaginatedPage<Watch>(
            items: response.watches,
            hasMore: response.hasMore,
            totalCount: response.totalCount,
          ),
        ),
      ResultFailure(failure: final failure) => ResultFailure(failure),
    };
  }
}
