import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/pagination/paginated_async_notifier.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../../../core/error/result.dart';
import '../data/repositories/watch_repository_impl.dart';
import '../domain/models/watch.dart';
import 'watch_filter_provider.dart';

typedef WatchListState = PaginatedListState<Watch>;

extension WatchListStateX on WatchListState {
  List<Watch> get watches => items;
}

final watchListProvider =
    AsyncNotifierProvider<WatchListNotifier, WatchListState>(
  WatchListNotifier.new,
);

class WatchListNotifier extends PaginatedAsyncNotifier<Watch> {
  @override
  Iterable<ProviderListenable<Object?>> get reloadTriggers => [
    watchFilterProvider,
    watchSortProvider,
  ];

  @override
  Future<Result<PaginatedPage<Watch>, Failure>> loadPage(int page) async {
    final filters = ref.read(watchFilterProvider);
    final sort = ref.read(watchSortProvider);
    final repo = ref.read(watchRepositoryProvider);
    final result = await repo.getWatches(
      filters: filters,
      page: page,
      sort: sort,
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
