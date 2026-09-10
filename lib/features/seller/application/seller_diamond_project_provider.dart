import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../diamond_projects/data/mappers/diamond_project_mapper.dart';
import '../../diamond_projects/domain/diamond_project_stats_calculator.dart';
import '../../diamond_projects/domain/models/diamond_project_item.dart';
import '../../diamond_projects/domain/models/diamond_project_stats.dart';
import '../../diamonds/application/diamond_search_provider.dart';
import '../../diamonds/data/repositories/diamond_repository_impl.dart';
import '../../diamonds/domain/models/diamond_filter_state.dart';

class SellerDiamondProjectInventoryState {
  const SellerDiamondProjectInventoryState({
    this.items = const [],
    this.totalCount = 0,
    this.appliedFilters,
    this.hasApplied = false,
  });

  final List<DiamondProjectItem> items;
  final int totalCount;
  final DiamondFilterState? appliedFilters;
  final bool hasApplied;

  bool get isEmpty => items.isEmpty;

  SellerDiamondProjectInventoryState copyWith({
    List<DiamondProjectItem>? items,
    int? totalCount,
    DiamondFilterState? appliedFilters,
    bool? hasApplied,
    bool clearAppliedFilters = false,
  }) {
    return SellerDiamondProjectInventoryState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      appliedFilters: clearAppliedFilters
          ? null
          : (appliedFilters ?? this.appliedFilters),
      hasApplied: hasApplied ?? this.hasApplied,
    );
  }
}

/// Draft filter state for the seller dashboard diamond-projects panel.
final sellerDiamondProjectFiltersProvider =
    NotifierProvider<SellerDiamondProjectFiltersNotifier, DiamondFilterState>(
  SellerDiamondProjectFiltersNotifier.new,
);

/// Individual chip toggles for color/clarity (not range select) on seller dashboard.
class SellerDiamondProjectFiltersNotifier extends DiamondSearchNotifier {
  @override
  void toggleStandardColor(String color) {
    final current = List<String>.from(state.selectedStandardColors);
    if (current.contains(color)) {
      current.remove(color);
    } else {
      current.add(color);
    }
    state = state.copyWith(
      isFancyColor: false,
      selectedStandardColors: List<String>.unmodifiable(current),
    );
  }

  @override
  void toggleClarityGradeGroup(String grade) {
    final current = List<String>.from(state.selectedClarityGrades);
    if (current.contains(grade)) {
      current.remove(grade);
    } else {
      current.add(grade);
    }
    state = state.copyWith(
      selectedClarityGrades: List<String>.unmodifiable(current),
    );
  }

  @override
  void toggleFancyColor(String color) {
    super.toggleFancyColor(color);
    final hasFancy = state.selectedFancyColors.isNotEmpty;
    state = state.copyWith(
      isFancyColor: hasFancy,
      selectedStandardColors: hasFancy ? const [] : state.selectedStandardColors,
    );
  }
}

/// Filtered active natural inventory for the signed-in seller.
final sellerDiamondProjectInventoryProvider =
    AsyncNotifierProvider<SellerDiamondProjectInventoryNotifier,
        SellerDiamondProjectInventoryState>(
  SellerDiamondProjectInventoryNotifier.new,
);

final sellerDiamondProjectStatsProvider = Provider<DiamondProjectStats>((ref) {
  // Watch the full async value (not a List select) so stats always recompute
  // when inventory finishes loading after AsyncLoading clears valueOrNull.
  final inventory = ref.watch(sellerDiamondProjectInventoryProvider);
  final items =
      inventory.valueOrNull?.items ?? const <DiamondProjectItem>[];
  return DiamondProjectStatsCalculator.compute(items);
});

class SellerDiamondProjectInventoryNotifier
    extends AsyncNotifier<SellerDiamondProjectInventoryState> {
  CancelToken? _cancelToken;

  @override
  Future<SellerDiamondProjectInventoryState> build() async {
    ref.watch(authProvider.select((s) => s.user?.id));
    ref.onDispose(() => _cancelToken?.cancel());
    _cancelToken?.cancel('auth-user-changed');
    _cancelToken = null;
    return const SellerDiamondProjectInventoryState();
  }

  Future<void> applyFilters() async {
    final sellerId =
        ref.read(authProvider).sellerId ?? ref.read(authProvider).user?.id;
    if (sellerId == null || sellerId.isEmpty) {
      state = AsyncError(
        'Seller account not found. Please sign in again.',
        StackTrace.current,
      );
      return;
    }

    final filters = ref.read(sellerDiamondProjectFiltersProvider);
    _cancelToken?.cancel('seller-diamond-project-apply');
    _cancelToken = CancelToken();

    final previous = state.valueOrNull;
    state = previous == null
        ? const AsyncLoading()
        : const AsyncLoading<SellerDiamondProjectInventoryState>()
            .copyWithPrevious(AsyncData(previous));
    final repo = ref.read(diamondRepositoryProvider);

    final items = <DiamondProjectItem>[];
    final seen = <String>{};
    var page = 1;
    var totalCount = 0;
    var hasMore = true;

    while (hasMore && page <= 50) {
      final requestedPage = page;
      final result = await repo.searchSellerInventory(
        sellerId: sellerId,
        filters: filters,
        page: requestedPage,
        cancelToken: _cancelToken,
      );
      switch (result) {
        case Success(value: final response):
          totalCount = response.totalCount;
          for (final diamond in response.diamonds) {
            if (diamond.id.isEmpty || !seen.add(diamond.id)) continue;
            items.add(
              DiamondProjectMapper.fromDiamond(diamond, productKind: 'SINGLE'),
            );
          }
          hasMore = response.hasMore && response.diamonds.isNotEmpty;
          // Always advance from the requested page — response.page can reset
          // and stall the loop on the same page.
          page = requestedPage + 1;
        case ResultFailure(failure: final failure):
          if (failure is NetworkFailure && failure.isCancelled) return;
          state = AsyncError(failure.message, StackTrace.current);
          return;
      }
    }

    state = AsyncData(
      SellerDiamondProjectInventoryState(
        items: List<DiamondProjectItem>.unmodifiable(items),
        totalCount: totalCount,
        appliedFilters: filters,
        hasApplied: true,
      ),
    );
  }

  void clearFilters() {
    ref.read(sellerDiamondProjectFiltersProvider.notifier).reset();
    applyFilters();
  }

  Future<void> loadIfNeeded() async {
    if (state.valueOrNull?.hasApplied == true) return;
    await applyFilters();
  }
}
