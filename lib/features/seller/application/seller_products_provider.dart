import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seller_products_mock_data.dart';
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

final sellerProductsCatalogProvider = Provider<List<SellerProduct>>((ref) {
  return buildSellerProductsMockCatalog();
});

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
