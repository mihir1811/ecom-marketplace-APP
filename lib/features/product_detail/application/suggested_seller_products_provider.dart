import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../data/repositories/suggested_seller_products_repository_impl.dart';
import '../domain/models/listing_seller_info.dart';
import '../domain/models/product_detail.dart';
import '../domain/repositories/suggested_seller_products_repository.dart';

/// Query key for same-seller suggestions on a product detail screen.
@immutable
class SuggestedSellerProductsQuery {
  const SuggestedSellerProductsQuery({
    required this.segment,
    required this.excludeProductId,
    this.sellerId,
    this.companyName,
  });

  factory SuggestedSellerProductsQuery.fromDetail(ProductDetail detail) {
    final seller = detail.listingSeller;
    return SuggestedSellerProductsQuery(
      segment: detail.segment,
      excludeProductId: detail.id,
      sellerId: _sellerId(seller),
      companyName: _companyName(seller),
    );
  }

  final ProductSegment segment;
  final String excludeProductId;
  final String? sellerId;
  final String? companyName;

  bool get canLoad {
    final sid = sellerId?.trim() ?? '';
    final company = companyName?.trim() ?? '';
    return sid.isNotEmpty || company.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    return other is SuggestedSellerProductsQuery &&
        other.segment == segment &&
        other.excludeProductId == excludeProductId &&
        other.sellerId == sellerId &&
        other.companyName == companyName;
  }

  @override
  int get hashCode =>
      Object.hash(segment, excludeProductId, sellerId, companyName);

  static String? _sellerId(ListingSellerInfo? seller) {
    final id = seller?.id?.trim();
    if (id != null && id.isNotEmpty) return id;
    final userId = seller?.userId?.trim();
    if (userId != null && userId.isNotEmpty) return userId;
    return null;
  }

  static String? _companyName(ListingSellerInfo? seller) {
    final name = seller?.displayName.trim() ?? '';
    if (name.isEmpty || name.toLowerCase() == 'seller') return null;
    return name;
  }
}

typedef SuggestedSellerProductsState = PaginatedListState<ProductDetail>;

final suggestedSellerProductsProvider =
    NotifierProvider.family<
      SuggestedSellerProductsNotifier,
      SuggestedSellerProductsState,
      SuggestedSellerProductsQuery
    >(SuggestedSellerProductsNotifier.new);

class SuggestedSellerProductsNotifier
    extends FamilyNotifier<SuggestedSellerProductsState, SuggestedSellerProductsQuery> {
  CancelToken? _cancelToken;
  int _page = 1;
  Future<void>? _inFlightNext;

  SuggestedSellerProductsRepository get _repo =>
      ref.read(suggestedSellerProductsRepositoryProvider);

  @override
  SuggestedSellerProductsState build(SuggestedSellerProductsQuery arg) {
    ref.onDispose(() {
      final token = _cancelToken;
      if (token != null && !token.isCancelled) {
        token.cancel('suggested-seller-disposed');
      }
    });

    if (!arg.canLoad) {
      return const SuggestedSellerProductsState(hasMore: false);
    }

    Future.microtask(loadFirstPage);
    return const SuggestedSellerProductsState(isInitialLoading: true);
  }

  Future<void> loadFirstPage() async {
    if (!arg.canLoad) {
      state = const SuggestedSellerProductsState(hasMore: false);
      return;
    }

    _cancelToken?.cancel('suggested-seller-reset');
    _cancelToken = CancelToken();
    _page = 1;
    _inFlightNext = null;
    state = const SuggestedSellerProductsState(isInitialLoading: true);

    final result = await _repo.getPage(
      segment: arg.segment,
      excludeProductId: arg.excludeProductId,
      sellerId: arg.sellerId,
      companyName: arg.companyName,
      page: 1,
      pageSize: SuggestedSellerProductsPageSize.defaultSize,
      cancelToken: _cancelToken,
    );

    switch (result) {
      case Success(value: final page):
        state = SuggestedSellerProductsState(
          items: page.items,
          hasMore: page.hasMore && page.items.isNotEmpty,
          totalCount: page.totalCount,
        );
      case ResultFailure(failure: final failure):
        state = SuggestedSellerProductsState(
          hasMore: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<void> loadNextPage() {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.isInitialLoading ||
        state.items.isEmpty) {
      return _inFlightNext ?? Future<void>.value();
    }
    if (_inFlightNext != null) return _inFlightNext!;

    _inFlightNext = _loadNextBody();
    return _inFlightNext!;
  }

  Future<void> _loadNextBody() async {
    final previous = state;
    state = previous.copyWith(isLoadingMore: true, errorMessage: null);
    final nextPage = _page + 1;

    try {
      final result = await _repo.getPage(
        segment: arg.segment,
        excludeProductId: arg.excludeProductId,
        sellerId: arg.sellerId,
        companyName: arg.companyName,
        page: nextPage,
        pageSize: SuggestedSellerProductsPageSize.defaultSize,
        cancelToken: _cancelToken,
      );

      switch (result) {
        case Success(value: final page):
          _page = nextPage;
          state = previous.copyWith(
            items: [...previous.items, ...page.items],
            hasMore: page.hasMore && page.items.isNotEmpty,
            totalCount: page.totalCount,
            isLoadingMore: false,
          );
        case ResultFailure(failure: final failure):
          state = previous.copyWith(
            isLoadingMore: false,
            errorMessage: failure.message,
          );
      }
    } finally {
      _inFlightNext = null;
    }
  }
}
