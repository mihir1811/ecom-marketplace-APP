import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../data/repositories/jewelry_repository_impl.dart';
import '../domain/models/jewelry.dart';
import '../domain/models/jewelry_filter_state.dart';
import '../domain/repositories/jewelry_repository.dart';

/// One house's pieces: shop slug, optional parent category slug and sort.
typedef JewelryHouseQuery = ({
  String shop,
  String? category,
  JewelrySortOption? sort,
});

/// A house's live pieces from `GET /marketplace/listings?shop=`, paged.
final jewelryHousePiecesProvider = NotifierProvider.autoDispose
    .family<
      JewelryHousePiecesNotifier,
      PaginatedListState<Jewelry>,
      JewelryHouseQuery
    >(JewelryHousePiecesNotifier.new);

class JewelryHousePiecesNotifier
    extends
        AutoDisposeFamilyNotifier<
          PaginatedListState<Jewelry>,
          JewelryHouseQuery
        > {
  CancelToken? _cancel;
  int _page = 1;
  int _epoch = 0;

  @override
  PaginatedListState<Jewelry> build(JewelryHouseQuery query) {
    ref.onDispose(() {
      _epoch++;
      _cancel?.cancel();
    });
    Future.microtask(_loadFirst);
    return const PaginatedListState(isInitialLoading: true);
  }

  Future<void> refresh() => _loadFirst(keepItems: true);

  Future<void> _loadFirst({bool keepItems = false}) async {
    final epoch = ++_epoch;
    _cancel?.cancel();
    _page = 1;
    state = keepItems
        ? state.copyWith(isRefreshing: true)
        : const PaginatedListState(isInitialLoading: true);
    final result = await _fetch(1);
    if (epoch != _epoch) return;
    state = switch (result) {
      Success(value: final r) => PaginatedListState(
        items: r.items,
        hasMore: r.hasMore && r.items.isNotEmpty,
        totalCount: r.totalCount,
      ),
      ResultFailure(failure: final f) => PaginatedListState(
        errorMessage: f.message,
      ),
    };
  }

  Future<void> loadNextPage() async {
    final current = state;
    if (!current.hasMore ||
        current.isLoadingMore ||
        current.isInitialLoading ||
        current.isRefreshing) {
      return;
    }
    final epoch = _epoch;
    state = current.copyWith(isLoadingMore: true);
    final result = await _fetch(_page + 1);
    if (epoch != _epoch) return;
    switch (result) {
      case Success(value: final r):
        _page++;
        state = current.copyWith(
          items: [...current.items, ...r.items],
          hasMore: r.hasMore && r.items.isNotEmpty,
          totalCount: r.totalCount,
          isLoadingMore: false,
        );
      case ResultFailure(failure: final f):
        state = current.copyWith(isLoadingMore: false, errorMessage: f.message);
    }
  }

  Future<Result<JewelryListResponse, Failure>> _fetch(int page) {
    _cancel = CancelToken();
    return ref
        .read(jewelryRepositoryProvider)
        .getJewelry(
          filters: JewelryFilterState(shop: arg.shop, category: arg.category),
          page: page,
          pageSize: JewelryPageSize.defaultSize,
          sort: arg.sort,
          cancelToken: _cancel,
        );
  }
}
