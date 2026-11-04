import 'dart:convert';

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
import '../../diamonds/data/mappers/seller_diamond_project_search_mapper.dart';
import '../../diamonds/data/repositories/diamond_repository_impl.dart';
import '../../diamonds/domain/models/diamond.dart';
import '../../diamonds/domain/models/diamond_filter_state.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

/// Option values present in the seller's whole (unfiltered) inventory, so the
/// filter dialog only offers choices that can match a stone.
class SellerDiamondProjectFacets {
  const SellerDiamondProjectFacets({
    this.shapes = const {},
    this.colors = const {},
    this.clarities = const {},
    this.cuts = const {},
    this.fancyColors = const {},
    this.labs = const {},
    this.minCarat,
    this.maxCarat,
    this.minRatio,
    this.maxRatio,
  });

  /// Lower-cased values; test options with [has].
  final Set<String> shapes;
  final Set<String> colors;
  final Set<String> clarities;
  final Set<String> cuts;
  final Set<String> fancyColors;
  final Set<String> labs;
  final double? minCarat;
  final double? maxCarat;
  final double? minRatio;
  final double? maxRatio;

  static const _knownLabs = {'gia', 'hrd', 'igi', 'egl', 'ags'};

  static bool has(Set<String> set, String option) =>
      set.contains(option.trim().toLowerCase());

  static String? _key(String? raw) {
    final v = raw?.trim().toLowerCase();
    return (v == null || v.isEmpty) ? null : v;
  }

  static String _cutKey(String raw) => switch (raw) {
    'id' => 'ideal',
    'ex' => 'excellent',
    'vg' => 'very good',
    'gd' || 'g' => 'good',
    'fr' || 'f' => 'fair',
    'pr' || 'p' => 'poor',
    _ => raw,
  };

  factory SellerDiamondProjectFacets.fromDiamonds(List<Diamond> diamonds) {
    final shapes = <String>{};
    final colors = <String>{};
    final clarities = <String>{};
    final cuts = <String>{};
    final fancy = <String>{};
    final labs = <String>{};
    double? minCt, maxCt, minRatio, maxRatio;
    for (final d in diamonds) {
      if (_key(d.shape) case final v?) shapes.add(v);
      if (_key(d.clarity) case final v?) clarities.add(v);
      if (_key(d.cut) case final v?) cuts.add(_cutKey(v));
      if (_key(d.fancyColor) case final v?) fancy.add(v);
      // Paired grades ("Y-Z") stand for both letters.
      if (_key(d.color) case final v?) {
        for (final part in v.split(RegExp(r'[-/ ]'))) {
          if (part.isNotEmpty) colors.add(part);
        }
      }
      if (_key(d.lab ?? d.certificate) case final v?) {
        labs.add(_knownLabs.contains(v) ? v : 'others');
      }
      if (d.carat > 0) {
        if (minCt == null || d.carat < minCt) minCt = d.carat;
        if (maxCt == null || d.carat > maxCt) maxCt = d.carat;
      }
      final ratio = double.tryParse(d.ratio?.trim() ?? '');
      if (ratio != null && ratio > 0) {
        if (minRatio == null || ratio < minRatio) minRatio = ratio;
        if (maxRatio == null || ratio > maxRatio) maxRatio = ratio;
      }
    }
    return SellerDiamondProjectFacets(
      shapes: shapes,
      colors: colors,
      clarities: clarities,
      cuts: cuts,
      fancyColors: fancy,
      labs: labs,
      minCarat: minCt,
      maxCarat: maxCt,
      minRatio: minRatio,
      maxRatio: maxRatio,
    );
  }
}

class SellerDiamondProjectInventoryState {
  const SellerDiamondProjectInventoryState({
    this.items = const [],
    this.totalCount = 0,
    this.appliedFilters,
    this.hasApplied = false,
    this.facets,
  });

  final List<DiamondProjectItem> items;
  final int totalCount;
  final DiamondFilterState? appliedFilters;
  final bool hasApplied;

  /// Options in the whole inventory; null until known.
  final SellerDiamondProjectFacets? facets;

  bool get isEmpty => items.isEmpty;

  SellerDiamondProjectInventoryState copyWith({
    List<DiamondProjectItem>? items,
    int? totalCount,
    DiamondFilterState? appliedFilters,
    bool? hasApplied,
    SellerDiamondProjectFacets? facets,
    bool clearAppliedFilters = false,
  }) {
    return SellerDiamondProjectInventoryState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      appliedFilters: clearAppliedFilters
          ? null
          : (appliedFilters ?? this.appliedFilters),
      hasApplied: hasApplied ?? this.hasApplied,
      facets: facets ?? this.facets,
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
      selectedStandardColors: hasFancy
          ? const []
          : state.selectedStandardColors,
    );
  }
}

/// Filtered active natural inventory for the signed-in seller.
final sellerDiamondProjectInventoryProvider =
    AsyncNotifierProvider<
      SellerDiamondProjectInventoryNotifier,
      SellerDiamondProjectInventoryState
    >(SellerDiamondProjectInventoryNotifier.new);

final sellerDiamondProjectStatsProvider = Provider<DiamondProjectStats>((ref) {
  // Watch the full async value (not a List select) so stats always recompute
  // when inventory finishes loading after AsyncLoading clears valueOrNull.
  final inventory = ref.watch(sellerDiamondProjectInventoryProvider);
  final items = inventory.value?.items ?? const <DiamondProjectItem>[];
  return DiamondProjectStatsCalculator.compute(items);
});

class SellerDiamondProjectInventoryNotifier
    extends AsyncNotifier<SellerDiamondProjectInventoryState>
    with DisposeTolerantAsyncNotifier<SellerDiamondProjectInventoryState> {
  CancelToken? _cancelToken;
  CancelToken? _facetsToken;

  @override
  Future<SellerDiamondProjectInventoryState> build() async {
    ref.watch(authProvider.select((s) => s.user?.id));
    ref.onDispose(() {
      _cancelToken?.cancel();
      _facetsToken?.cancel();
    });
    _cancelToken?.cancel('auth-user-changed');
    _cancelToken = null;
    _facetsToken?.cancel('auth-user-changed');
    _facetsToken = null;
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
    final token = _cancelToken = CancelToken();

    final previous = state.value;
    state = previous == null
        ? const AsyncLoading()
        // Keeps the previous inventory visible while reloading. Marked
        // internal in Riverpod 3 but unchanged; ref.refresh would refetch.
        : const AsyncLoading<SellerDiamondProjectInventoryState>()
          // ignore: invalid_use_of_internal_member
          .copyWithPrevious(AsyncData(previous));

    final fetched = await _fetchAll(sellerId, filters, token);
    if (!ref.mounted) return;
    if (fetched == null) return;
    final (diamonds, totalCount) = fetched;
    // An unfiltered load is the whole inventory: its options are the facets.
    final facets = _isUnfiltered(filters)
        ? SellerDiamondProjectFacets.fromDiamonds(diamonds)
        : previous?.facets;

    state = AsyncData(
      SellerDiamondProjectInventoryState(
        items: List<DiamondProjectItem>.unmodifiable([
          for (final d in diamonds)
            DiamondProjectMapper.fromDiamond(d, productKind: 'SINGLE'),
        ]),
        totalCount: totalCount,
        appliedFilters: filters,
        hasApplied: true,
        facets: facets,
      ),
    );
    if (facets == null) _loadFacets(sellerId);
  }

  /// Every page of seller inventory matching [filters] and the total count;
  /// null when cancelled or failed.
  Future<(List<Diamond>, int)?> _fetchAll(
    String sellerId,
    DiamondFilterState filters,
    CancelToken token, {
    bool reportErrors = true,
  }) async {
    final repo = ref.read(diamondRepositoryProvider);
    final diamonds = <Diamond>[];
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
        cancelToken: token,
      );
      switch (result) {
        case Success(value: final response):
          totalCount = response.totalCount;
          for (final diamond in response.diamonds) {
            if (diamond.id.isEmpty || !seen.add(diamond.id)) continue;
            diamonds.add(diamond);
          }
          hasMore = response.hasMore && response.diamonds.isNotEmpty;
          // Always advance from the requested page — response.page can reset
          // and stall the loop on the same page.
          page = requestedPage + 1;
        case ResultFailure(failure: final failure):
          if (failure is NetworkFailure && failure.isCancelled) return null;
          if (reportErrors) {
            state = AsyncError(failure.message, StackTrace.current);
          }
          return null;
      }
    }
    return (diamonds, totalCount);
  }

  static String _bodyKey(DiamondFilterState filters) => jsonEncode(
    SellerDiamondProjectSearchMapper.toBody(
      sellerId: '',
      filters: filters,
      page: 1,
    ),
  );

  static final _unfilteredKey = _bodyKey(const DiamondFilterState());

  static bool _isUnfiltered(DiamondFilterState filters) =>
      _bodyKey(filters) == _unfilteredKey;

  /// Background pass over the whole inventory when the loads so far were
  /// filtered, so the dialog still knows every available option.
  Future<void> _loadFacets(String sellerId) async {
    if (_facetsToken != null) return;
    final token = _facetsToken = CancelToken();
    try {
      final fetched = await _fetchAll(
        sellerId,
        const DiamondFilterState(),
        token,
        reportErrors: false,
      );
      if (!ref.mounted) return;
      final current = state.value;
      if (fetched == null || current == null || current.facets != null) {
        return;
      }
      state = AsyncData(
        current.copyWith(
          facets: SellerDiamondProjectFacets.fromDiamonds(fetched.$1),
        ),
      );
    } finally {
      if (identical(_facetsToken, token)) _facetsToken = null;
    }
  }

  void clearFilters() {
    ref.read(sellerDiamondProjectFiltersProvider.notifier).reset();
    applyFilters();
  }

  Future<void> loadIfNeeded() async {
    if (state.value?.hasApplied == true) return;
    await applyFilters();
    if (!ref.mounted) return;
  }

  /// Drops one stone from the applied inventory (and therefore from KPIs/charts).
  void removeItem(String diamondId) {
    final current = state.value;
    if (current == null || !current.hasApplied) return;
    final id = diamondId.trim();
    if (id.isEmpty) return;

    final next = [
      for (final item in current.items)
        if (item.diamondId != id) item,
    ];
    if (next.length == current.items.length) return;

    state = AsyncData(
      current.copyWith(
        items: List<DiamondProjectItem>.unmodifiable(next),
        totalCount: next.length,
      ),
    );
  }
}
