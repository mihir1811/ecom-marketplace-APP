import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_system_back_scope.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_toggle_sort_sheet.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_actions.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/bullions_filter_provider.dart';
import '../../application/bullions_list_provider.dart';
import '../../domain/models/bullions_filter_state.dart';
import '../../domain/models/bullions_filter_summary.dart';
import '../widgets/bullion_luxe_cards.dart';
import '../../../spotlight/domain/spotlight_models.dart';
import '../../../spotlight/presentation/widgets/spotlight_category_block.dart';

/// Bullion catalogue, built from the same luxe listing pieces as the other
/// catalogues.
///
/// Search and the metal / purity presets scroll away; the filter / sort /
/// view toolbar stays pinned. Cards enter with a short stagger, skeletons
/// cover loading, and empty / error states offer the next step.
class BullionsScreen extends ConsumerStatefulWidget {
  const BullionsScreen({super.key});

  @override
  ConsumerState<BullionsScreen> createState() => _BullionsScreenState();
}

class _BullionsScreenState extends ConsumerState<BullionsScreen>
    with LuxeListingMixin {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    initListing();
    final q = ref.read(bullionsFilterProvider).searchQuery;
    if (q.isNotEmpty) _searchController.text = q;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    disposeListing();
    super.dispose();
  }

  @override
  bool get listingCanLoadMore {
    final s = ref.read(bullionsListProvider).value;
    return s != null &&
        s.hasMore &&
        !s.isLoadingMore &&
        !s.isInitialLoading &&
        !s.isRefreshing;
  }

  @override
  void listingLoadMore() =>
      ref.read(bullionsListProvider.notifier).loadNextPage();

  @override
  int get listingItemCount =>
      ref.read(bullionsListProvider).value?.bullions.length ?? 0;

  @override
  LuxeViewMode get listingViewMode =>
      ref.read(bullionsViewModeProvider) == BullionsViewMode.grid
      ? LuxeViewMode.grid
      : LuxeViewMode.list;

  @override
  void listingApplyViewMode(LuxeViewMode mode) =>
      ref
          .read(bullionsViewModeProvider.notifier)
          .state = mode == LuxeViewMode.grid
      ? BullionsViewMode.grid
      : BullionsViewMode.list;

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        ref.read(bullionsFilterProvider.notifier).setSearchQuery(value);
      }
    });
  }

  void _onSearchSubmitted(String value) {
    _searchDebounce?.cancel();
    ref.read(bullionsFilterProvider.notifier).setSearchQuery(value);
  }

  void _openFilters() {
    // Flush a pending search first so the draft starts from it and a late
    // debounce can't overwrite the draft while the filters are open.
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
      ref
          .read(bullionsFilterProvider.notifier)
          .setSearchQuery(_searchController.text);
    }
    ref.read(bullionsFilterDraftProvider.notifier).syncFromApplied();
    context.push(AppRouteNames.bullionsFilters);
  }

  void _clearAll() {
    _searchDebounce?.cancel();
    ref.read(bullionsFilterProvider.notifier).reset();
    _searchController.clear();
  }

  Future<void> _openSort() {
    String dir(BullionsSortOption o) => switch (o) {
      BullionsSortOption.priceLowToHigh ||
      BullionsSortOption.weightLowToHigh => 'Low to High',
      BullionsSortOption.priceHighToLow ||
      BullionsSortOption.weightHighToLow => 'High to Low',
      BullionsSortOption.newest => 'Newest',
      BullionsSortOption.oldest => 'Oldest',
      BullionsSortOption.featured => '',
    };
    return showLuxeToggleSortSheet<BullionsSortOption>(
      context,
      title: context.tr(CatalogFlowL10n.bullionSort),
      fields: [
        const LuxeSortField(
          label: 'Default sorting',
          options: [BullionsSortOption.featured],
        ),
        LuxeSortField(
          label: 'Price',
          options: const [
            BullionsSortOption.priceLowToHigh,
            BullionsSortOption.priceHighToLow,
          ],
          directionLabelOf: dir,
        ),
        LuxeSortField(
          label: 'Arrivals',
          options: const [BullionsSortOption.newest, BullionsSortOption.oldest],
          directionLabelOf: dir,
        ),
        LuxeSortField(
          label: 'Weight',
          options: const [
            BullionsSortOption.weightLowToHigh,
            BullionsSortOption.weightHighToLow,
          ],
          directionLabelOf: dir,
        ),
      ],
      current: ref.read(bullionsSortProvider),
      onChanged: (o) => ref.read(bullionsSortProvider.notifier).state = o,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSystemBackScope(
      child: LuxeScope(child: Builder(builder: _buildScaffold)),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    return AppScaffold(
      // Runs on behind the floating dock; the scroll view clears it.
      safeBottom: false,
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: '',
        subtitle: const _CountLine(),
        scrollOffset: listingOffset,
        actions: const [TopBarActions()],
      ),
      body: LuxeListingScrollView(
        controller: listingScroll,
        offset: listingOffset,
        onRefresh: () => ref.read(bullionsListProvider.notifier).refresh(),
        onBackToTop: listingBackToTop,
        backToTopLabel: context.tr(DiamondFlowL10n.backToTop),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              key: listingHeaderKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 5, 12, 12),
                  child: LuxeSearchField(
                    controller: _searchController,
                    hintText: context.tr(CatalogL10n.searchBullions),
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchSubmitted,
                  ),
                ),
                const SpotlightCategoryBlock(
                  category: SpotlightCategory.bullion,
                  topSpacing: 0,
                ),
                LuxeRowHeading(title: context.tr(CatalogFlowL10n.metal)),
                const _MetalPresets(),
              ],
            ),
          ),
          LuxePinnedBar(
            child: Center(
              child: _Toolbar(
                onFilters: _openFilters,
                onSort: _openSort,
                onViewMode: switchListingViewMode,
              ),
            ),
          ),
          ..._content(context),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final stateAsync = ref.watch(bullionsListProvider);
    final grid = ref.watch(bullionsViewModeProvider) == BullionsViewMode.grid;
    final state = stateAsync.value;
    final error =
        stateAsync.whenOrNull(error: (e, _) => e.toString()) ??
        state?.errorMessage;
    final listed = state?.bullions ?? const [];
    return luxeResultSlivers(
      context: context,
      initialLoading:
          !stateAsync.hasError && (state == null || state.isInitialLoading),
      error: error,
      items: listed,
      isLoadingMore: state?.isLoadingMore ?? false,
      viewMode: grid ? LuxeViewMode.grid : LuxeViewMode.list,
      idOf: (b) => b.id,
      cardOf: (b, mode) => mode == LuxeViewMode.grid
          ? BullionLuxeGridCard(
              bullion: b,
              onTap: () => openBullionDetail(context, b, among: listed),
            )
          : BullionLuxeListCard(
              bullion: b,
              onTap: () => openBullionDetail(context, b, among: listed),
            ),
      loadingMoreLabel: context.tr(DiamondFlowL10n.loadingMore),
      emptyView: LuxeStateView(
        icon: Icons.account_balance_wallet_outlined,
        title: context.tr(CatalogL10n.noBullions),
        message: context.tr(CatalogL10n.adjustBullionFilters),
        actionLabel: context.tr(DiamondFlowL10n.editFilters),
        onAction: _openFilters,
        secondaryLabel: context.tr(CatalogL10n.clearAll),
        onSecondary: _clearAll,
      ),
      errorView: (message) => LuxeStateView(
        icon: Icons.cloud_off_rounded,
        tone: LuxeTone.error,
        title: context.tr(CatalogFlowL10n.errorTitle),
        message: message,
        actionLabel: context.tr(CatalogL10n.retry),
        onAction: () => ref.read(bullionsListProvider.notifier).refresh(),
        secondaryLabel: context.tr(DiamondFlowL10n.editFilters),
        onSecondary: _openFilters,
      ),
    );
  }
}

/// Metal presets with tone dots, plus multi-select purity variants for the
/// chosen metal.
class _MetalPresets extends ConsumerWidget {
  const _MetalPresets();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metal = ref.watch(
      bullionsFilterProvider.select((s) => s.metalFilter),
    );
    final picked = ref.watch(
      bullionsFilterProvider.select((s) => s.selectedVariants),
    );
    final variants = ref.watch(
      bullionsFilterProvider.select((s) => s.availableVariants),
    );
    final notifier = ref.read(bullionsFilterProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuxeQuickChips<BullionsMetalFilter>(
          chips: [
            for (final m in BullionsMetalFilter.values)
              LuxeQuickChip(
                value: m,
                label: m.label,
                tone: m.metal == null ? null : bullionMetalTone(m.metal),
              ),
          ],
          isSelected: (m) => m == metal,
          onTap: notifier.setMetalFilter,
        ),
        AnimatedSize(
          duration: LuxeMotion.medium,
          curve: LuxeMotion.settle,
          alignment: Alignment.topCenter,
          child: variants.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: LuxeQuickChips<String>(
                    key: ValueKey(metal),
                    dense: true,
                    chips: [
                      for (final v in variants)
                        LuxeQuickChip(value: v, label: v),
                    ],
                    isSelected: picked.contains,
                    onTap: notifier.toggleVariant,
                  ),
                ),
        ),
      ],
    );
  }
}

/// "248 bars & coins" (or "Searching…") under the title.
class _CountLine extends ConsumerWidget {
  const _CountLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(
      bullionsListProvider.select((v) {
        final s = v.value;
        return s == null || s.isInitialLoading ? null : s.totalCount;
      }),
    );
    return LuxeCountLine(
      text: total == null
          ? context.tr(DiamondFlowL10n.searching)
          : context.tr(CatalogFlowL10n.bullionResults, {
              'count': formatGroupedWhole(total.toDouble()),
            }),
    );
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({
    required this.onFilters,
    required this.onSort,
    required this.onViewMode,
  });

  final VoidCallback onFilters;
  final VoidCallback onSort;
  final ValueChanged<LuxeViewMode> onViewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grid = ref.watch(
      bullionsViewModeProvider.select((m) => m == BullionsViewMode.grid),
    );
    final active = ref.watch(
      bullionsFilterProvider.select((s) => BullionsFilterSummary.of(s).total),
    );
    return LuxeListingToolbar(
      filtersLabel: context.tr(DiamondFlowL10n.filters),
      activeFilters: active,
      onFilters: onFilters,
      onSort: onSort,
      viewMode: grid ? LuxeViewMode.grid : LuxeViewMode.list,
      onViewMode: onViewMode,
      gridLabel: context.tr(DiamondFlowL10n.grid),
      listLabel: context.tr(DiamondFlowL10n.list),
    );
  }
}
