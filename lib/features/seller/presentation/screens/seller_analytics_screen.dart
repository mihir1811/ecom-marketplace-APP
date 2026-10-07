import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../application/seller_insights_provider.dart';
import '../../domain/models/seller_insights.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_studio.dart';
import '../atelier/atelier_theme.dart';

/// Seller analytics: headline revenue, period KPIs with change, revenue
/// trend, category mix, order pipeline and catalogue engagement.
class SellerAnalyticsScreen extends ConsumerStatefulWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  ConsumerState<SellerAnalyticsScreen> createState() =>
      _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends ConsumerState<SellerAnalyticsScreen> {
  AnalyticsRange _range = AnalyticsRange.last30;

  String _rangeLabel(AnalyticsRange r) => switch (r) {
    AnalyticsRange.last7 => context.tr(RemainingL10n.last7Days),
    AnalyticsRange.last30 => context.tr(RemainingL10n.last30Days),
    AnalyticsRange.last90 => context.tr(RemainingL10n.last90Days),
    AnalyticsRange.year => context.tr(RemainingL10n.thisYear),
  };

  static String _rangeShort(AnalyticsRange r) => switch (r) {
    AnalyticsRange.last7 => '7D',
    AnalyticsRange.last30 => '30D',
    AnalyticsRange.last90 => '90D',
    AnalyticsRange.year => 'YTD',
  };

  Future<void> _refresh() =>
      ref.read(sellerAnalyticsProvider(_range).notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final state = ref.watch(sellerAnalyticsProvider(_range));
    final snapshot = state.snapshot;
    final headline = snapshot?.kpis.firstOrNull;

    return AtelierPage(
      onRefresh: _refresh,
      children: [
        AtelierHero(
          overline: 'Performance',
          title: context.tr(RemainingL10n.analytics),
          subtitle: context.tr(
            RemainingL10n.performanceInsightsAcrossSalesOrdersAndTraffic,
          ),
          cut: GemCut.radiant,
          footer: _HeroHeadline(
            label:
                '${headline?.title ?? context.tr(RemainingL10n.revenue)}'
                ' · ${_rangeLabel(_range)}',
            kpi: headline,
            loading: snapshot == null && state.errorMessage == null,
          ),
        ),
        const SizedBox(height: AtelierSpace.s24),
        Reveal(
          index: 2,
          child: Row(
            children: [
              Expanded(
                child: AtelierSegmented<AnalyticsRange>(
                  expand: true,
                  segments: [
                    for (final r in AnalyticsRange.values)
                      AtelierSegment(value: r, label: _rangeShort(r)),
                  ],
                  selected: _range,
                  onChanged: (r) => setState(() => _range = r),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: AtelierMotion.base,
                child: state.isLoading && snapshot != null
                    ? SizedBox(
                        key: const ValueKey('busy'),
                        width: 40,
                        height: 40,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: p.gold,
                            ),
                          ),
                        ),
                      )
                    : AtelierIconButton(
                        key: const ValueKey('idle'),
                        icon: Icons.refresh_rounded,
                        tooltip: context.tr(RemainingL10n.refresh),
                        filled: true,
                        onPressed: _refresh,
                      ),
              ),
            ],
          ),
        ),
        if (snapshot != null) ...[
          const SizedBox(height: 8),
          Text(
            '${_rangeLabel(_range)} · updated ${_time(snapshot.fetchedAt)}',
            style: AtelierType.caption(p.muted, size: 11.5),
          ),
        ],
        if (state.errorMessage != null && snapshot != null) ...[
          const SizedBox(height: AtelierSpace.s12),
          AtelierNotice(
            text: state.errorMessage!,
            tone: AtelierTone.ruby,
            icon: Icons.error_outline_rounded,
            actionLabel: context.tr(RemainingL10n.retry),
            onAction: _refresh,
          ),
        ],
        const SizedBox(height: AtelierSpace.s20),
        AnimatedSwitcher(
          duration: AtelierMotion.slow,
          switchInCurve: AtelierMotion.emphasized,
          child: KeyedSubtree(
            key: ValueKey('$_range-${snapshot == null}'),
            child: _body(context, state, snapshot),
          ),
        ),
      ],
    );
  }

  static String _time(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }

  Widget _body(
    BuildContext context,
    SellerAnalyticsState state,
    SellerAnalyticsSnapshot? snapshot,
  ) {
    if (snapshot == null && state.errorMessage != null) {
      return AtelierErrorState(
        title: 'Analytics unavailable',
        message: state.errorMessage!,
        onRetry: _refresh,
      );
    }
    if (snapshot == null) return const _AnalyticsSkeleton();

    final p = context.atelier;
    final kpis = snapshot.kpis.skip(1).toList();
    final series = snapshot.revenueSeries;
    final hasRevenue = series.values.any((v) => v > 0);

    final category = AtelierPanel(
      overline: 'Mix',
      title: context.tr(RemainingL10n.salesByCategory),
      subtitle: context.tr(RemainingL10n.revenueSharePerCatalog),
      child: snapshot.categorySlices.isEmpty
          ? AtelierEmptyState(
              compact: true,
              icon: Icons.donut_large_rounded,
              title: 'No category data',
              message: context.tr(RemainingL10n.noCategorySales),
            )
          : AtelierDonut(
              centerCaption: context.tr(RemainingL10n.ofRevenue),
              slices: [
                for (var i = 0; i < snapshot.categorySlices.length; i++)
                  AtelierSlice(
                    label: snapshot.categorySlices[i].label,
                    value: snapshot.categorySlices[i].value,
                    color: _sliceColor(p, i),
                  ),
              ],
            ),
    );
    final pipeline = AtelierPanel(
      overline: 'Pipeline',
      title: context.tr(RemainingL10n.orderStatus),
      subtitle: context.tr(RemainingL10n.currentPipelineBreakdown),
      child: snapshot.orderStatus.isEmpty
          ? AtelierEmptyState(
              compact: true,
              icon: Icons.stacked_bar_chart_rounded,
              title: 'No orders to break down',
              message: context.tr(RemainingL10n.noOrdersPeriod),
            )
          : _StatusBars(rows: snapshot.orderStatus),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kpis.isNotEmpty)
          AtelierTileGrid(
            columns: 3,
            minTileWidth: 160,
            children: [
              for (final k in kpis)
                AtelierStatTile(
                  label: k.title,
                  value: k.value,
                  icon: _kpiIcon(k.title),
                  caption: 'vs previous period',
                  trailing: k.delta.isEmpty
                      ? null
                      : AtelierDelta(label: k.delta, up: k.deltaUp),
                ),
            ],
          ),
        const SizedBox(height: AtelierSpace.s20),
        Reveal(
          index: 3,
          child: AtelierPanel(
            overline: 'Trend',
            title: context.tr(RemainingL10n.revenueTrend),
            subtitle: context.tr(RemainingL10n.grossRevenueOverTime),
            trailing: hasRevenue
                ? Text(
                    'Drag to explore',
                    style: AtelierType.caption(p.muted, size: 11),
                  )
                : null,
            child: !hasRevenue
                ? AtelierEmptyState(
                    compact: true,
                    icon: Icons.show_chart_rounded,
                    title: 'No revenue yet',
                    message: context.tr(RemainingL10n.noRevenuePeriod),
                  )
                : AtelierLineChart(
                    values: series.values,
                    labels: series.labels,
                    detailAt: series.detailAt,
                    formatValue: (v) => AppCurrency.usd(v),
                  ),
          ),
        ),
        const SizedBox(height: AtelierSpace.s20),
        Reveal(
          index: 4,
          child: LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    category,
                    const SizedBox(height: AtelierSpace.s20),
                    pipeline,
                  ],
                );
              }
              // Panels contain LayoutBuilders, so no IntrinsicHeight here.
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: category),
                  const SizedBox(width: AtelierSpace.s20),
                  Expanded(child: pipeline),
                ],
              );
            },
          ),
        ),
        if (snapshot.engagement.isNotEmpty) ...[
          const SizedBox(height: AtelierSpace.s32),
          AtelierSectionHeader(
            overline: 'Catalogue',
            title: context.tr(RemainingL10n.engagementMetrics),
            subtitle: context.tr(
              RemainingL10n.listingInterestAndCatalogPerformance,
            ),
          ),
          const SizedBox(height: AtelierSpace.s16),
          AtelierTileGrid(
            columns: 4,
            minTileWidth: 150,
            children: [
              for (final m in snapshot.engagement)
                AtelierStatTile(
                  label: m.label,
                  value: m.value,
                  caption: m.hint,
                  icon: _engagementIcon(m.label),
                  tone: _engagementTone(m.label),
                ),
            ],
          ),
        ],
      ],
    );
  }

  static IconData _kpiIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('order value')) return Icons.payments_outlined;
    if (t.contains('order')) return Icons.receipt_long_outlined;
    if (t.contains('unit')) return Icons.inventory_2_outlined;
    if (t.contains('revenue')) return Icons.attach_money_rounded;
    return Icons.insights_outlined;
  }

  static IconData _engagementIcon(String label) {
    final t = label.toLowerCase();
    if (t.contains('refund')) return Icons.replay_rounded;
    if (t.contains('live')) return Icons.storefront_outlined;
    if (t.contains('sold')) return Icons.sell_outlined;
    if (t.contains('unit')) return Icons.inventory_2_outlined;
    if (t.contains('rate')) return Icons.percent_rounded;
    return Icons.insights_outlined;
  }

  static AtelierTone _engagementTone(String label) {
    final t = label.toLowerCase();
    if (t.contains('refund')) return AtelierTone.ruby;
    if (t.contains('live')) return AtelierTone.emerald;
    if (t.contains('sold')) return AtelierTone.sapphire;
    return AtelierTone.gold;
  }

  static Color _sliceColor(AtelierPalette p, int i) {
    final colors = [p.gold, p.sapphire, p.emerald, p.amber, p.ruby, p.inkSoft];
    return colors[i % colors.length];
  }
}

class _HeroHeadline extends StatelessWidget {
  const _HeroHeadline({
    required this.label,
    required this.kpi,
    required this.loading,
  });

  final String label;
  final AnalyticsKpi? kpi;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final soft = p.onOnyx.withValues(alpha: 0.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AtelierType.overline(soft)),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: AtelierMotion.base,
          child: loading || kpi == null
              ? Container(
                  key: const ValueKey('loading'),
                  width: 180,
                  height: 44,
                  decoration: BoxDecoration(
                    color: p.onOnyx.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AtelierRadius.sm),
                  ),
                )
              : CountUpText(
                  kpi!.value,
                  key: ValueKey(kpi!.value),
                  duration: const Duration(milliseconds: 1500),
                  style: AtelierType.display(
                    p.onOnyx,
                    size: 48,
                    weight: FontWeight.w500,
                  ),
                ),
        ),
        if (kpi != null && kpi!.delta.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              AtelierDelta(label: kpi!.delta, up: kpi!.deltaUp, onDark: true),
              const SizedBox(width: 8),
              Text(
                'vs previous period',
                style: AtelierType.caption(soft, size: 11.5),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatusBars extends StatelessWidget {
  const _StatusBars({required this.rows});

  final List<AnalyticsStatusRow> rows;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final total = rows.fold<int>(0, (s, r) => s + r.count);
    final max = rows.fold<int>(0, (m, r) => r.count > m ? r.count : m);
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Reveal(
              index: i,
              offset: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor(p, rows[i].label),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rows[i].label,
                          style: AtelierType.label(p.ink, size: 12.5),
                        ),
                      ),
                      Text(
                        '${rows[i].count}',
                        style: AtelierType.figure(p.ink, size: 13),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 38,
                        child: Text(
                          total == 0
                              ? '0%'
                              : '${(rows[i].count / total * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.end,
                          style: AtelierType.caption(p.muted, size: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AtelierMeter(
                    value: max == 0 ? 0 : rows[i].count / max,
                    color: _statusColor(p, rows[i].label),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static Color _statusColor(AtelierPalette p, String label) {
    final s = label.toUpperCase();
    if (s.contains('DELIVER') || s.contains('PAID') || s.contains('SUCCESS')) {
      return p.emerald;
    }
    if (s.contains('SHIP')) return p.sapphire;
    if (s.contains('PROCESS') || s.contains('PEND')) return p.amber;
    if (s.contains('CANCEL') || s.contains('FAIL')) return p.ruby;
    return p.gold;
  }
}

class _AnalyticsSkeleton extends StatelessWidget {
  const _AnalyticsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final n = c.maxWidth >= 520 ? 3 : 2;
            final w = (c.maxWidth - 12 * (n - 1)) / n;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < 3; i++)
                  SizedBox(
                    width: w,
                    child: const SkeletonBox(
                      height: 104,
                      radius: AtelierRadius.lg,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const SkeletonBox(height: 320, radius: AtelierRadius.lg),
        const SizedBox(height: 20),
        const SkeletonBox(height: 220, radius: AtelierRadius.lg),
      ],
    );
  }
}
