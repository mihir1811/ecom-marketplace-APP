import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/pagination/paginated_async_notifier.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../../../core/pagination/prefetched_first_page.dart';
import '../../../core/error/result.dart';
import '../data/repositories/bullions_repository_impl.dart';
import '../domain/models/billion.dart';
import '../domain/models/bullions_filter_state.dart';
import '../domain/repositories/bullions_repository.dart';
import 'bullions_filter_provider.dart';
import '../../recently_viewed/application/recently_viewed_providers.dart';

typedef BullionsListState = PaginatedListState<Bullion>;

extension BullionsListStateX on BullionsListState {
  List<Bullion> get bullions => items;
}

/// First page fetched outside the screen (e.g. Gem Agent), served once.
final bullionsPrefetchProvider =
    StateProvider<PrefetchedFirstPage<BullionsFilterState, Bullion>?>(
      (ref) => null,
    );

/// Applies [prefetched]'s filters; the list reloads and shows its page.
void presentPrefetchedBullions(
  Ref ref,
  PrefetchedFirstPage<BullionsFilterState, Bullion> prefetched,
) {
  ref.read(bullionsPrefetchProvider.notifier).state = prefetched;
  ref.read(bullionsFilterProvider.notifier).replaceWith(prefetched.filters);
}

final bullionsListProvider =
    AsyncNotifierProvider<BullionsListNotifier, BullionsListState>(
  BullionsListNotifier.new,
);

class BullionsListNotifier extends PaginatedAsyncNotifier<Bullion> {
  CancelToken? _cancelToken;

  @override
  Iterable<ProviderListenable<Object?>> get reloadTriggers => [
        bullionsFilterProvider,
        bullionsSortProvider,
      ];

  @override
  void onResetPagination() {
    final token = _cancelToken;
    if (token != null && !token.isCancelled) {
      token.cancel('bullions-list-reset');
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
  Future<Result<PaginatedPage<Bullion>, Failure>> loadPage(int page) async {
    _cancelToken ??= CancelToken();
    final filter = ref.read(bullionsFilterProvider);
    final sort = ref.read(bullionsSortProvider);
    if (page == 1) {
      final prefetched = ref.read(bullionsPrefetchProvider)?.take(filter);
      if (prefetched != null) return Success(prefetched);
    }
    final repo = ref.read(bullionsRepositoryProvider);
    final result = await repo.searchBullions(
      filters: filter,
      page: page,
      pageSize: BullionPageSize.defaultSize,
      sort: sort,
      cancelToken: _cancelToken,
    );
    return switch (result) {
      Success(value: final response) => Success(
          PaginatedPage<Bullion>(
            items: response.bullions,
            hasMore: response.hasMore,
            totalCount: response.totalCount,
          ),
        ),
      ResultFailure(failure: final failure) => ResultFailure(failure),
    };
  }
}
