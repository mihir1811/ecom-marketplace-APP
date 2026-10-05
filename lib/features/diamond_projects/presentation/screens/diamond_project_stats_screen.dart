import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_view.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../application/diamond_project_save_provider.dart';
import '../../application/diamond_project_selection_provider.dart';
import '../../domain/models/diamond_project_stats.dart';
import '../widgets/diamond_project_histogram_card.dart';
import '../widgets/diamond_project_kpi_grid.dart';
import '../widgets/diamond_project_mix_card.dart';
import '../widgets/diamond_project_price_stats_card.dart';
import '../widgets/diamond_project_scatter_card.dart';
import '../widgets/diamond_project_selected_table.dart';

enum _ProjectTab { overview, mix, spread, stones }

/// Local analytics dashboard for the current diamond selection.
///
/// A dark hero carries the headline numbers; the sticky tab bar splits the
/// analytics (overview, mix, spread) from the stone list so every chart is
/// one tap away without one long scroll.
class DiamondProjectStatsScreen extends ConsumerStatefulWidget {
  const DiamondProjectStatsScreen({super.key});

  @override
  ConsumerState<DiamondProjectStatsScreen> createState() =>
      _DiamondProjectStatsScreenState();
}

class _DiamondProjectStatsScreenState
    extends ConsumerState<DiamondProjectStatsScreen> {
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);
  _ProjectTab _tab = _ProjectTab.overview;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.offset);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    final selection = ref.watch(diamondProjectSelectionProvider);
    final stats = ref.watch(diamondProjectStatsProvider);
    final saving = ref.watch(diamondProjectSaveProvider).isLoading;

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        eyebrow: context.tr(ExperienceL10n.projectEyebrow),
        title: selection.isEmpty
            ? context.tr(CatalogL10n.diamondProject)
            : selection.name,
        scrollOffset: _offset,
        actions: [
          LuxeIconButton(
            icon: Icons.folder_open_outlined,
            tooltip: context.tr(CatalogL10n.savedStatistics),
            size: 40,
            onPressed: () => context.push(AppRouteNames.savedDiamondProjects),
          ),
          const SizedBox(width: 8),
          LuxeIconButton(
            icon: Icons.bookmark_add_outlined,
            tooltip: context.tr(CatalogL10n.saveNow),
            size: 40,
            loading: saving,
            onPressed: saving || selection.isEmpty ? null : _save,
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: context.tr(CatalogL10n.projectActions),
            icon: Icon(Icons.more_vert_rounded, color: p.ink),
            onSelected: (value) {
              switch (value) {
                case 'saved':
                  context.push(AppRouteNames.savedDiamondProjects);
                case 'clear':
                  AppHaptics.warning();
                  ref.read(diamondProjectSelectionProvider.notifier).clear();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'saved',
                child: Text(context.tr(CatalogL10n.savedStatistics)),
              ),
              PopupMenuItem(
                value: 'clear',
                enabled: !selection.isEmpty,
                child: Text(
                  context.tr(CatalogL10n.clearSelection),
                  style: TextStyle(color: p.caution),
                ),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: LuxeMotion.medium,
        child: selection.isEmpty
            ? LuxeStateView(
                key: const ValueKey('empty'),
                icon: Icons.analytics_outlined,
                title: context.tr(CatalogL10n.noDiamondsSelected),
                message: context.tr(CatalogL10n.selectPageHelp),
                actionLabel: context.tr(CatalogL10n.backToListings),
                onAction: () => context.goBack(),
                secondaryLabel: context.tr(CatalogL10n.savedStatistics),
                onSecondary: () =>
                    context.push(AppRouteNames.savedDiamondProjects),
              )
            : CustomScrollView(
                key: const ValueKey('content'),
                controller: _scroll,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: _reveal(
                        _ProjectHero(
                          name: selection.name,
                          projectId: selection.projectId,
                          stats: stats,
                        ),
                        0,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    sliver: SliverToBoxAdapter(
                      child: _reveal(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 10,
                              ),
                              child: Text(
                                context
                                    .tr(ExperienceL10n.projectAverages)
                                    .toUpperCase(),
                                style: LuxeType.eyebrow(
                                  p.inkMuted,
                                ).copyWith(fontSize: 10),
                              ),
                            ),
                            DiamondProjectKpiGrid(stats: stats),
                          ],
                        ),
                        1,
                      ),
                    ),
                  ),
                  LuxePinnedBar(
                    extent: 64,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: LuxeSegmented<_ProjectTab>(
                          options: _ProjectTab.values,
                          selected: _tab,
                          dense: true,
                          labelOf: (t) => switch (t) {
                            _ProjectTab.overview => context.tr(
                              ExperienceL10n.tabOverview,
                            ),
                            _ProjectTab.mix => context.tr(
                              ExperienceL10n.tabMix,
                            ),
                            _ProjectTab.spread => context.tr(
                              ExperienceL10n.tabDistribution,
                            ),
                            _ProjectTab.stones =>
                              '${context.tr(ExperienceL10n.tabStones)} · '
                                  '${selection.items.length}',
                          },
                          onChanged: (t) => setState(() => _tab = t),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
                    sliver: SliverToBoxAdapter(
                      child: AnimatedSwitcher(
                        duration: LuxeMotion.medium,
                        switchInCurve: LuxeMotion.settle,
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.025),
                              end: Offset.zero,
                            ).animate(a),
                            child: child,
                          ),
                        ),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            ...previous.map(
                              (w) => IgnorePointer(
                                child: Opacity(opacity: 0, child: w),
                              ),
                            ),
                            ?current,
                          ],
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(_tab),
                          child: _tabContent(context, stats, selection),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _reveal(Widget child, int index) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return child
        .animate()
        .fadeIn(delay: (80 * index).ms, duration: 420.ms)
        .moveY(
          begin: 18,
          end: 0,
          delay: (80 * index).ms,
          duration: 700.ms,
          curve: LuxeMotion.settle,
        );
  }

  Widget _tabContent(
    BuildContext context,
    DiamondProjectStats stats,
    DiamondProjectSelection selection,
  ) {
    final p = LuxePalette.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 720;
    Widget hint() => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(Icons.touch_app_outlined, size: 13, color: p.inkFaint),
          const SizedBox(width: 6),
          Text(
            context.tr(ExperienceL10n.projectTapHint),
            style: LuxeType.label(p.inkFaint, size: 11.5),
          ),
        ],
      ),
    );
    Widget grid(List<Widget> cards) {
      if (!wide) {
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              cards[i],
            ],
          ],
        );
      }
      return Column(
        children: [
          for (var i = 0; i < cards.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[i]),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < cards.length
                      ? cards[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      );
    }

    switch (_tab) {
      case _ProjectTab.overview:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hint(),
            grid([
              DiamondProjectPriceStatsCard(stats: stats),
              DiamondProjectScatterCard(stats: stats),
            ]),
          ],
        );
      case _ProjectTab.mix:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hint(),
            grid([
              DiamondProjectMixCard(
                title: context.tr(CatalogL10n.shapeMix),
                entries: stats.shapeMix,
              ),
              DiamondProjectMixCard(
                title: context.tr(CatalogL10n.colorMix),
                entries: stats.colorMix,
              ),
              DiamondProjectMixCard(
                title: context.tr(CatalogL10n.clarityMix),
                entries: stats.clarityMix,
              ),
            ]),
          ],
        );
      case _ProjectTab.spread:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hint(),
            grid([
              DiamondProjectHistogramCard(
                title: context.tr(CatalogL10n.priceDistribution),
                entries: stats.priceBuckets,
              ),
              DiamondProjectHistogramCard(
                title: context.tr(CatalogL10n.pricePerCaratDistribution),
                entries: stats.ppcBuckets,
              ),
              DiamondProjectHistogramCard(
                title: context.tr(CatalogL10n.caratDistribution),
                entries: stats.caratBuckets,
              ),
            ]),
          ],
        );
      case _ProjectTab.stones:
        return DiamondProjectSelectedTable(
          items: selection.items,
          onRemove: (id) {
            ref.read(diamondProjectSelectionProvider.notifier).removeItem(id);
          },
        );
    }
  }

  Future<void> _save() async {
    AppHaptics.medium();
    final result = await ref.read(diamondProjectSaveProvider.notifier).save();
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        showLuxeToast(
          context,
          context.tr(CatalogL10n.savedProject, {'name': value.name}),
          tone: LuxeTone.success,
          actionLabel: context.tr(CatalogL10n.savedStatistics),
          onAction: () => context.push(AppRouteNames.savedDiamondProjects),
        );
      case ResultFailure(:final failure):
        showLuxeToast(context, failure.message, tone: LuxeTone.error);
    }
  }
}

/// Dark stage with the project's name, status, headline totals and a live
/// stone in the selection's dominant cut (drag to turn, tap to flash).
class _ProjectHero extends StatelessWidget {
  const _ProjectHero({
    required this.name,
    required this.projectId,
    required this.stats,
  });

  final String name;
  final String? projectId;
  final DiamondProjectStats stats;

  static GemCut cutFor(String? shape) {
    final s = (shape ?? '').toLowerCase();
    for (final cut in GemCut.values) {
      if (s.contains(cut.name)) return cut;
    }
    if (s.contains('square')) return GemCut.princess;
    if (s.contains('rect')) return GemCut.emerald;
    return GemCut.round;
  }

  @override
  Widget build(BuildContext context) {
    final id = projectId;
    final saved = id != null && id.isNotEmpty;
    final status = saved
        ? 'ID ${id.length > 8 ? id.substring(0, 8) : id}…'
        : context.tr(CatalogL10n.projectUnsaved);
    final dominant = stats.shapeMix.isEmpty ? null : stats.shapeMix.first.label;

    Widget figure(String value, String label) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: LuxeType.figure(
            LuxeStage.ink,
            size: 17,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LuxeType.label(LuxeStage.inkMuted, size: 11),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const RadialGradient(
          center: Alignment(0.75, -0.4),
          radius: 1.2,
          colors: [Color(0xFF24222A), LuxeStage.obsidian],
        ),
        border: Border.all(color: LuxeStage.glassBorder),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: saved
                            ? const Color(0x267BC8A0)
                            : LuxeStage.glass,
                        shape: const StadiumBorder(
                          side: BorderSide(color: LuxeStage.glassBorder),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            saved
                                ? Icons.cloud_done_outlined
                                : Icons.cloud_off_outlined,
                            size: 12,
                            color: saved
                                ? const Color(0xFF7BC8A0)
                                : LuxeStage.inkMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            status,
                            style: LuxeType.label(LuxeStage.ink, size: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.display(28, LuxeStage.ink),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr(ExperienceL10n.projectValue).toUpperCase(),
                      style: LuxeType.eyebrow(
                        LuxeStage.gold,
                      ).copyWith(fontSize: 9.5),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppCurrency.usd(stats.totalPrice, decimals: 0),
                        style: LuxeType.display(36, LuxeStage.gold),
                      ),
                    ),
                  ],
                ),
              ),
              GemView(
                size: 118,
                cut: cutFor(dominant),
                interactive: true,
                semanticLabel: dominant,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 0.6, color: LuxeStage.glassBorder),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: figure(
                  '${stats.stones}',
                  context.tr(CatalogL10n.projectStonesKpi),
                ),
              ),
              Expanded(
                child: figure(
                  '${stats.totalCarat.toStringAsFixed(2)} ct',
                  context.tr(CatalogL10n.projectTotalCaratKpi),
                ),
              ),
              Expanded(
                child: figure(
                  dominant ?? '—',
                  context.tr(CatalogL10n.shapeMix),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
