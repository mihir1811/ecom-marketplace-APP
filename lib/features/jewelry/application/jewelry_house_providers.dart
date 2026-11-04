import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../data/repositories/jewelry_repository_impl.dart';
import '../domain/models/jewelry.dart';
import '../domain/models/jewelry_filter_state.dart';
import '../domain/models/marketplace_listing.dart';
import '../domain/repositories/jewelry_repository.dart';
import 'jewellery_categories_provider.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

/// One house's pieces: filters (with the shop slug set) and sort.
typedef JewelryHouseQuery = ({
  JewelryFilterState filters,
  JewelrySortOption? sort,
});

/// A house's live pieces from `GET /marketplace/listings?shop=`, paged.
final jewelryHousePiecesProvider = NotifierProvider.autoDispose
    .family<
      JewelryHousePiecesNotifier,
      PaginatedListState<Jewelry>,
      JewelryHouseQuery
    >(JewelryHousePiecesNotifier.new);

class JewelryHousePiecesNotifier extends Notifier<PaginatedListState<Jewelry>>
    with DisposeTolerantNotifier<PaginatedListState<Jewelry>> {
  JewelryHousePiecesNotifier(this.arg);

  /// The family argument this notifier was created for.
  final JewelryHouseQuery arg;

  JewelryHouseQuery get query => arg;

  CancelToken? _cancel;
  int _page = 1;
  int _epoch = 0;

  @override
  PaginatedListState<Jewelry> build() {
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
    if (!ref.mounted) return;
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
    if (!ref.mounted) return;
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
          filters: arg.filters,
          page: page,
          pageSize: JewelryPageSize.defaultSize,
          sort: arg.sort,
          cancelToken: _cancel,
        );
  }
}

/// One collection a house sells in, with its newest piece's first image.
typedef JewelryHouseCollection = ({
  MarketplaceCategory category,
  String? cover,
});

/// The newest piece of [shop] in [category] (a parent or sub-category slug),
/// or null when it has none. One-item page: never the whole inventory.
Future<Jewelry?> _newestPiece(
  Ref ref,
  String shop,
  String category,
  CancelToken cancel,
) async {
  final result = await ref
      .read(jewelryRepositoryProvider)
      .getJewelry(
        filters: JewelryFilterState(shop: shop, category: category),
        page: 1,
        pageSize: 1,
        sort: JewelrySortOption.newest,
        cancelToken: cancel,
      );
  return switch (result) {
    Success(value: final r) => r.items.firstOrNull,
    ResultFailure(failure: final f) => throw f,
  };
}

/// Collections (top-level categories, in API order) that house [shop]
/// sells in, each fronted by its latest upload's first image.
final jewelryHouseCollectionsProvider = FutureProvider.autoDispose
    .family<List<JewelryHouseCollection>, String>((ref, shop) async {
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      final categories = await ref.watch(jewelleryCategoriesProvider.future);
      final newest = await Future.wait([
        for (final c in categories) _newestPiece(ref, shop, c.slug, cancel),
      ]);
      return [
        for (final (i, c) in categories.indexed)
          if (newest[i] case final piece?)
            (
              category: c,
              cover: piece.imageUrls.firstOrNull ?? piece.displayImageUrl,
            ),
      ];
    });

/// Slugs of [query.category]'s styles (sub-categories) that house
/// [query.shop] has pieces in. Styles are created by people and change, so
/// they are read live and probed one item each.
final jewelryHouseStylesProvider = FutureProvider.autoDispose
    .family<Set<String>, ({String shop, String category})>((ref, query) async {
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      final categories = await ref.watch(jewelleryCategoriesProvider.future);
      final parent = MarketplaceCategory.find(categories, query.category);
      final styles = parent?.children ?? const <MarketplaceCategory>[];
      final newest = await Future.wait([
        for (final s in styles) _newestPiece(ref, query.shop, s.slug, cancel),
      ]);
      return {
        for (final (i, s) in styles.indexed)
          if (newest[i] != null) s.slug,
      };
    });
