import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/app_currency.dart';
import '../../../domain/models/seller_insights.dart';
import '../../atelier/atelier_bar_chart.dart';
import '../../atelier/atelier_components.dart';
import '../../atelier/atelier_feedback.dart';
import '../../atelier/atelier_motion.dart';
import '../../atelier/atelier_theme.dart';

/// Visual identity of each dashboard metric.
({IconData icon, AtelierTone tone}) dashboardMetricStyle(DashboardMetric m) =>
    switch (m) {
      DashboardMetric.totalSales => (
        icon: Icons.payments_outlined,
        tone: AtelierTone.gold,
      ),
      DashboardMetric.productsSold => (
        icon: Icons.diamond_outlined,
        tone: AtelierTone.emerald,
      ),
      DashboardMetric.orders => (
        icon: Icons.receipt_long_outlined,
        tone: AtelierTone.sapphire,
      ),
      DashboardMetric.inventoryValue => (
        icon: Icons.inventory_2_outlined,
        tone: AtelierTone.amber,
      ),
    };

/// Axis / tooltip formatter for a metric.
String Function(double) dashboardMetricFormatter(DashboardMetric metric) {
  return switch (metric) {
    DashboardMetric.totalSales => (v) => AppCurrency.format(
      v.toStringAsFixed(2),
    ),
    DashboardMetric.productsSold => (v) => v.toStringAsFixed(0),
    DashboardMetric.orders => (v) => v.toStringAsFixed(0),
    DashboardMetric.inventoryValue => (v) {
      if (v >= 1000) {
        return '${AppCurrency.format((v / 1000).toStringAsFixed(0))}k';
      }
      return AppCurrency.format(v.toStringAsFixed(0));
    },
  };
}

String dashboardDate(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.month)}/${two(d.day)}/${d.year}';
}

/// KPI tiles in one horizontally scrolling row; the selected one drives the
/// chart below. When all tiles fit at their natural width they share the row.
class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid({
    required this.metrics,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<DashboardMetricCard> metrics;
  final DashboardMetric selected;
  final ValueChanged<DashboardMetric> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AtelierSpace.s10;
        const minTile = 158.0;
        final n = metrics.length;
        final fitWidth = n == 0
            ? minTile
            : (constraints.maxWidth - gap * (n - 1)) / n;
        // Phones: ~2.3 tiles visible so the cut-off one hints at scrolling.
        final tileWidth = fitWidth >= minTile
            ? fitWidth
            : ((constraints.maxWidth - gap * 2) / 2.3).clamp(minTile, 190.0);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // Room for the selected tile's glow, which a scroll view would clip.
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(bottom: 4),
          physics: fitWidth >= minTile
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                SizedBox(
                  width: tileWidth,
                  child: Reveal(
                    index: i,
                    child: _MetricTile(
                      card: metrics[i],
                      selected: metrics[i].metric == selected,
                      onTap: () => onSelected(metrics[i].metric),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  final DashboardMetricCard card;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final style = dashboardMetricStyle(card.metric);
    final accent = p.tone(style.tone);
    return Semantics(
      selected: selected,
      label: '${card.title}, ${card.value}. ${card.subtitle}',
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AtelierMotion.slow,
          curve: AtelierMotion.emphasized,
          height: 104,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: BoxDecoration(
            color: selected ? p.raised : p.surface,
            borderRadius: BorderRadius.circular(AtelierRadius.lg),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.7) : p.hairline,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: p.isDark ? 0.18 : 0.16),
                      blurRadius: 26,
                      spreadRadius: -6,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : p.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and title share one line to save a row.
              Row(
                children: [
                  AtelierIconBadge(
                    icon: style.icon,
                    tone: style.tone,
                    size: 26,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      card.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.caption(p.muted, size: 11.5),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: AtelierMotion.base,
                    opacity: selected ? 1 : 0,
                    child: Icon(
                      Icons.bar_chart_rounded,
                      size: 14,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: CountUpText(
                  card.value,
                  style: AtelierType.display(p.ink, size: 23),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                card.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.caption(p.muted, size: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chart card: range selector, animated bars, freshness footnotes.
class DashboardPerformanceCard extends StatelessWidget {
  const DashboardPerformanceCard({
    required this.metric,
    required this.snapshot,
    required this.params,
    required this.isRefreshing,
    required this.isStale,
    required this.errorMessage,
    required this.onRangeSelected,
    required this.onEditCustomRange,
    required this.onRetry,
    super.key,
  });

  final DashboardMetric metric;
  final SellerDashboardSnapshot snapshot;
  final SellerDashboardParams params;
  final bool isRefreshing;
  final bool isStale;
  final String? errorMessage;
  final ValueChanged<SalesRange> onRangeSelected;
  final VoidCallback onEditCustomRange;
  final VoidCallback onRetry;

  String _title(BuildContext context) => switch (metric) {
    DashboardMetric.totalSales => context.tr(RemainingL10n.salesOverview),
    DashboardMetric.productsSold => context.tr(RemainingL10n.productsSold),
    DashboardMetric.orders => context.tr(RemainingL10n.orders),
    DashboardMetric.inventoryValue => context.tr(RemainingL10n.inventoryValue),
  };

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final series = snapshot.chartFor(metric);
    final style = dashboardMetricStyle(metric);
    final showError = isStale && !isRefreshing && errorMessage != null;
    final ranges = <SalesRange, String>{
      SalesRange.daily: context.tr(RemainingL10n.daily),
      SalesRange.weekly: context.tr(RemainingL10n.weekly),
      SalesRange.monthly: context.tr(RemainingL10n.monthly),
      SalesRange.quarterly: context.tr(RemainingL10n.quarterly),
      SalesRange.yearly: context.tr(RemainingL10n.yearly),
      SalesRange.custom: context.tr(RemainingL10n.custom),
    };
    final hasCustomDates =
        params.range == SalesRange.custom &&
        params.customStart != null &&
        params.customEnd != null;

    return AtelierCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PERFORMANCE', style: AtelierType.overline(p.gold)),
                    const SizedBox(height: 5),
                    AnimatedSwitcher(
                      duration: AtelierMotion.base,
                      child: Text(
                        _title(context),
                        key: ValueKey(metric),
                        style: AtelierType.display(p.ink, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: AtelierMotion.base,
                child: isRefreshing
                    ? SizedBox(
                        key: const ValueKey('busy'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: p.gold,
                        ),
                      )
                    : const SizedBox(key: ValueKey('idle'), width: 18),
              ),
            ],
          ),
          const SizedBox(height: AtelierSpace.s16),
          AtelierSegmented<SalesRange>(
            dense: true,
            segments: [
              for (final entry in ranges.entries)
                AtelierSegment(
                  value: entry.key,
                  label: entry.value,
                  icon: entry.key == SalesRange.custom
                      ? Icons.date_range_rounded
                      : null,
                ),
            ],
            selected: params.range,
            onChanged: onRangeSelected,
          ),
          AnimatedSize(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            alignment: Alignment.topLeft,
            child: hasCustomDates
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Pressable(
                      onTap: onEditCustomRange,
                      semanticLabel: 'Change custom dates',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_rounded, size: 14, color: p.gold),
                          const SizedBox(width: 5),
                          Text(
                            '${dashboardDate(params.customStart!)}  →  '
                            '${dashboardDate(params.customEnd!)}',
                            style: AtelierType.figure(p.inkSoft, size: 12),
                          ),
                          const SizedBox(width: 5),
                          Icon(Icons.edit_outlined, size: 13, color: p.muted),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: AtelierSpace.s20),
          AnimatedSwitcher(
            duration: AtelierMotion.base,
            child: showError
                ? AtelierErrorState(
                    key: const ValueKey('error'),
                    compact: true,
                    title: 'Chart unavailable',
                    message: errorMessage!,
                    onRetry: onRetry,
                  )
                : AnimatedOpacity(
                    key: const ValueKey('chart'),
                    duration: AtelierMotion.base,
                    opacity: isRefreshing ? 0.45 : 1,
                    child: AtelierBarChart(
                      values: series.values,
                      labels: series.labels,
                      detailAt: series.detailAt,
                      formatValue: dashboardMetricFormatter(metric),
                      accent: p.tone(style.tone),
                    ),
                  ),
          ),
          const SizedBox(height: AtelierSpace.s12),
          Row(
            children: [
              Expanded(
                child: Text(
                  snapshot.chartEndDate != null && !isStale
                      ? context.tr(RemainingL10n.throughDate, {
                          'date': dashboardDate(snapshot.chartEndDate!),
                        })
                      : '',
                  style: AtelierType.caption(p.muted, size: 11.5),
                ),
              ),
              Text(
                'Tap or drag the bars',
                style: AtelierType.caption(p.muted, size: 11),
              ),
            ],
          ),
          if (metric == DashboardMetric.inventoryValue) ...[
            const SizedBox(height: 5),
            Text(
              context.tr(RemainingL10n.inventorySnapshotNote),
              style: AtelierType.caption(p.muted, size: 11.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// Start / end picker for the custom chart range.
Future<(DateTime, DateTime)?> pickDashboardCustomRange(
  BuildContext context, {
  DateTime? initialStart,
  DateTime? initialEnd,
}) {
  final firstDate = DateTime(2020);
  final lastDate = DateTime.now().add(const Duration(days: 365));
  DateTime? start = initialStart;
  DateTime? end = initialEnd;

  return showAtelierDialog<(DateTime, DateTime)>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickStart() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: start ?? DateTime.now(),
              firstDate: firstDate,
              lastDate: end ?? lastDate,
              helpText: context.tr(RemainingL10n.selectStartDate),
            );
            if (picked == null) return;
            setDialogState(() {
              start = picked;
              if (end != null && end!.isBefore(picked)) end = null;
            });
          }

          Future<void> pickEnd() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: end ?? start ?? DateTime.now(),
              firstDate: start ?? firstDate,
              lastDate: lastDate,
              helpText: context.tr(RemainingL10n.selectEndDate),
            );
            if (picked == null) return;
            setDialogState(() => end = picked);
          }

          return AtelierDialogFrame(
            title: context.tr(RemainingL10n.customDateRange),
            icon: Icons.date_range_rounded,
            content: Column(
              children: [
                _DateField(
                  label: context.tr(RemainingL10n.startDate),
                  value: start,
                  onTap: pickStart,
                ),
                const SizedBox(height: 8),
                _DateField(
                  label: context.tr(RemainingL10n.endDate),
                  value: end,
                  onTap: pickEnd,
                ),
              ],
            ),
            actions: [
              AtelierButton(
                label: context.tr(RemainingL10n.cancel),
                variant: AtelierButtonVariant.secondary,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              AtelierButton(
                label: context.tr(RemainingL10n.apply),
                onPressed: start != null && end != null
                    ? () => Navigator.of(dialogContext).pop((start!, end!))
                    : null,
              ),
            ],
          );
        },
      );
    },
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: p.sunken,
          borderRadius: BorderRadius.circular(AtelierRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AtelierType.overline(p.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value == null
                        ? context.tr(RemainingL10n.selectDate)
                        : dashboardDate(value!),
                    style: AtelierType.figure(
                      value == null ? p.muted : p.ink,
                      size: 15,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today_rounded, size: 17, color: p.gold),
          ],
        ),
      ),
    );
  }
}
