import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_view.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../domain/models/diamond_project_item.dart';
import '../../domain/models/diamond_project_stats.dart';
import 'diamond_project_histogram_card.dart';
import 'diamond_project_kpi_grid.dart';
import 'diamond_project_mix_card.dart';
import 'diamond_project_price_stats_card.dart';
import 'diamond_project_scatter_card.dart';
import 'diamond_project_selected_table.dart';

/// Tabs of a diamond project: analytics split from the stone list.
enum DiamondProjectTab { overview, mix, spread, stones }

/// Dark stage with the project's name, status, headline totals and a live
/// stone in the selection's dominant cut (drag to turn, tap to flash).
///
/// Shared by the diamond project screen and the seller dashboard panel.
class DiamondProjectHero extends StatelessWidget {
  const DiamondProjectHero({
    required this.name,
    required this.status,
    required this.stats,
    this.statusIcon,
    this.highlighted = false,
    this.compact = false,
    super.key,
  });

  /// Tighter padding and type for embedding inside another card
  /// (seller dashboard); the standalone project screen uses the roomy size.
  final bool compact;

  final String name;
  final String status;
  final IconData? statusIcon;

  /// Green status pill (e.g. saved / live) instead of the neutral glass one.
  final bool highlighted;
  final DiamondProjectStats stats;

  /// `$1,234,567` — grouped so large inventory values stay readable.
  static String _money(num amount) {
    final digits = amount.round().abs().toString();
    final out = StringBuffer(amount < 0 ? '-\$' : '\$');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

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
    final dominant = stats.shapeMix.isEmpty ? null : stats.shapeMix.first.label;

    Widget figure(String value, String label) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shrinks instead of truncating, so figures are never cut off.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: LuxeType.figure(
              LuxeStage.ink,
              size: compact ? 15 : 17,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
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
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        gradient: RadialGradient(
          center: Alignment(0.75, -0.4),
          radius: 1.2,
          colors: [LuxeStage.raised, LuxeStage.obsidian],
        ),
        border: Border.all(color: LuxeStage.glassBorder),
      ),
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 14, 8, 14)
          : const EdgeInsets.fromLTRB(20, 18, 12, 20),
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
                        color: highlighted
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
                            statusIcon ??
                                (highlighted
                                    ? Icons.cloud_done_outlined
                                    : Icons.cloud_off_outlined),
                            size: 12,
                            color: highlighted
                                ? const Color(0xFF7BC8A0)
                                : LuxeStage.inkMuted,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LuxeType.label(LuxeStage.ink, size: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 14),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.display(compact ? 22 : 28, LuxeStage.ink),
                    ),
                    SizedBox(height: compact ? 12 : 16),
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
                        _money(stats.totalPrice),
                        style: LuxeType.display(
                          compact ? 30 : 36,
                          LuxeStage.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GemView(
                size: compact ? 88 : 118,
                cut: cutFor(dominant),
                interactive: true,
                semanticLabel: dominant,
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 18),
          Container(height: 0.6, color: LuxeStage.glassBorder),
          SizedBox(height: compact ? 10 : 14),
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

/// "Averages" eyebrow over the KPI grid.
class DiamondProjectAverages extends StatelessWidget {
  const DiamondProjectAverages({required this.stats, super.key});

  final DiamondProjectStats stats;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            context.tr(ExperienceL10n.projectAverages).toUpperCase(),
            style: LuxeType.eyebrow(p.inkMuted).copyWith(fontSize: 10),
          ),
        ),
        DiamondProjectKpiGrid(stats: stats),
      ],
    );
  }
}

/// Overview · Mix · Spread · Stones segmented control.
class DiamondProjectTabBar extends StatelessWidget {
  const DiamondProjectTabBar({
    required this.selected,
    required this.stoneCount,
    required this.onChanged,
    super.key,
  });

  final DiamondProjectTab selected;
  final int stoneCount;
  final ValueChanged<DiamondProjectTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return LuxeSegmented<DiamondProjectTab>(
      options: DiamondProjectTab.values,
      selected: selected,
      dense: true,
      labelOf: (t) => switch (t) {
        DiamondProjectTab.overview => context.tr(ExperienceL10n.tabOverview),
        DiamondProjectTab.mix => context.tr(ExperienceL10n.tabMix),
        DiamondProjectTab.spread => context.tr(ExperienceL10n.tabDistribution),
        DiamondProjectTab.stones =>
          '${context.tr(ExperienceL10n.tabStones)} · $stoneCount',
      },
      onChanged: onChanged,
    );
  }
}

/// Content of the selected [DiamondProjectTab], cross-fading on change.
class DiamondProjectTabView extends StatelessWidget {
  const DiamondProjectTabView({
    required this.tab,
    required this.stats,
    required this.items,
    required this.onRemove,
    super.key,
  });

  final DiamondProjectTab tab;
  final DiamondProjectStats stats;
  final List<DiamondProjectItem> items;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
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
            (w) => IgnorePointer(child: Opacity(opacity: 0, child: w)),
          ),
          ?current,
        ],
      ),
      child: KeyedSubtree(key: ValueKey(tab), child: _content(context)),
    );
  }

  Widget _content(BuildContext context) {
    final p = LuxePalette.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 720;
    Widget hint() => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(Icons.touch_app_outlined, size: 13, color: p.inkFaint),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              context.tr(ExperienceL10n.projectTapHint),
              style: LuxeType.label(p.inkFaint, size: 11.5),
            ),
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

    switch (tab) {
      case DiamondProjectTab.overview:
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
      case DiamondProjectTab.mix:
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
      case DiamondProjectTab.spread:
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
      case DiamondProjectTab.stones:
        return DiamondProjectSelectedTable(items: items, onRemove: onRemove);
    }
  }
}
