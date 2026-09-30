import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/chart_value_tooltip.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../application/seller_insights_provider.dart';
import '../../../auction/application/auction_providers.dart';
import '../widgets/seller_auction_standing_section.dart';
import '../widgets/seller_dashboard_diamond_projects_section.dart';
import '../../domain/models/seller_insights.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Seller dashboard screen shown after login.
class SellerDashboardScreen extends ConsumerStatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  ConsumerState<SellerDashboardScreen> createState() =>
      _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen> {
  SalesRange _range = SalesRange.monthly;
  DateTime? _customStart;
  DateTime? _customEnd;
  DashboardMetric _metric = DashboardMetric.totalSales;

  static final _metricIcons = <DashboardMetric, (IconData, Color)>{
    DashboardMetric.totalSales: (Icons.attach_money_outlined, AppColors.bronze),
    DashboardMetric.productsSold: (
      Icons.inventory_2_outlined,
      AppColors.success,
    ),
    DashboardMetric.orders: (Icons.shopping_cart_outlined, AppColors.info),
    DashboardMetric.inventoryValue: (
      Icons.warehouse_outlined,
      AppColors.bronzeDark,
    ),
  };

  Future<void> _applyRange(SalesRange range, {DateTime? start, DateTime? end}) {
    setState(() {
      _range = range;
      _customStart = start;
      _customEnd = end;
    });
    return ref
        .read(sellerDashboardProvider.notifier)
        .setParams(
          SellerDashboardParams(
            range: range,
            customStart: start,
            customEnd: end,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerDashboardProvider);
    final snapshot = state.snapshot;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sellerAuctionStandingProvider);
          await ref.read(sellerDashboardProvider.notifier).refresh();
        },
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView(
            children: [
              _TopHeader(
                subtitle: context.tr(
                  RemainingL10n.welcomeBackHereSWhatSHappening,
                ),
              ),
              if (state.errorMessage != null && snapshot == null) ...[
                const SizedBox(height: AppSpacing.s16),
                CatalogErrorState(
                  message: state.errorMessage!,
                  onRetry: () =>
                      ref.read(sellerDashboardProvider.notifier).refresh(),
                ),
              ] else if (state.isLoading && snapshot == null) ...[
                const SizedBox(height: 80),
                const Center(child: CircularProgressIndicator()),
              ] else if (snapshot != null) ...[
                const SizedBox(height: AppSpacing.s16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    final crossAxisCount = isWide ? 4 : 2;
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: snapshot.metrics.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: AppSpacing.s16,
                        mainAxisSpacing: AppSpacing.s16,
                        childAspectRatio: isWide ? 1.55 : 1.35,
                      ),
                      itemBuilder: (context, index) {
                        final card = snapshot.metrics[index];
                        final icon = _metricIcons[card.metric]!;
                        return _MetricCard(
                          data: _MetricData(
                            metric: card.metric,
                            title: card.title,
                            value: card.value,
                            subtitle: card.subtitle,
                            icon: icon.$1,
                            iconColor: icon.$2,
                          ),
                          selected: _metric == card.metric,
                          onTap: () {
                            setState(() => _metric = card.metric);
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.s16),
                _CardSection(
                  title: _chartSectionTitle(_metric),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SalesRangeDropdown(
                        value: _range,
                        customStart: _customStart,
                        customEnd: _customEnd,
                        onChanged: (v) async {
                          if (v == SalesRange.custom) {
                            final picked = await _pickCustomDateRange(context);
                            if (picked == null) return;
                            await _applyRange(
                              SalesRange.custom,
                              start: picked.$1,
                              end: picked.$2,
                            );
                            return;
                          }
                          await _applyRange(v);
                        },
                      ),
                      if (_range == SalesRange.custom &&
                          _customStart != null &&
                          _customEnd != null) ...[
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          '${_fmtDate(_customStart!)} → ${_fmtDate(_customEnd!)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.s16),
                      Stack(
                        children: [
                          _DashboardBarChart(
                            metric: _metric,
                            values: snapshot.chartFor(_metric).values,
                            labels: snapshot.chartFor(_metric).labels,
                          ),
                          if (state.isRefreshing)
                            Positioned.fill(
                              child: ColoredBox(
                                color: AppColors.bg(
                                  context,
                                ).withValues(alpha: 0.35),
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        snapshot.chartEndDate != null
                            ? context.tr(RemainingL10n.throughDate, {
                                'date': _fmtDate(snapshot.chartEndDate!),
                              })
                            : '',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                const SellerAuctionStandingSection(),
                const SizedBox(height: AppSpacing.s16),
                const SellerDashboardDiamondProjectsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _chartSectionTitle(DashboardMetric metric) {
    return switch (metric) {
      DashboardMetric.totalSales => context.tr(RemainingL10n.salesOverview),
      DashboardMetric.productsSold => context.tr(RemainingL10n.productsSold),
      DashboardMetric.orders => context.tr(RemainingL10n.orders),
      DashboardMetric.inventoryValue => context.tr(
        RemainingL10n.inventoryValue,
      ),
    };
  }

  Future<(DateTime, DateTime)?> _pickCustomDateRange(
    BuildContext context,
  ) async {
    DateTime? start = _customStart;
    DateTime? end = _customEnd;
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now().add(const Duration(days: 365));

    return showAppDialog<(DateTime, DateTime)>(
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
                if (end != null && end!.isBefore(picked)) {
                  end = null;
                }
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

            return AlertDialog(
              backgroundColor: AppColors.card(context),
              title: Text(
                context.tr(RemainingL10n.customDateRange),
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CustomDateField(
                      label: context.tr(RemainingL10n.startDate),
                      value: start,
                      onTap: pickStart,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    _CustomDateField(
                      label: context.tr(RemainingL10n.endDate),
                      value: end,
                      onTap: pickEnd,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.tr(RemainingL10n.cancel)),
                ),
                FilledButton(
                  onPressed: start != null && end != null
                      ? () => Navigator.of(dialogContext).pop((start!, end!))
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.charcoal,
                    foregroundColor: AppColors.warmWhite,
                  ),
                  child: Text(context.tr(RemainingL10n.apply)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _fmtDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.month)}/${two(d.day)}/${d.year}';
  }
}

class _CustomDateField extends StatelessWidget {
  const _CustomDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? context.tr(RemainingL10n.selectDate)
        : _SellerDashboardScreenState._fmtDate(value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: AppColors.card(context),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            child: InputDecorator(
              decoration: InputDecoration(
                isDense: true,
                hintText: context.tr(RemainingL10n.selectDate),
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              child: Text(
                text,
                style: AppTypography.body.copyWith(
                  color: value == null
                      ? AppColors.textMuted(context)
                      : AppColors.textPrimary(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.metric,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final DashboardMetric metric;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _MetricData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        side: BorderSide(
          color: selected ? AppColors.info : AppColors.border(context),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.title,
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(data.icon, color: data.iconColor, size: 22),
                ],
              ),
              const Spacer(),
              Text(
                data.value,
                style: AppTypography.headline.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                data.subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Text(
      subtitle,
      style: AppTypography.body.copyWith(
        color: AppColors.textSecondary(context),
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
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
            const SizedBox(height: AppSpacing.s12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SalesRangeDropdown extends StatelessWidget {
  const _SalesRangeDropdown({
    required this.value,
    required this.onChanged,
    this.customStart,
    this.customEnd,
  });

  final SalesRange value;
  final ValueChanged<SalesRange> onChanged;
  final DateTime? customStart;
  final DateTime? customEnd;

  Map<SalesRange, String> _labels(BuildContext context) => {
    SalesRange.daily: context.tr(RemainingL10n.daily),
    SalesRange.weekly: context.tr(RemainingL10n.weekly),
    SalesRange.monthly: context.tr(RemainingL10n.monthly),
    SalesRange.quarterly: context.tr(RemainingL10n.quarterly),
    SalesRange.yearly: context.tr(RemainingL10n.yearly),
    SalesRange.custom: context.tr(RemainingL10n.custom),
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SalesRange>(
      key: ValueKey('${value.name}_${customStart}_$customEnd'),
      initialValue: value,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
      ),
      items: [
        for (final range in SalesRange.values)
          DropdownMenuItem(value: range, child: Text(_labels(context)[range]!)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _DashboardBarChart extends StatefulWidget {
  const _DashboardBarChart({
    required this.metric,
    required this.values,
    required this.labels,
  });

  final DashboardMetric metric;
  final List<double> values;
  final List<String> labels;

  static const chartHeight = 240.0;

  static Color barColor(DashboardMetric metric) {
    return switch (metric) {
      DashboardMetric.totalSales => AppColors.bronze,
      DashboardMetric.productsSold => AppColors.success,
      DashboardMetric.orders => AppColors.info,
      DashboardMetric.inventoryValue => AppColors.bronzeDark,
    };
  }

  static double niceMax(List<double> values) {
    if (values.isEmpty) return 1;
    final raw = values.reduce((a, b) => a > b ? a : b);
    if (raw <= 0) return 1;
    final magnitude = pow10((math.log(raw) / math.ln10).floor());
    final normalized = raw / magnitude;
    final nice = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    return nice * magnitude;
  }

  static double pow10(int exp) {
    var result = 1.0;
    for (var i = 0; i < exp.abs(); i++) {
      result *= 10;
    }
    return exp < 0 ? 1 / result : result;
  }

  static List<double> yTicks(double maxY) {
    return [0, maxY * 0.25, maxY * 0.5, maxY * 0.75, maxY];
  }

  static String Function(double) yFormatter(DashboardMetric metric) {
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

  @override
  State<_DashboardBarChart> createState() => _DashboardBarChartState();
}

class _DashboardBarChartState extends State<_DashboardBarChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant _DashboardBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metric != widget.metric ||
        oldWidget.values != widget.values) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.values.isEmpty ? const <double>[0] : widget.values;
    final xLabels = widget.labels.isEmpty ? ['—'] : widget.labels;
    final maxY = _DashboardBarChart.niceMax(series);
    final yTicks = _DashboardBarChart.yTicks(maxY);
    final formatY = _DashboardBarChart.yFormatter(widget.metric);

    return SizedBox(
      height: _DashboardBarChart.chartHeight + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            height: _DashboardBarChart.chartHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final tick in yTicks.reversed)
                  Text(
                    formatY(tick),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted(context),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: _DashboardBarChart.chartHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < yTicks.length; i++)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: _DashboardBarChart.chartHeight *
                              (1 - yTicks[i] / maxY),
                          child: Container(
                            height: 1,
                            color: AppColors.border(
                              context,
                            ).withValues(alpha: 0.6),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < series.length; i++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: _BarColumn(
                                  value: series[i],
                                  maxY: maxY,
                                  height: _DashboardBarChart.chartHeight,
                                  color: _DashboardBarChart.barColor(
                                    widget.metric,
                                  ),
                                  selected: _selectedIndex == i,
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex =
                                          _selectedIndex == i ? null : i;
                                    });
                                  },
                                  tooltip: _selectedIndex == i
                                      ? ChartValueTooltip(
                                          label: xLabels[i],
                                          value: formatY(series[i]),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Row(
                  children: [
                    for (final label in xLabels)
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted(context),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.value,
    required this.maxY,
    required this.height,
    required this.color,
    this.selected = false,
    this.onTap,
    this.tooltip,
  });

  final double value;
  final double maxY;
  final double height;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? tooltip;

  @override
  Widget build(BuildContext context) {
    final barHeight = maxY > 0 ? (value / maxY) * height : 0.0;
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: barHeight.clamp(0, height),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.85) : color,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  border: selected
                      ? Border.all(color: AppColors.info, width: 2)
                      : null,
                ),
              ),
            ),
          ),
          if (tooltip != null)
            Positioned(
              bottom: barHeight.clamp(0, height) + 8,
              left: 0,
              right: 0,
              child: Center(child: tooltip),
            ),
        ],
      ),
    );
  }
}

