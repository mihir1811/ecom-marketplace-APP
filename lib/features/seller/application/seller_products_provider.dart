import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/seller_product_repository_impl.dart';
import '../domain/models/seller_product.dart';
import '../domain/models/seller_product_column.dart';

class SellerProductsState {
  const SellerProductsState({
    this.tab = SellerProductDiamondTab.natural,
    this.statusFilter = SellerProductStatusFilter.active,
    this.viewMode = SellerProductsViewMode.grid,
    this.searchQuery = '',
    this.visibleColumnIds = const {},
    this.selectedProductIds = const {},
    this.page = 0,
    this.rowsPerPage = 25,
  });

  final SellerProductDiamondTab tab;
  final SellerProductStatusFilter statusFilter;
  final SellerProductsViewMode viewMode;
  final String searchQuery;
  final Set<String> visibleColumnIds;
  final Set<String> selectedProductIds;
  final int page;
  final int rowsPerPage;

  SellerProductsState copyWith({
    SellerProductDiamondTab? tab,
    SellerProductStatusFilter? statusFilter,
    SellerProductsViewMode? viewMode,
    String? searchQuery,
    Set<String>? visibleColumnIds,
    Set<String>? selectedProductIds,
    int? page,
    int? rowsPerPage,
  }) {
    return SellerProductsState(
      tab: tab ?? this.tab,
      statusFilter: statusFilter ?? this.statusFilter,
      viewMode: viewMode ?? this.viewMode,
      searchQuery: searchQuery ?? this.searchQuery,
      visibleColumnIds: visibleColumnIds ?? this.visibleColumnIds,
      selectedProductIds: selectedProductIds ?? this.selectedProductIds,
      page: page ?? this.page,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
    );
  }
}

class SellerProductsCatalogState {
  const SellerProductsCatalogState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<SellerProduct> products;
  final bool isLoading;
  final String? errorMessage;

  SellerProductsCatalogState copyWith({
    List<SellerProduct>? products,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SellerProductsCatalogState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final sellerProductsCatalogProvider =
    NotifierProvider<SellerProductsCatalogNotifier, SellerProductsCatalogState>(
      SellerProductsCatalogNotifier.new,
    );

/// Live seller catalog loaded from `/diamond` and `/melee-diamond`.
class SellerProductsCatalogNotifier
    extends Notifier<SellerProductsCatalogState> {
  CancelToken? _cancelToken;
  var _hasLoaded = false;

  @override
  SellerProductsCatalogState build() {
    // Rebuild on account switch so loadIfNeeded cannot keep the prior catalog.
    ref.watch(authProvider.select((s) => s.user?.id));
    ref.onDispose(() => _cancelToken?.cancel());
    _hasLoaded = false;
    _cancelToken?.cancel('auth-user-changed');
    _cancelToken = null;
    return const SellerProductsCatalogState(isLoading: true);
  }

  /// First visit only. Later visits keep the cached catalog.
  Future<void> loadIfNeeded() async {
    if (_hasLoaded) return;
    await refresh();
  }

  Future<void> refresh() async {
    final sellerId =
        ref.read(authProvider).sellerId ?? ref.read(authProvider).user?.id;
    if (sellerId == null || sellerId.isEmpty) {
      state = const SellerProductsCatalogState(
        errorMessage: 'Seller account not found. Please sign in again.',
      );
      return;
    }

    _hasLoaded = true;
    _cancelToken?.cancel('refresh');
    _cancelToken = CancelToken();
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await ref
        .read(sellerProductRepositoryProvider)
        .listProducts(sellerId: sellerId, cancelToken: _cancelToken);
    switch (result) {
      case Success(:final value):
        state = SellerProductsCatalogState(products: value);
      case ResultFailure(:final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  void updateProduct(SellerProduct product) {
    state = state.copyWith(
      products: [
        for (final p in state.products)
          if (p.id == product.id) product else p,
      ],
    );
  }

  void deleteProduct(String id) {
    state = state.copyWith(
      products: [
        for (final p in state.products)
          if (p.id == id) p.copyWith(isDeleted: true) else p,
      ],
    );
  }

  Future<Result<void, Failure>> persistUpdate(SellerProduct product) async {
    final result = await ref
        .read(sellerProductRepositoryProvider)
        .updateProduct(product);
    if (result case Success()) {
      updateProduct(product);
    }
    return result;
  }

  Future<Result<void, Failure>> persistDelete(SellerProduct product) async {
    final result = await ref
        .read(sellerProductRepositoryProvider)
        .deleteProduct(product);
    if (result case Success()) {
      deleteProduct(product.id);
    }
    return result;
  }
}

class SellerProductsController extends Notifier<SellerProductsState> {
  @override
  SellerProductsState build() {
    return SellerProductsState(
      visibleColumnIds: defaultVisibleSellerProductColumnIds(),
    );
  }

  void setTab(SellerProductDiamondTab tab) {
    state = state.copyWith(tab: tab, page: 0, selectedProductIds: {});
  }

  void setStatusFilter(SellerProductStatusFilter filter) {
    state = state.copyWith(statusFilter: filter, page: 0);
  }

  void setViewMode(SellerProductsViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, page: 0);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void setRowsPerPage(int rows) {
    state = state.copyWith(rowsPerPage: rows, page: 0);
  }

  void toggleColumn(String columnId, bool visible) {
    final next = Set<String>.from(state.visibleColumnIds);
    if (visible) {
      next.add(columnId);
    } else {
      next.remove(columnId);
    }
    state = state.copyWith(visibleColumnIds: next);
  }

  void setAllColumnsVisible(bool visible) {
    if (visible) {
      state = state.copyWith(
        visibleColumnIds: kSellerProductColumns.map((c) => c.id).toSet(),
      );
    } else {
      state = state.copyWith(visibleColumnIds: {});
    }
  }

  void resetColumnsToDefault() {
    state = state.copyWith(
      visibleColumnIds: defaultVisibleSellerProductColumnIds(),
    );
  }

  void toggleProductSelection(String productId, bool selected) {
    final next = Set<String>.from(state.selectedProductIds);
    if (selected) {
      next.add(productId);
    } else {
      next.remove(productId);
    }
    state = state.copyWith(selectedProductIds: next);
  }

  void toggleSelectAllOnPage(List<SellerProduct> pageItems, bool selected) {
    final next = Set<String>.from(state.selectedProductIds);
    for (final p in pageItems) {
      if (selected) {
        next.add(p.id);
      } else {
        next.remove(p.id);
      }
    }
    state = state.copyWith(selectedProductIds: next);
  }
}

final sellerProductsControllerProvider =
    NotifierProvider<SellerProductsController, SellerProductsState>(
      SellerProductsController.new,
    );

List<SellerProduct> filteredSellerProducts(
  List<SellerProduct> catalog,
  SellerProductsState state,
) {
  return catalog.where((p) {
    final tabOk = state.tab == SellerProductDiamondTab.natural
        ? p.isNatural
        : !p.isNatural;
    if (!tabOk) return false;
    if (p.isDeleted) return false;

    final statusOk = switch (state.statusFilter) {
      SellerProductStatusFilter.active => !p.isExpired,
      SellerProductStatusFilter.expired => p.isExpired,
      SellerProductStatusFilter.all => true,
    };
    if (!statusOk) return false;

    return p.matchesSearch(state.searchQuery);
  }).toList();
}

List<SellerProductColumnDef> visibleColumnsInOrder(SellerProductsState state) {
  return kSellerProductColumns
      .where((c) => state.visibleColumnIds.contains(c.id))
      .toList();
}
