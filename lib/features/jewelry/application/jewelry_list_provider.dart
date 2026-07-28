import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/pagination/paginated_async_notifier.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../../../core/error/result.dart';
import '../data/repositories/jewelry_repository_impl.dart';
import '../domain/models/jewelry.dart';
import 'jewelry_filter_provider.dart';

typedef JewelryListState = PaginatedListState<Jewelry>;

final jewelryListProvider =
    AsyncNotifierProvider<JewelryListNotifier, JewelryListState>(
  JewelryListNotifier.new,
);

class JewelryListNotifier extends PaginatedAsyncNotifier<Jewelry> {
  @override
  Iterable<ProviderListenable<Object?>> get reloadTriggers => [
    jewelryFilterProvider,
    jewelrySortProvider,
  ];

  @override
  Future<Result<PaginatedPage<Jewelry>, Failure>> loadPage(int page) async {
    final filters = ref.read(jewelryFilterProvider);
    final sort = ref.read(jewelrySortProvider);
    final repo = ref.read(jewelryRepositoryProvider);
    final result = await repo.getJewelry(
      filters: filters,
      page: page,
      sort: sort,
    );
    return switch (result) {
      Success(value: final response) => Success(
          PaginatedPage<Jewelry>(
            items: response.items,
            hasMore: response.hasMore,
            totalCount: response.totalCount,
          ),
        ),
      ResultFailure(failure: final failure) => ResultFailure(failure),
    };
  }
}
