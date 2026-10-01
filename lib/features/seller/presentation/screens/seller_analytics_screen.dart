import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/chart_value_tooltip.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../application/seller_insights_provider.dart';
import '../../domain/models/seller_insights.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Seller analytics screen: revenue trend, category mix, order status,
/// top products, and engagement metrics.
class SellerAnalyticsScreen extends ConsumerStatefulWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  ConsumerState<SellerAnalyticsScreen> createState() =>
      _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends ConsumerState<SellerAnalyticsScreen> {
  AnalyticsRange _range = AnalyticsRange.last30;

  Map<AnalyticsRange, String> get _rangeLabels => {
    AnalyticsRange.last7: context.tr(RemainingL10n.last7Days),
    AnalyticsRange.last30: context.tr(RemainingL10n.last30Days),
    AnalyticsRange.last90: context.tr(RemainingL10n.last90Days),
    AnalyticsRange.year: context.tr(RemainingL10n.thisYear),
  };

  Map<String, (IconData, Color)> get _kpiMeta => {
    context.tr(RemainingL10n.revenue): (
      Icons.attach_money_outlined,
      AppColors.bronze,
    ),
    context.tr(RemainingL10n.orders): (
      Icons.shopping_cart_outlined,
      AppColors.info,
    ),
    context.tr(RemainingL10n.averageOrderValue): (
      Icons.payments_outlined,
      AppColors.success,
    ),
    context.tr(RemainingL10n.unitsSold): (
      Icons.inventory_2_outlined,
      AppColors.bronzeDark,
    ),
  };

  Map<String, (IconData, Color)> get _engagementMeta => {
    context.tr(RemainingL10n.unitsSold): (
      Icons.inventory_2_outlined,
      AppColors.bronzeDark,
    ),
    context.tr(RemainingL10n.refundRequests): (
      Icons.replay_outlined,
      AppColors.error,
    ),
    context.tr(RemainingL10n.paidRate): (
      Icons.percent_outlined,
      AppColors.success,
    ),
    context.tr(RemainingL10n.uniqueProducts): (
      Icons.category_outlined,
      AppColors.bronze,
    ),
  };

  static final _sliceColors = <Color>[
    const Color(0xFF5C7C9E),
    AppColors.bronze,
    const Color(0xFF8E6C88),
    AppColors.success,
    AppColors.charcoal,
    AppColors.info,
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerAnalyticsProvider(_range));
    final snapshot = state.snapshot;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: RefreshIndicator(
        onRefresh: () =>
            ref.read(sellerAnalyticsProvider(_range).notifier).refresh(),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView(
            children: [
              Text(
                context.tr(
                  RemainingL10n.performanceInsightsAcrossSalesOrdersAndTraffic,
                ),
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              _RangeSelector(
                value: _range,
                labels: _rangeLabels,
                onChanged: (v) => setState(() => _range = v),
              ),
              if (state.errorMessage != null && snapshot == null) ...[
                const SizedBox(height: AppSpacing.s16),
                CatalogErrorState(
                  message: state.errorMessage!,
                  onRetry: () => ref
                      .read(sellerAnalyticsProvider(_range).notifier)
                      .refresh(),
                ),
              ] else if (state.isLoading && snapshot == null) ...[
                const SizedBox(height: 80),
                const Center(child: CircularProgressIndicator()),
              ] else if (snapshot != null) ...[
                const SizedBox(height: AppSpacing.s16),
                _KpiGrid(
                  kpis: [
                    for (final kpi in snapshot.kpis)
                      _Kpi(
                        title: kpi.title,
                        value: kpi.value,
                        delta: kpi.delta,
                        deltaUp: kpi.deltaUp,
                        icon:
                            (_kpiMeta[kpi.title] ??
                                    (
                                      Icons.insights_outlined,
                                      AppColors.textPrimary(context),
                                    ))
                                .$1,
                        color:
                            (_kpiMeta[kpi.title] ??
                                    (
                                      Icons.insights_outlined,
                                      AppColors.textPrimary(context),
                                    ))
                                .$2,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                _AnalyticsCard(
                  title: context.tr(RemainingL10n.revenueTrend),
                  subtitle: context.tr(RemainingL10n.grossRevenueOverTime),
                  child: snapshot.revenueSeries.values.isEmpty
                      ? Text(
                          context.tr(RemainingL10n.noRevenuePeriod),
                          style: AppTypography.body.copyWith(
                            color: AppColors.textMuted(context),
                          ),
                        )
                      : _RevenueLineChart(
                          values: snapshot.revenueSeries.values,
                          labels: snapshot.revenueSeries.labels,
                          details: snapshot.revenueSeries.details,
                        ),
                ),
                const SizedBox(height: AppSpacing.s16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 760;
                    final catMix = _AnalyticsCard(
                      title: context.tr(RemainingL10n.salesByCategory),
                      subtitle: context.tr(
                        RemainingL10n.revenueSharePerCatalog,
                      ),
                      child: snapshot.categorySlices.isEmpty
                          ? Text(
                              context.tr(RemainingL10n.noCategorySales),
                              style: AppTypography.body.copyWith(
                                color: AppColors.textMuted(context),
                              ),
                            )
                          : _CategoryDonut(
                              slices: [
                                for (
                                  var i = 0;
                                  i < snapshot.categorySlices.length;
                                  i++
                                )
                                  _CategorySlice(
                                    snapshot.categorySlices[i].label,
                                    snapshot.categorySlices[i].value,
                                    _sliceColors[i % _sliceColors.length],
                                  ),
                              ],
                            ),
                    );
                    final orderStatus = _AnalyticsCard(
                      title: context.tr(RemainingL10n.orderStatus),
                      subtitle: context.tr(
                        RemainingL10n.currentPipelineBreakdown,
                      ),
                      child: snapshot.orderStatus.isEmpty
                          ? Text(
                              context.tr(RemainingL10n.noOrdersPeriod),
                              style: AppTypography.body.copyWith(
                                color: AppColors.textMuted(context),
                              ),
                            )
                          : _OrderStatusBars(
                              rows: [
                                for (
                                  var i = 0;
                                  i < snapshot.orderStatus.length;
                                  i++
                                )
                                  _StatusRow(
                                    snapshot.orderStatus[i].label,
                                    snapshot.orderStatus[i].count,
                                    _statusColor(
                                      snapshot.orderStatus[i].label,
                                      i,
                                    ),
                                  ),
                              ],
                            ),
                    );
                    if (!isWide) {
                      return Column(
                        children: [
                          catMix,
                          const SizedBox(height: AppSpacing.s16),
                          orderStatus,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: catMix),
                        const SizedBox(width: AppSpacing.s16),
                        Expanded(child: orderStatus),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.s16),
                _AnalyticsCard(
                  title: context.tr(RemainingL10n.engagementMetrics),
                  subtitle: context.tr(
                    RemainingL10n.listingInterestAndCatalogPerformance,
                  ),
                  child: _EngagementGrid(
                    metrics: [
                      for (final m in snapshot.engagement)
                        _EngagementMetric(
                          label: m.label,
                          value: m.value,
                          hint: m.hint,
                          icon:
                              (_engagementMeta[m.label] ??
                                      (
                                        Icons.insights_outlined,
                                        AppColors.textPrimary(context),
                                      ))
                                  .$1,
                          color:
                              (_engagementMeta[m.label] ??
                                      (
                                        Icons.insights_outlined,
                                        AppColors.textPrimary(context),
                                      ))
                                  .$2,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String label, int index) {
    final s = label.toUpperCase();
    if (s.contains('DELIVER') || s.contains('PAID') || s.contains('SUCCESS')) {
      return AppColors.success;
    }
    if (s.contains('SHIP')) return AppColors.info;
    if (s.contains('PROCESS') || s.contains('PEND')) return AppColors.warning;
    if (s.contains('CANCEL') || s.contains('FAIL')) return AppColors.error;
    if (s.contains('REFUND')) return const Color(0xFF8E6C88);
    return _sliceColors[index % _sliceColors.length];
  }
}

class _Kpi {
  const _Kpi({
    required this.title,
    required this.value,
    required this.delta,
    required this.deltaUp,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String delta;
  final bool deltaUp;
  final IconData icon;
  final Color color;
}

class _CategorySlice {
  const _CategorySlice(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class _StatusRow {
  const _StatusRow(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;
}

class _EngagementMetric {
  const _EngagementMetric({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;
}

// Building blocks
// ---------------------------------------------------------------------------

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  final AnalyticsRange value;
  final Map<AnalyticsRange, String> labels;
  final ValueChanged<AnalyticsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final range in AnalyticsRange.values) ...[
            ChoiceChip(
              label: Text(labels[range]!),
              selected: value == range,
              onSelected: (_) => onChanged(range),
              selectedColor: AppColors.selectedFill(context),
              labelStyle: AppTypography.label.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value == range
                    ? AppColors.onSelected(context)
                    : AppColors.textPrimary(context),
              ),
              side: BorderSide(color: AppColors.border(context)),
              showCheckmark: false,
            ),
            const SizedBox(width: AppSpacing.s8),
          ],
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});

  final List<_Kpi> kpis;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: kpis.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: AppSpacing.s16,
            mainAxisSpacing: AppSpacing.s16,
            childAspectRatio: isWide ? 1.7 : 1.45,
          ),
          itemBuilder: (context, index) {
            final kpi = kpis[index];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(AppSpacing.r12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          kpi.title,
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(kpi.icon, color: kpi.color, size: 20),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      kpi.value,
                      style: AppTypography.headline.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    children: [
                      Icon(
                        kpi.deltaUp ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: kpi.deltaUp
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${kpi.delta} vs previous period',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            color: kpi.deltaUp
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.title.copyWith(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Revenue line chart
// ---------------------------------------------------------------------------

class _RevenueLineChart extends StatefulWidget {
  const _RevenueLineChart({
    required this.values,
    required this.labels,
    this.details = const [],
  });

  final List<double> values;
  final List<String> labels;

  /// Full period names for the tooltip, aligned with [labels].
  final List<String> details;

  static const height = 220.0;

  @override
  State<_RevenueLineChart> createState() => _RevenueLineChartState();
}

class _RevenueLineChartState extends State<_RevenueLineChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant _RevenueLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxY = widget.values.reduce(math.max) * 1.15;
    final labelStep = (widget.labels.length / 7).ceil().clamp(
      1,
      math.max(1, widget.labels.length),
    );

    return Column(
      children: [
        SizedBox(
          height: _RevenueLineChart.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 46,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final f in [1.0, 0.75, 0.5, 0.25, 0.0])
                      Text(
                        _fmtShort(maxY * f),
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapDown: (details) {
                        if (widget.values.length < 2 || maxY <= 0) return;
                        final stepX =
                            constraints.maxWidth / (widget.values.length - 1);
                        final index = ((details.localPosition.dx / stepX)
                                .round())
                            .clamp(0, widget.values.length - 1);
                        setState(() {
                          _selectedIndex = _selectedIndex == index ? null : index;
                        });
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            painter: _LineChartPainter(
                              values: widget.values,
                              maxY: maxY,
                              lineColor: AppColors.bronze,
                              fillColor:
                                  AppColors.bronze.withValues(alpha: 0.12),
                              gridColor: AppColors.border(context)
                                  .withValues(alpha: 0.6),
                              selectedIndex: _selectedIndex,
                            ),
                            child: const SizedBox.expand(),
                          ),
                          if (_selectedIndex != null)
                            _lineChartTooltip(
                              constraints.maxWidth,
                              _selectedIndex!,
                              maxY,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            const SizedBox(width: 54),
            for (var i = 0; i < widget.labels.length; i++)
              Expanded(
                child: Text(
                  // Daily / weekly series label every few points; the
                  // tooltip names each one.
                  i % labelStep == 0 || i == widget.labels.length - 1
                      ? widget.labels[i]
                      : '',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    height: 1.2,
                    color: AppColors.textMuted(context),
                  ),
                  maxLines: 2,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _lineChartTooltip(double width, int index, double maxY) {
    if (widget.values.length < 2) return const SizedBox.shrink();
    final stepX = width / (widget.values.length - 1);
    final x = stepX * index;
    final y = _RevenueLineChart.height * (1 - widget.values[index] / maxY);
    return Positioned(
      left: (x - 48).clamp(0.0, width - 96),
      top: (y - 52).clamp(0.0, _RevenueLineChart.height - 48),
      child: ChartValueTooltip(
        label: index < widget.details.length
            ? widget.details[index]
            : widget.labels[index],
        value: AppCurrency.format(widget.values[index].toStringAsFixed(2)),
      ),
    );
  }

  static String _fmtShort(double v) {
    if (v >= 1000) {
      return '${AppCurrency.format((v / 1000).toStringAsFixed(1))}k';
    }
    return AppCurrency.format(v.toStringAsFixed(0));
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.values,
    required this.maxY,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    this.selectedIndex,
  });

  final List<double> values;
  final double maxY;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final f in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final y = size.height * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (values.length < 2 || maxY <= 0) return;

    final stepX = size.width / (values.length - 1);
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(stepX * i, size.height * (1 - values[i] / maxY)),
    ];

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    final dotPaint = Paint()..color = lineColor;
    final dotRing = Paint()..color = Colors.white;
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final selected = selectedIndex == i;
      canvas.drawCircle(p, selected ? 6.5 : 4.5, dotRing);
      canvas.drawCircle(p, selected ? 4.5 : 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.maxY != maxY ||
      oldDelegate.selectedIndex != selectedIndex;
}

// ---------------------------------------------------------------------------
// Category donut
// ---------------------------------------------------------------------------

class _CategoryDonut extends StatefulWidget {
  const _CategoryDonut({required this.slices});

  final List<_CategorySlice> slices;

  @override
  State<_CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<_CategoryDonut> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant _CategoryDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slices != widget.slices) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.slices.fold<double>(0, (s, e) => s + e.value);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: GestureDetector(
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null || total <= 0) return;
              final local = box.globalToLocal(details.globalPosition);
              final center = Offset(box.size.width / 2, 90);
              final dx = local.dx - center.dx;
              final dy = local.dy - center.dy;
              final distance = math.sqrt(dx * dx + dy * dy);
              final radius = math.min(box.size.width, 180) / 2 - 6;
              if (distance < radius - 26 || distance > radius + 6) {
                setState(() => _selectedIndex = null);
                return;
              }
              var angle = math.atan2(dy, dx) + math.pi / 2;
              if (angle < 0) angle += 2 * math.pi;
              var cursor = 0.0;
              for (var i = 0; i < widget.slices.length; i++) {
                final sweep = (widget.slices[i].value / total) * 2 * math.pi;
                if (angle >= cursor && angle < cursor + sweep) {
                  setState(() {
                    _selectedIndex = _selectedIndex == i ? null : i;
                  });
                  return;
                }
                cursor += sweep;
              }
            },
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: _DonutPainter(
                    slices: widget.slices,
                    total: total,
                    selectedIndex: _selectedIndex,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${total.toStringAsFixed(0)}%',
                          style: AppTypography.headline.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          context.tr(RemainingL10n.ofRevenue),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted(context),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedIndex != null)
                  Positioned(
                    top: 0,
                    child: ChartValueTooltip(
                      label: widget.slices[_selectedIndex!].label,
                      value:
                          '${widget.slices[_selectedIndex!].value.toStringAsFixed(1)}%',
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Wrap(
          spacing: AppSpacing.s16,
          runSpacing: AppSpacing.s8,
          children: [
            for (var i = 0; i < widget.slices.length; i++)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = _selectedIndex == i ? null : i;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: widget.slices[i].color,
                        shape: BoxShape.circle,
                        border: _selectedIndex == i
                            ? Border.all(color: AppColors.info, width: 2)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.slices[i].label} ${widget.slices[i].value.toStringAsFixed(0)}%',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight:
                            _selectedIndex == i ? FontWeight.w700 : null,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.slices,
    required this.total,
    this.selectedIndex,
  });

  final List<_CategorySlice> slices;
  final double total;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const stroke = 26.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    var start = -math.pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final s = slices[i];
      final sweep = (s.value / total) * 2 * math.pi;
      paint.color = s.color;
      if (selectedIndex == i) {
        paint.strokeWidth = stroke + 4;
      } else {
        paint.strokeWidth = stroke;
      }
      canvas.drawArc(rect, start, sweep - 0.03, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.selectedIndex != selectedIndex;
}

// ---------------------------------------------------------------------------
// Order status horizontal bars
// ---------------------------------------------------------------------------

class _OrderStatusBars extends StatefulWidget {
  const _OrderStatusBars({required this.rows});

  final List<_StatusRow> rows;

  @override
  State<_OrderStatusBars> createState() => _OrderStatusBarsState();
}

class _OrderStatusBarsState extends State<_OrderStatusBars> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final maxCount = widget.rows
        .fold<int>(0, (m, r) => math.max(m, r.count))
        .toDouble();

    return Column(
      children: [
        for (var i = 0; i < widget.rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = _selectedIndex == i ? null : i;
                });
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 84,
                        child: Text(
                          widget.rows[i].label,
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _selectedIndex == i
                                ? AppColors.info
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: maxCount > 0
                                ? widget.rows[i].count / maxCount
                                : 0,
                            minHeight: 10,
                            backgroundColor: AppColors.surface(context),
                            valueColor:
                                AlwaysStoppedAnimation(widget.rows[i].color),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${widget.rows[i].count}',
                          textAlign: TextAlign.right,
                          style: AppTypography.label.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedIndex == i)
                    Positioned(
                      top: -40,
                      left: 84,
                      child: ChartValueTooltip(
                        label: widget.rows[i].label,
                        value: '${widget.rows[i].count}',
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Top products — paused for now (not needed yet).
// ---------------------------------------------------------------------------

// class _TopProductsList extends StatelessWidget {
//   _TopProductsList({required this.products});
//
//   final List<_TopProduct> products;
//
//   @override
//   Widget build(BuildContext context) {
//     final maxRevenue =
//         products.fold<double>(0, (m, p) => math.max(m, p.revenue));
//
//     return Column(
//       children: [
//         for (var i = 0; i < products.length; i++)
//           Padding(
//             padding: EdgeInsets.only(
//               bottom: i == products.length - 1 ? 0 : AppSpacing.s12,
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 28,
//                   height: 28,
//                   alignment: Alignment.center,
//                   decoration: BoxDecoration(
//                     color: AppColors.sandSurface,
//                     borderRadius: BorderRadius.circular(AppSpacing.r8),
//                   ),
//                   child: Text(
//                     '${i + 1}',
//                     style: AppTypography.label.copyWith(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: AppSpacing.s12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         products[i].name,
//                         style: AppTypography.label.copyWith(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       SizedBox(height: 3),
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(3),
//                         child: LinearProgressIndicator(
//                           value: maxRevenue > 0
//                               ? products[i].revenue / maxRevenue
//                               : 0,
//                           minHeight: 6,
//                           backgroundColor: AppColors.sandSurface,
//                           valueColor:
//                               AlwaysStoppedAnimation(AppColors.bronze),
//                         ),
//                       ),
//                       SizedBox(height: 2),
//                       Text(
//                         '${products[i].category} · ${products[i].units} sold',
//                         style: AppTypography.caption.copyWith(
//                           fontSize: 10,
//                           color: AppColors.textMutedLight,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(width: AppSpacing.s12),
//                 Text(
//                   AppCurrency.format(products[i].revenue.toStringAsFixed(0)),
//                   style: AppTypography.label.copyWith(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }
// }

// ---------------------------------------------------------------------------
// Engagement metrics (2×2 grid)
// ---------------------------------------------------------------------------

class _EngagementGrid extends StatelessWidget {
  const _EngagementGrid({required this.metrics});

  final List<_EngagementMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.s12,
        mainAxisSpacing: AppSpacing.s12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final m = metrics[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppSpacing.r12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: m.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.r8),
                    ),
                    child: Icon(m.icon, size: 18, color: m.color),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      m.label,
                      style: AppTypography.label.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                m.value,
                style: AppTypography.headline.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.hint,
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.textMuted(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
