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
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../catalog_flow/presentation/widgets/catalog_flow_actions.dart';
import '../../../comparison/presentation/widgets/comparison_bottom_bar.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/gemstone_list_provider.dart';
import '../../application/gemstone_search_provider.dart';
import '../../domain/models/gemstone_filter_summary.dart';
import '../../domain/models/gemstone_sort_option.dart';
import '../widgets/gemstone_luxe_cards.dart';

/// Gemstone results, built from the same luxe listing pieces as diamonds.
///
/// Active-filter pills scroll away; the filter / sort / view toolbar stays
/// pinned. Cards enter with a short stagger on first load, skeletons cover
/// loading, and empty / error states offer the next step.
class GemstoneListingsScreen extends ConsumerStatefulWidget {
  const GemstoneListingsScreen({super.key});

  @override
  ConsumerState<GemstoneListingsScreen> createState() =>
      _GemstoneListingsScreenState();
}

class _GemstoneListingsScreenState
    extends ConsumerState<GemstoneListingsScreen> {
  static const _gap = 12.0;
  static const _pad = 16.0;
  static const _listStride = LuxeProductListCard.thumbSize + 12 + _gap;

  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);
  final _headerKey = GlobalKey();
  final _entered = <String>{};

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
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

    final listState = ref.read(gemstoneListProvider).valueOrNull;
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
      ref.read(gemstoneListProvider.notifier).loadNextPage();
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

  /// Switches layout while keeping the first visible stone in view.
  void _switchViewMode(LuxeViewMode next) {
    final current = ref.read(gemstoneViewModeProvider);
    final nextMode = next == LuxeViewMode.grid
        ? GemstoneViewMode.grid
        : GemstoneViewMode.list;
    if (current == nextMode) return;
    final count =
        ref.read(gemstoneListProvider).valueOrNull?.gemstones.length ?? 0;
    final into = (_scroll.hasClients ? _scroll.offset : 0) - _headerExtent;
    final index = count == 0 || into <= 0
        ? 0
        : (current == GemstoneViewMode.grid
                  ? (into / _gridStride(context)).floor() * 2
                  : (into / _listStride).floor())
              .clamp(0, count - 1);
    ref.read(gemstoneViewModeProvider.notifier).state = nextMode;
    if (index == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target =
          _headerExtent +
          (nextMode == GemstoneViewMode.grid
              ? (index ~/ 2) * _gridStride(context)
              : index * _listStride);
      _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
    });
  }

  void _editFilters() => context.resetTo(AppRouteNames.gemstones);

  Future<void> _resetFilters() async {
    ref.read(gemstoneSearchProvider.notifier).reset();
    await ref.read(gemstoneListProvider.notifier).applyFiltersAndReload();
  }

  Future<void> _openSort(BuildContext context) async {
    final selected = await showLuxeChoiceSheet<GemstoneSortOption>(
      context,
      title: context.tr(GemstoneFlowL10n.sortTitle),
      options: GemstoneSortOption.values,
      current: ref.read(gemstoneSortProvider),
      labelOf: (o) => o.label,
    );
    if (selected != null && mounted) {
      ref.read(gemstoneSortProvider.notifier).state = selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: context.tr(RemainingL10n.gemstones),
        subtitle: const _CountLine(),
        scrollOffset: _offset,
        actions: const [CatalogFlowActions()],
      ),
      body: ComparisonTrayHost(
        child: Stack(
          children: [
            RefreshIndicator(
              color: p.ink,
              backgroundColor: p.surface,
              onRefresh: () =>
                  ref.read(gemstoneListProvider.notifier).refresh(),
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: _headerKey,
                      child: _ActiveFilterPills(
                        onEdit: _editFilters,
                        onResetAll: _resetFilters,
                      ),
                    ),
                  ),
                  LuxePinnedBar(
                    child: Center(
                      child: _Toolbar(
                        onEditFilters: _editFilters,
                        onSort: () => _openSort(context),
                        onSwitchViewMode: _switchViewMode,
                      ),
                    ),
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
    );
  }

  List<Widget> _content(BuildContext context) {
    final stateAsync = ref.watch(gemstoneListProvider);
    final viewMode = ref.watch(gemstoneViewModeProvider);
    final grid = viewMode == GemstoneViewMode.grid;

    Widget fill(Widget child) =>
        SliverFillRemaining(hasScrollBody: false, child: child);

    final error = stateAsync.whenOrNull(error: (e, _) => e.toString());
    final state = stateAsync.valueOrNull;
    if (error != null) return [fill(_errorView(error))];
    if (state == null || state.isInitialLoading) {
      return [LuxeListingSkeletons(grid: grid, padding: _pad, gap: _gap)];
    }
    if (state.errorMessage != null && state.gemstones.isEmpty) {
      return [fill(_errorView(state.errorMessage!))];
    }
    if (state.gemstones.isEmpty) {
      return [
        fill(
          LuxeStateView(
            icon: Icons.auto_awesome_outlined,
            title: context.tr(GemstoneFlowL10n.emptyTitle),
            message: context.tr(DiamondFlowL10n.emptyBody),
            actionLabel: context.tr(DiamondFlowL10n.editFilters),
            onAction: _editFilters,
            secondaryLabel: context.tr(CatalogL10n.resetFilters),
            onSecondary: _resetFilters,
          ),
        ),
      ];
    }

    final gemstones = state.gemstones;

    Widget card(int i) {
      final g = gemstones[i];
      void open() => openGemstoneDetail(context, g);
      final child = grid
          ? GemstoneLuxeGridCard(gemstone: g, onTap: open)
          : GemstoneLuxeListCard(gemstone: g, onTap: open);
      return LuxeEntranceOnce(
        key: ValueKey('${viewMode.name}-${g.id}'),
        id: '${viewMode.name}-${g.id}',
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
                itemCount: gemstones.length,
                itemBuilder: (context, i) => card(i),
              )
            : SliverList.separated(
                itemCount: gemstones.length,
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
      title: context.tr(GemstoneFlowL10n.errorTitle),
      message: message,
      actionLabel: context.tr(CatalogL10n.retry),
      onAction: () =>
          ref.read(gemstoneListProvider.notifier).applyFiltersAndReload(),
      secondaryLabel: context.tr(DiamondFlowL10n.editFilters),
      onSecondary: _editFilters,
    );
  }
}

/// "1,284 gemstones" (or "Searching…") under the title, cross-fading.
class _CountLine extends ConsumerWidget {
  const _CountLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(
      gemstoneListProvider.select((v) {
        final s = v.valueOrNull;
        if (s == null || s.isInitialLoading) return null;
        return s.totalCount;
      }),
    );
    return LuxeCountLine(
      text: total == null
          ? context.tr(DiamondFlowL10n.searching)
          : context.tr(GemstoneFlowL10n.resultsCount, {
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
    GemstoneFinderSection s,
  ) => context.tr(switch (s) {
    GemstoneFinderSection.gemType => GemstoneFlowL10n.sectionGemType,
    GemstoneFinderSection.shape => DiamondFlowL10n.sectionShape,
    GemstoneFinderSection.sizePrice => DiamondFlowL10n.sectionSizePrice,
    GemstoneFinderSection.colorQuality => GemstoneFlowL10n.sectionColorQuality,
    GemstoneFinderSection.grading => GemstoneFlowL10n.sectionGrading,
    GemstoneFinderSection.listing => DiamondFlowL10n.sectionListing,
    GemstoneFinderSection.seller => DiamondFlowL10n.sectionSeller,
    GemstoneFinderSection.measurements => DiamondFlowL10n.sectionMeasurements,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(
      gemstoneSearchProvider.select(GemstoneFilterSummary.of),
    );
    final types = ref.watch(
      gemstoneSearchProvider.select((s) => s.selectedGemstoneTypes),
    );
    final typeOnly =
        summary.count(GemstoneFinderSection.gemType) == types.length;
    return LuxeActiveFilterPills(
      labels: [
        for (final s in GemstoneFinderSection.values)
          if (summary.count(s) > 0)
            s == GemstoneFinderSection.gemType && typeOnly && types.length <= 2
                ? types.join(', ')
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
  const _Toolbar({
    required this.onEditFilters,
    required this.onSort,
    required this.onSwitchViewMode,
  });

  final VoidCallback onEditFilters;
  final VoidCallback onSort;
  final ValueChanged<LuxeViewMode> onSwitchViewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(gemstoneViewModeProvider);
    final sort = ref.watch(gemstoneSortProvider);
    final active = ref.watch(
      gemstoneSearchProvider.select((s) => GemstoneFilterSummary.of(s).total),
    );
    return LuxeListingToolbar(
      filtersLabel: context.tr(DiamondFlowL10n.filters),
      activeFilters: active,
      onFilters: onEditFilters,
      sortLabel: sort.shortLabel,
      onSort: onSort,
      viewMode: viewMode == GemstoneViewMode.grid
          ? LuxeViewMode.grid
          : LuxeViewMode.list,
      onViewMode: onSwitchViewMode,
      gridLabel: context.tr(DiamondFlowL10n.grid),
      listLabel: context.tr(DiamondFlowL10n.list),
    );
  }
}
