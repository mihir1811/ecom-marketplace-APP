import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/pagination/paginated_async_notifier.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../../../core/error/result.dart';
import '../data/repositories/bullions_repository_impl.dart';
import '../domain/models/billion.dart';
import 'bullions_filter_provider.dart';

typedef BullionsListState = PaginatedListState<Bullion>;

extension BullionsListStateX on BullionsListState {
  List<Bullion> get bullions => items;
}

final bullionsListProvider =
    AsyncNotifierProvider<BullionsListNotifier, BullionsListState>(
  BullionsListNotifier.new,
);

class BullionsListNotifier extends PaginatedAsyncNotifier<Bullion> {
  @override
  Iterable<ProviderListenable<Object?>> get reloadTriggers => [
    bullionsFilterProvider,
  ];

  @override
  Future<Result<PaginatedPage<Bullion>, Failure>> loadPage(int page) async {
    final filter = ref.read(bullionsFilterProvider);
    final repo = ref.read(bullionsRepositoryProvider);
    final result = await repo.searchBullions(
      filters: filter,
      page: page,
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

