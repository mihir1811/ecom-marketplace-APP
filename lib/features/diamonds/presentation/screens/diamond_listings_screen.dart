import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../ai_chat/application/ai_pending_filters.dart';
import '../../../diamond_projects/application/diamond_project_listing_pick_provider.dart';
import '../../../diamond_projects/application/diamond_selection.dart';
import '../../../diamond_projects/presentation/widgets/diamond_insight_strip.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/diamond_list_provider.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_filter_summary.dart';
import '../../../catalog_flow/presentation/widgets/catalog_flow_actions.dart';
import '../widgets/diamond_luxe_cards.dart';
import '../widgets/diamond_sorting_bottom_sheet.dart';

/// Diamond results (natural and lab grown).
///
/// Active-filter pills scroll away; the sort / filter / view toolbar and a
/// slim insight strip (selection, KPIs, Select all) stay pinned. Buyers and
/// sellers share it all; sellers also get a link to detailed analytics. Cards enter with a short stagger on first load,
/// skeletons cover loading, and empty / error states offer the next step.
class DiamondListingsScreen extends ConsumerStatefulWidget {
  const DiamondListingsScreen({
    super.key,
    this.title = 'Diamond Results',
    this.searchRoute = AppRouteNames.diamonds,
  });

  final String title;
  final String searchRoute;

  @override
  ConsumerState<DiamondListingsScreen> createState() =>
      _DiamondListingsScreenState();
}

class _DiamondListingsScreenState extends ConsumerState<DiamondListingsScreen>
    with LuxeListingMixin {
  bool get _isLab => widget.searchRoute == AppRouteNames.labGrownDiamonds;

  @override
  void initState() {
    super.initState();
    initListing();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyPendingAiFilters(),
    );
  }

  void _applyPendingAiFilters() {
    if (!mounted) return;
    final pending = ref.read(aiPendingDiamondFiltersProvider);
    if (pending == null) return;
    if (pending.isLabGrown != _isLab) return;

    ref.read(diamondSearchProvider.notifier).replaceFilters(pending.filters);
    ref.read(aiPendingDiamondFiltersProvider.notifier).state = null;
    ref.invalidate(diamondListProvider);
  }

  @override
  void dispose() {
    disposeListing();
    super.dispose();
  }

  @override
  bool get listingCanLoadMore {
    final s = ref.read(diamondListProvider).valueOrNull;
    return s != null &&
        s.hasMore &&
        !s.isLoadingMore &&
        !s.isInitialLoading &&
        !s.isRefreshing;
  }

  @override
  void listingLoadMore() =>
      ref.read(diamondListProvider.notifier).loadNextPage();

  @override
  int get listingItemCount =>
      ref.read(diamondListProvider).valueOrNull?.diamonds.length ?? 0;

  @override
  LuxeViewMode get listingViewMode =>
      ref.read(diamondViewModeProvider) == ViewMode.grid
      ? LuxeViewMode.grid
      : LuxeViewMode.list;

  @override
  void listingApplyViewMode(LuxeViewMode mode) =>
      ref.read(diamondViewModeProvider.notifier).state =
          mode == LuxeViewMode.grid ? ViewMode.grid : ViewMode.list;

  void _editFilters() => context.resetTo(widget.searchRoute);

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    final title = widget.title == 'Diamond Results'
        ? context.tr(RemainingL10n.naturalDiamonds)
        : widget.title;
    final selecting = ref.watch(
      diamondProjectListingPickProvider.select((s) => s.isNotEmpty),
    );

    return AppScaffold(
      // Runs on behind the floating dock; the scroll view clears it.
      safeBottom: false,
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: title,
        subtitle: const _CountLine(),
        scrollOffset: listingOffset,
        actions: const [CatalogFlowActions()],
      ),
      body: LuxeListingScrollView(
        controller: listingScroll,
        offset: listingOffset,
        onRefresh: () => ref.read(diamondListProvider.notifier).refresh(),
        onBackToTop: listingBackToTop,
        backToTopLabel: context.tr(DiamondFlowL10n.backToTop),
        slivers: [
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: listingHeaderKey,
              child: _ActiveFilterPills(
                onEdit: _editFilters,
                onResetAll: () => ref
                    .read(diamondListProvider.notifier)
                    .resetFiltersAndReload(),
              ),
            ),
          ),
          LuxePinnedBar(
            extent: selecting ? 56 + kDiamondInsightStripHeight + 6 : 56,
            child: Column(
              children: [
                _Toolbar(
                  onEditFilters: _editFilters,
                  onSwitchViewMode: switchListingViewMode,
                ),
                // Only while something is picked.
                if (selecting) const DiamondInsightStrip(),
              ],
            ),
          ),
          ..._content(context),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final stateAsync = ref.watch(diamondListProvider);
    final grid = ref.watch(diamondViewModeProvider) == ViewMode.grid;
    final state = stateAsync.valueOrNull;
    final error =
        stateAsync.whenOrNull(error: (e, _) => e.toString()) ??
        state?.errorMessage;
    final listed = state?.diamonds ?? const [];
    return luxeResultSlivers(
      context: context,
      initialLoading:
          !stateAsync.hasError && (state == null || state.isInitialLoading),
      error: error,
      items: listed,
      isLoadingMore: state?.isLoadingMore ?? false,
      viewMode: grid ? LuxeViewMode.grid : LuxeViewMode.list,
      idOf: (d) => d.id,
      cardOf: (d, mode) => mode == LuxeViewMode.grid
          ? DiamondLuxeGridCard(
              diamond: d,
              onTap: () => openDiamondDetail(context, d, among: listed),
            )
          : DiamondLuxeListCard(
              diamond: d,
              onTap: () => openDiamondDetail(context, d, among: listed),
            ),
      entered: listingEntered,
      loadingMoreLabel: context.tr(DiamondFlowL10n.loadingMore),
      emptyView: LuxeStateView(
        icon: Icons.diamond_outlined,
        title: context.tr(DiamondFlowL10n.emptyTitle),
        message: context.tr(DiamondFlowL10n.emptyBody),
        actionLabel: context.tr(DiamondFlowL10n.editFilters),
        onAction: _editFilters,
        secondaryLabel: context.tr(CatalogL10n.resetFilters),
        onSecondary: () =>
            ref.read(diamondListProvider.notifier).resetFiltersAndReload(),
      ),
      errorView: (message) => LuxeStateView(
        icon: Icons.cloud_off_rounded,
        tone: LuxeTone.error,
        title: context.tr(DiamondFlowL10n.errorTitle),
        message: message,
        actionLabel: context.tr(CatalogL10n.retry),
        onAction: () =>
            ref.read(diamondListProvider.notifier).applyFiltersAndSort(),
        secondaryLabel: context.tr(DiamondFlowL10n.editFilters),
        onSecondary: _editFilters,
      ),
    );
  }
}

/// "1,284 diamonds" (or "Searching…") under the title, cross-fading.
class _CountLine extends ConsumerWidget {
  const _CountLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(
      diamondListProvider.select((v) {
        final s = v.valueOrNull;
        if (s == null || s.isInitialLoading) return null;
        return s.totalCount;
      }),
    );
    return LuxeCountLine(
      text: total == null
          ? context.tr(DiamondFlowL10n.searching)
          : context.tr(DiamondFlowL10n.resultsCount, {
              'count': formatGroupedWhole(total.toDouble()),
            }),
    );
  }
}

/// Pills summarising which finder sections hold filters; tapping edits.
class _ActiveFilterPills extends ConsumerWidget {
  const _ActiveFilterPills({required this.onEdit, required this.onResetAll});

  final VoidCallback onEdit;
  final VoidCallback onResetAll;

  static String _label(
    BuildContext context,
    DiamondFinderSection s,
  ) => context.tr(switch (s) {
    DiamondFinderSection.shape => DiamondFlowL10n.sectionShape,
    DiamondFinderSection.sizePrice => DiamondFlowL10n.sectionSizePrice,
    DiamondFinderSection.colorClarity => DiamondFlowL10n.sectionColorClarity,
    DiamondFinderSection.grading => DiamondFlowL10n.sectionGrading,
    DiamondFinderSection.inclusions => DiamondFlowL10n.sectionInclusions,
    DiamondFinderSection.listing => DiamondFlowL10n.sectionListing,
    DiamondFinderSection.seller => DiamondFlowL10n.sectionSeller,
    DiamondFinderSection.measurements => DiamondFlowL10n.sectionMeasurements,
    DiamondFinderSection.proportions => DiamondFlowL10n.sectionProportions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(
      diamondSearchProvider.select(DiamondFilterSummary.of),
    );
    final shapes = ref.watch(diamondSearchProvider.select((s) => s.shapes));
    return LuxeActiveFilterPills(
      labels: [
        for (final s in DiamondFinderSection.values)
          if (summary.count(s) > 0)
            s == DiamondFinderSection.shape && shapes.length <= 2
                ? shapes.join(', ')
                : '${_label(context, s)} · ${summary.count(s)}',
      ],
      onEdit: onEdit,
      onReset: onResetAll,
      resetLabel: context.tr(DiamondFlowL10n.reset),
    );
  }
}

/// Pinned row: Filters (with count), Sort and view toggle.
class _Toolbar extends ConsumerWidget {
  const _Toolbar({required this.onEditFilters, required this.onSwitchViewMode});

  final VoidCallback onEditFilters;
  final ValueChanged<LuxeViewMode> onSwitchViewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(diamondViewModeProvider);
    final active = ref.watch(
      diamondSearchProvider.select((s) => DiamondFilterSummary.of(s).total),
    );

    return LuxeListingToolbar(
      filtersLabel: context.tr(DiamondFlowL10n.filters),
      activeFilters: active,
      onFilters: onEditFilters,
      onSort: () => DiamondSortingBottomSheet.show(context),
      viewMode: viewMode == ViewMode.grid
          ? LuxeViewMode.grid
          : LuxeViewMode.list,
      onViewMode: onSwitchViewMode,
      gridLabel: context.tr(DiamondFlowL10n.grid),
      listLabel: context.tr(DiamondFlowL10n.list),
      // Sellers only, and only once stones are picked.
      extra:
          ref.watch(canAnalyzeDiamondsProvider) &&
              ref.watch(
                diamondProjectListingPickProvider.select((s) => s.isNotEmpty),
              )
          ? const DiamondAnalyticsLink()
          : null,
    );
  }
}
