import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/pagination/paginated_async_notifier.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../../recently_viewed/application/recently_viewed_providers.dart';
import '../data/repositories/rough_diamond_repository_impl.dart';
import '../domain/models/rough_parcel.dart';
import '../domain/repositories/rough_diamond_repository.dart';
import 'rough_filter_provider.dart';

typedef RoughListState = PaginatedListState<RoughParcel>;

/// Parcels on sale for the applied filters; 24 per page, more while
/// `meta.next` is set.
final roughListProvider =
    AsyncNotifierProvider<RoughListNotifier, RoughListState>(
      RoughListNotifier.new,
    );

class RoughListNotifier extends PaginatedAsyncNotifier<RoughParcel> {
  CancelToken? _cancelToken;

  @override
  Iterable<ProviderListenable<Object?>> get reloadTriggers => [
    roughFilterProvider,
    roughSortProvider,
  ];

  @override
  void onResetPagination() {
    final token = _cancelToken;
    if (token != null && !token.isCancelled) token.cancel('rough-list-reset');
    _cancelToken = CancelToken();
  }

  @override
  void onBeforePageLoad({required int page, required bool isFirstPage}) {
    if (isFirstPage) ensureRecentlyViewedIdsLoaded(ref);
  }

  @override
  Future<Result<PaginatedPage<RoughParcel>, Failure>> loadPage(int page) async {
    _cancelToken ??= CancelToken();
    final result = await ref
        .read(roughDiamondRepositoryProvider)
        .search(
          filters: ref.read(roughFilterProvider),
          sort: ref.read(roughSortProvider),
          page: page,
          pageSize: RoughPageSize.defaultSize,
          cancelToken: _cancelToken,
        );
    return switch (result) {
      Success(value: final r) => Success(
        PaginatedPage<RoughParcel>(
          items: r.parcels,
          hasMore: r.hasMore,
          totalCount: r.totalCount,
        ),
      ),
      ResultFailure(failure: final f) => ResultFailure(f),
    };
  }
}
