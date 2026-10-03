import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
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
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../ai_chat/application/ai_pending_filters.dart';
import '../../../comparison/presentation/widgets/comparison_bottom_bar.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_listing_actions.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_pick_bottom_bar.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/diamond_list_provider.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_filter_summary.dart';
import '../../../catalog_flow/presentation/widgets/catalog_flow_actions.dart';
import '../widgets/diamond_listing_stats_bar.dart';
import '../widgets/diamond_luxe_cards.dart';
import '../widgets/diamond_sorting_bottom_sheet.dart';

/// Diamond results (natural and lab grown).
///
/// Insights and active-filter pills scroll away; the sort / filter / view
/// toolbar stays pinned. Cards enter with a short stagger on first load,
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

class _DiamondListingsScreenState extends ConsumerState<DiamondListingsScreen> {
  static const _gap = 12.0;
  static const _pad = 16.0;
  static const _listStride = LuxeProductListCard.thumbSize + 12 + _gap;

  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);
  final _headerKey = GlobalKey();
  final _entered = <String>{};

  bool get _isLab => widget.searchRoute == AppRouteNames.labGrownDiamonds;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
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
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _offset.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    _offset.value = _scroll.offset;

    final listState = ref.read(diamondListProvider).valueOrNull;
    if (listState == null ||
        !listState.hasMore ||
        listState.isLoadingMore ||
        listState.isInitialLoading ||
        listState.isRefreshing) {
      return;
    }
    final position = _scroll.position;
    // Prefetch ~1 viewport before the end so the next page arrives seamlessly.
    if (position.pixels >=
        position.maxScrollExtent - position.viewportDimension) {
      ref.read(diamondListProvider.notifier).loadNextPage();
    }
  }

  double get _headerExtent {
    final box = _headerKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : 0;
  }

  double _gridStride(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cell = (width - _pad * 2 - _gap) / 2;
    return cell +
        luxeGridCardTextExtent(MediaQuery.textScalerOf(context)) +
        _gap;
  }

  void _switchViewMode(ViewMode next) {
    final current = ref.read(diamondViewModeProvider);
    if (current == next) return;
    AppHaptics.selection();
    final count =
        ref.read(diamondListProvider).valueOrNull?.diamonds.length ?? 0;
    final into = (_scroll.hasClients ? _scroll.offset : 0) - _headerExtent;
    final index = count == 0 || into <= 0
        ? 0
        : (current == ViewMode.grid
                  ? (into / _gridStride(context)).floor() * 2
                  : (into / _listStride).floor())
              .clamp(0, count - 1);
    ref.read(diamondViewModeProvider.notifier).state = next;
    if (index == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target =
          _headerExtent +
          (next == ViewMode.grid
              ? (index ~/ 2) * _gridStride(context)
              : index * _listStride);
      _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
    });
  }

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

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: title,
        subtitle: const _CountLine(),
        scrollOffset: _offset,
        actions: const [CatalogFlowActions()],
      ),
      body: Column(
        children: [
          Expanded(
            child: ComparisonTrayHost(
              child: Stack(
                children: [
                  RefreshIndicator(
                    color: p.ink,
                    backgroundColor: p.surface,
                    onRefresh: () =>
                        ref.read(diamondListProvider.notifier).refresh(),
                    child: CustomScrollView(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            key: _headerKey,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ActiveFilterPills(
                                onEdit: _editFilters,
                                onResetAll: () => ref
                                    .read(diamondListProvider.notifier)
                                    .resetFiltersAndReload(),
                              ),
                              const DiamondListingStatsBar(),
                            ],
                          ),
                        ),
                        LuxePinnedBar(
                          child: Center(
                            child: _Toolbar(
                              onEditFilters: _editFilters,
                              onSwitchViewMode: _switchViewMode,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: DiamondProjectListingActions(),
                        ),
                        ..._content(context),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: LuxeBackToTop(
                      offset: _offset,
                      tooltip: context.tr(DiamondFlowL10n.backToTop),
                      onTap: () => _scroll.animateTo(
                        0,
                        duration: const Duration(milliseconds: 900),
                        curve: LuxeMotion.settle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const DiamondProjectPickBottomBar(),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final stateAsync = ref.watch(diamondListProvider);
    final viewMode = ref.watch(diamondViewModeProvider);
    final grid = viewMode == ViewMode.grid;

    Widget fill(Widget child) =>
        SliverFillRemaining(hasScrollBody: false, child: child);

    final error = stateAsync.whenOrNull(error: (e, _) => e.toString());
    final state = stateAsync.valueOrNull;
    if (error != null) return [fill(_errorView(error))];
    if (state == null || state.isInitialLoading) {
      return [LuxeListingSkeletons(grid: grid, padding: _pad, gap: _gap)];
    }
    if (state.errorMessage != null && state.diamonds.isEmpty) {
      return [fill(_errorView(state.errorMessage!))];
    }
    if (state.diamonds.isEmpty) {
      return [
        fill(
          LuxeStateView(
            icon: Icons.diamond_outlined,
            title: context.tr(DiamondFlowL10n.emptyTitle),
            message: context.tr(DiamondFlowL10n.emptyBody),
            actionLabel: context.tr(DiamondFlowL10n.editFilters),
            onAction: _editFilters,
            secondaryLabel: context.tr(CatalogL10n.resetFilters),
            onSecondary: () =>
                ref.read(diamondListProvider.notifier).resetFiltersAndReload(),
          ),
        ),
      ];
    }

    final showProjectPick = ref.watch(
      authProvider.select((s) => s.isSeller || s.sellerId != null),
    );
    final diamonds = state.diamonds;

    Widget card(int i) {
      final d = diamonds[i];
      void open() => openDiamondDetail(context, d);
      final child = grid
          ? DiamondLuxeGridCard(
              diamond: d,
              showProjectPick: showProjectPick,
              onTap: open,
            )
          : DiamondLuxeListCard(
              diamond: d,
              showProjectPick: showProjectPick,
              onTap: open,
            );
      return LuxeEntranceOnce(
        key: ValueKey('${viewMode.name}-${d.id}'),
        id: '${viewMode.name}-${d.id}',
        seen: _entered,
        index: i,
        child: RepaintBoundary(child: child),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final cell = (width - _pad * 2 - _gap) / 2;
    final extent =
        cell + luxeGridCardTextExtent(MediaQuery.textScalerOf(context));

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(_pad, 6, _pad, 0),
        sliver: grid
            ? SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: _gap,
                  crossAxisSpacing: _gap,
                  mainAxisExtent: extent,
                ),
                itemCount: diamonds.length,
                itemBuilder: (context, i) => card(i),
              )
            : SliverList.separated(
                itemCount: diamonds.length,
                separatorBuilder: (_, _) => const SizedBox(height: _gap),
                itemBuilder: (context, i) => card(i),
              ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
          child: state.isLoadingMore
              ? LuxeLoadingMore(label: context.tr(DiamondFlowL10n.loadingMore))
              : const SizedBox.shrink(),
        ),
      ),
    ];
  }

  Widget _errorView(String message) {
    return LuxeStateView(
      icon: Icons.cloud_off_rounded,
      tone: LuxeTone.error,
      title: context.tr(DiamondFlowL10n.errorTitle),
      message: message,
      actionLabel: context.tr(CatalogL10n.retry),
      onAction: () =>
          ref.read(diamondListProvider.notifier).applyFiltersAndSort(),
      secondaryLabel: context.tr(DiamondFlowL10n.editFilters),
      onSecondary: _editFilters,
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

/// Pinned row: Filters (with count), Sort (current key) and view toggle.
class _Toolbar extends ConsumerWidget {
  const _Toolbar({required this.onEditFilters, required this.onSwitchViewMode});

  final VoidCallback onEditFilters;
  final ValueChanged<ViewMode> onSwitchViewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(diamondViewModeProvider);
    final sorting = ref.watch(diamondSortingProvider);
    final active = ref.watch(
      diamondSearchProvider.select((s) => DiamondFilterSummary.of(s).total),
    );
    final sortLabel = sorting.isEmpty
        ? context.tr(CatalogL10n.defaultSorting)
        : ([...sorting]..sort((a, b) => a.priority.compareTo(b.priority)))
              .first
              .displayName;

    return LuxeListingToolbar(
      filtersLabel: context.tr(DiamondFlowL10n.filters),
      activeFilters: active,
      onFilters: onEditFilters,
      sortLabel: sortLabel,
      sortBadge: sorting.length > 1 ? sorting.length : 0,
      onSort: () => DiamondSortingBottomSheet.show(context),
      viewMode: viewMode == ViewMode.grid
          ? LuxeViewMode.grid
          : LuxeViewMode.list,
      onViewMode: (m) => onSwitchViewMode(
        m == LuxeViewMode.grid ? ViewMode.grid : ViewMode.list,
      ),
      gridLabel: context.tr(DiamondFlowL10n.grid),
      listLabel: context.tr(DiamondFlowL10n.list),
    );
  }
}
