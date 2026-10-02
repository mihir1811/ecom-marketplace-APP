import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../ai_chat/application/ai_pending_filters.dart';
import '../../../comparison/presentation/widgets/comparison_bottom_bar.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_listing_actions.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_pick_bottom_bar.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/diamond_list_provider.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_filter_summary.dart';
import '../widgets/diamond_flow_actions.dart';
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
  static const _listStride = 136.0;

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
        diamondLuxeGridTextExtent(MediaQuery.textScalerOf(context)) +
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
        actions: const [DiamondFlowActions()],
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
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _ToolbarDelegate(
                            background: p.canvas,
                            hairline: p.hairline,
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
                    child: _BackToTop(
                      offset: _offset,
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
      return [_skeletons(context, grid)];
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
      return _EntranceOnce(
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
        cell + diamondLuxeGridTextExtent(MediaQuery.textScalerOf(context));

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
              ? _LoadingMore(grid: grid)
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

  Widget _skeletons(BuildContext context, bool grid) {
    final p = LuxePalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final cell = (width - _pad * 2 - _gap) / 2;
    Widget block(double? w, double h, [double r = 8]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(r),
      ),
    );
    Widget frame(Widget child) => DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      child: child,
    );
    final gridCard = frame(
      Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            block(double.infinity, cell - 10, LuxeSpace.radius - 5),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 12, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(cell * 0.65, 16),
                  const SizedBox(height: 8),
                  block(cell * 0.45, 11),
                  const SizedBox(height: 14),
                  block(cell * 0.5, 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    final listCard = frame(
      Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            block(112, 112, LuxeSpace.radius - 6),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(140, 16),
                  const SizedBox(height: 8),
                  block(100, 11),
                  const SizedBox(height: 20),
                  block(90, 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(_pad, 6, _pad, 24),
      sliver: SliverToBoxAdapter(
        child: LuxeSkeleton(
          child: grid
              ? Wrap(
                  spacing: _gap,
                  runSpacing: _gap,
                  children: [
                    for (var i = 0; i < 4; i++)
                      SizedBox(width: cell, child: gridCard),
                  ],
                )
              : Column(
                  children: [
                    for (var i = 0; i < 5; i++) ...[
                      listCard,
                      const SizedBox(height: _gap),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// "1,284 diamonds" (or "Searching…") under the title, cross-fading.
class _CountLine extends ConsumerWidget {
  const _CountLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final total = ref.watch(
      diamondListProvider.select((v) {
        final s = v.valueOrNull;
        if (s == null || s.isInitialLoading) return null;
        return s.totalCount;
      }),
    );
    final text = total == null
        ? context.tr(DiamondFlowL10n.searching)
        : context.tr(DiamondFlowL10n.resultsCount, {
            'count': formatGroupedWhole(total.toDouble()),
          });
    return AnimatedSwitcher(
      duration: LuxeMotion.medium,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, ?current],
      ),
      child: Text(
        text,
        key: ValueKey(text),
        maxLines: 1,
        style: LuxeType.label(p.inkMuted, size: 12),
      ),
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
    final p = LuxePalette.of(context);
    final summary = ref.watch(
      diamondSearchProvider.select(DiamondFilterSummary.of),
    );
    final shapes = ref.watch(diamondSearchProvider.select((s) => s.shapes));
    if (summary.total == 0) return const SizedBox(height: 6);

    final pills = <Widget>[
      for (final s in DiamondFinderSection.values)
        if (summary.count(s) > 0)
          _Pill(
            label: s == DiamondFinderSection.shape && shapes.length <= 2
                ? shapes.join(', ')
                : '${_label(context, s)} · ${summary.count(s)}',
            onTap: onEdit,
          ),
    ];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        children: [
          for (final pill in pills) ...[pill, const SizedBox(width: 8)],
          TextButton.icon(
            onPressed: () {
              AppHaptics.selection();
              onResetAll();
            },
            style: TextButton.styleFrom(foregroundColor: p.accent),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: Text(
              context.tr(DiamondFlowL10n.reset),
              style: LuxeType.label(p.accent, size: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Material(
      color: p.accentSoft,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(label, style: LuxeType.label(p.ink, size: 12)),
        ),
      ),
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
    final p = LuxePalette.of(context);
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

    Widget pill({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      int badge = 0,
    }) {
      return Material(
        color: p.surface,
        shape: StadiumBorder(side: BorderSide(color: p.hairline)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            AppHaptics.selection();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: p.ink),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(p.ink, size: 12.5),
                  ),
                ),
                if (badge > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    height: 18,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: p.ink,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      '$badge',
                      style: LuxeType.figure(p.canvas, size: 10.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          pill(
            icon: Icons.tune_rounded,
            label: context.tr(DiamondFlowL10n.filters),
            badge: active,
            onTap: onEditFilters,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: pill(
                icon: Icons.swap_vert_rounded,
                label: sortLabel,
                badge: sorting.length > 1 ? sorting.length : 0,
                onTap: () => DiamondSortingBottomSheet.show(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: LuxeSegmented<ViewMode>(
              options: const [ViewMode.grid, ViewMode.list],
              selected: viewMode,
              height: 38,
              dense: true,
              onChanged: onSwitchViewMode,
              labelOf: (m) => context.tr(
                m == ViewMode.grid
                    ? DiamondFlowL10n.grid
                    : DiamondFlowL10n.list,
              ),
              iconOf: (m) => m == ViewMode.grid
                  ? Icons.grid_view_rounded
                  : Icons.view_agenda_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarDelegate extends SliverPersistentHeaderDelegate {
  _ToolbarDelegate({
    required this.child,
    required this.background,
    required this.hairline,
  });

  final Widget child;
  final Color background;
  final Color hairline;

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background.withValues(alpha: 0.9),
            border: Border(
              bottom: BorderSide(
                color: overlaps ? hairline : Colors.transparent,
                width: 0.6,
              ),
            ),
          ),
          child: SizedBox.expand(child: Center(child: child)),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_ToolbarDelegate old) =>
      old.child != child || old.background != background;
}

/// Plays a short fade-up the first time a card is shown (first ~10 only),
/// never again when it is scrolled back into view.
class _EntranceOnce extends StatefulWidget {
  const _EntranceOnce({
    required this.id,
    required this.seen,
    required this.index,
    required this.child,
    super.key,
  });

  final String id;
  final Set<String> seen;
  final int index;
  final Widget child;

  @override
  State<_EntranceOnce> createState() => _EntranceOnceState();
}

class _EntranceOnceState extends State<_EntranceOnce> {
  late final bool _animate = widget.index < 10 && widget.seen.add(widget.id);

  @override
  Widget build(BuildContext context) {
    if (!_animate || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return widget.child
        .animate(delay: (widget.index * 55).ms)
        .fadeIn(duration: 420.ms)
        .moveY(begin: 18, end: 0, duration: 650.ms, curve: LuxeMotion.settle);
  }
}

class _LoadingMore extends StatelessWidget {
  const _LoadingMore({required this.grid});

  final bool grid;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 1.8, color: p.accent),
        ),
        const SizedBox(width: 12),
        Text(
          context.tr(DiamondFlowL10n.loadingMore),
          style: LuxeType.label(p.inkMuted, size: 12.5),
        ),
      ],
    );
  }
}

class _BackToTop extends StatelessWidget {
  const _BackToTop({required this.offset, required this.onTap});

  final ValueNotifier<double> offset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: offset,
      builder: (context, value, _) {
        final show = value > 1400;
        return AnimatedSlide(
          offset: show ? Offset.zero : const Offset(0, 1.6),
          duration: LuxeMotion.medium,
          curve: LuxeMotion.settle,
          child: AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: LuxeMotion.fast,
            child: IgnorePointer(
              ignoring: !show,
              child: LuxeIconButton(
                icon: Icons.arrow_upward_rounded,
                tooltip: context.tr(DiamondFlowL10n.backToTop),
                onPressed: onTap,
                size: 48,
              ),
            ),
          ),
        );
      },
    );
  }
}
