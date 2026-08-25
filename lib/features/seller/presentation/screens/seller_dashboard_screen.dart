import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../application/seller_insights_provider.dart';
import '../../domain/models/seller_insights.dart';
import '../widgets/seller_layout.dart';

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

  static const _metricIcons = <DashboardMetric, (IconData, Color)>{
    DashboardMetric.totalSales: (Icons.attach_money_outlined, AppColors.bronze),
    DashboardMetric.productsSold: (Icons.inventory_2_outlined, AppColors.success),
    DashboardMetric.orders: (Icons.shopping_cart_outlined, AppColors.info),
    DashboardMetric.inventoryValue: (
      Icons.warehouse_outlined,
      AppColors.bronzeDark,
    ),
  };

  SellerDashboardParams get _params => SellerDashboardParams(
        range: _range,
        metric: _metric,
        customStart: _customStart,
        customEnd: _customEnd,
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerDashboardProvider(_params));
    final snapshot = state.snapshot;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: RefreshIndicator(
        onRefresh: () =>
            ref.read(sellerDashboardProvider(_params).notifier).refresh(),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView(
            children: [
              const _TopHeader(
                subtitle:
                    'Welcome back! Here’s what’s happening with your business today.',
              ),
              if (state.errorMessage != null && snapshot == null) ...[
                const SizedBox(height: AppSpacing.s16),
                CatalogErrorState(
                  message: state.errorMessage!,
                  onRetry: () => ref
                      .read(sellerDashboardProvider(_params).notifier)
                      .refresh(),
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
                            setState(() {
                              _range = SalesRange.custom;
                              _customStart = picked.$1;
                              _customEnd = picked.$2;
                            });
                            return;
                          }
                          setState(() {
                            _range = v;
                            _customStart = null;
                            _customEnd = null;
                          });
                        },
                      ),
                      if (_range == SalesRange.custom &&
                          _customStart != null &&
                          _customEnd != null) ...[
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          '${_fmtDate(_customStart!)} → ${_fmtDate(_customEnd!)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.s16),
                      _DashboardBarChart(
                        metric: _metric,
                        values: snapshot.chart.values,
                        labels: snapshot.chart.labels,
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        snapshot.chart.endDate != null
                            ? 'To ${_fmtDate(snapshot.chart.endDate!)}'
                            : '',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                _CardSection(
                  title: 'Recent Orders',
                  trailing: TextButton(
                    onPressed: () => context.openRoute(AppRouteNames.sellerOrders),
                    child: Text(
                      'View All',
                      style: AppTypography.label.copyWith(
                        color: AppColors.charcoal,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  child: snapshot.recentOrders.isEmpty
                      ? Text(
                          'No orders yet.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textMutedLight,
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0;
                                i < snapshot.recentOrders.length;
                                i++) ...[
                              if (i > 0) const SizedBox(height: AppSpacing.s12),
                              _OrderRow(
                                orderId: '#${snapshot.recentOrders[i].id}',
                                amount: snapshot.recentOrders[i].amountLabel,
                                status: snapshot.recentOrders[i].status,
                                statusColor: _statusColor(
                                  snapshot.recentOrders[i].status,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: AppSpacing.s16),
                _CardSection(
                  title: 'Product Upload Status',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UploadStatusRow(
                        label: 'Successful',
                        value: '${snapshot.uploadStatus.successful}',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 12),
                      _UploadStatusRow(
                        label: 'On Hold',
                        value: '${snapshot.uploadStatus.onHold}',
                        icon: Icons.pause_circle_outline,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 12),
                      _UploadStatusRow(
                        label: 'Failed',
                        value: '${snapshot.uploadStatus.failed}',
                        icon: Icons.cancel_outlined,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                const _QuickActionsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('PAID') ||
        s.contains('DELIVER') ||
        s.contains('SUCCESS') ||
        s.contains('COMPLETE')) {
      return AppColors.success;
    }
    if (s.contains('CANCEL') || s.contains('FAIL') || s.contains('REFUND')) {
      return AppColors.error;
    }
    return AppColors.warning;
  }

  String _chartSectionTitle(DashboardMetric metric) {
    return switch (metric) {
      DashboardMetric.totalSales => 'Sales Overview',
      DashboardMetric.productsSold => 'Products Sold',
      DashboardMetric.orders => 'Orders',
      DashboardMetric.inventoryValue => 'Inventory Value',
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
                helpText: 'Select start date',
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
                helpText: 'Select end date',
              );
              if (picked == null) return;
              setDialogState(() => end = picked);
            }

            return AlertDialog(
              backgroundColor: AppColors.warmWhite,
              title: Text(
                'Custom date range',
                style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CustomDateField(
                      label: 'Start date',
                      value: start,
                      onTap: pickStart,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    _CustomDateField(
                      label: 'End date',
                      value: end,
                      onTap: pickEnd,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: start != null && end != null
                      ? () => Navigator.of(dialogContext).pop((start!, end!))
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.charcoal,
                    foregroundColor: AppColors.warmWhite,
                  ),
                  child: const Text('Apply'),
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
        ? 'Select date'
        : _SellerDashboardScreenState._fmtDate(value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: AppColors.warmWhite,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            child: InputDecorator(
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Select date',
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                  borderSide: const BorderSide(color: AppColors.warmBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                  borderSide: const BorderSide(color: AppColors.warmBorder),
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
                      ? AppColors.textMutedLight
                      : AppColors.charcoal,
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
      color: AppColors.warmWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        side: BorderSide(
          color: selected ? AppColors.info : AppColors.warmBorder,
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
                        color: AppColors.charcoal,
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
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                data.subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMutedLight,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => openSellerDrawer(context),
              icon: const Icon(Icons.menu),
              color: AppColors.charcoal,
              tooltip: 'Open menu',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            Expanded(
              child: Text(
                'Dashboard',
                style: AppTypography.headline.copyWith(
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          subtitle,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({
    required this.title,
    this.trailing,
    required this.child,
  });

  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.title.copyWith(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
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

  static const _labels = {
    SalesRange.daily: 'Daily',
    SalesRange.weekly: 'Weekly',
    SalesRange.monthly: 'Monthly',
    SalesRange.quarterly: 'Quarterly',
    SalesRange.yearly: 'Yearly',
    SalesRange.custom: 'Custom',
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SalesRange>(
      key: ValueKey('${value.name}_${customStart}_$customEnd'),
      initialValue: value,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          borderSide: const BorderSide(color: AppColors.warmBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          borderSide: const BorderSide(color: AppColors.warmBorder),
        ),
      ),
      items: [
        for (final range in SalesRange.values)
          DropdownMenuItem(
            value: range,
            child: Text(_labels[range]!),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _DashboardBarChart extends StatelessWidget {
  const _DashboardBarChart({
    required this.metric,
    required this.values,
    required this.labels,
  });

  final DashboardMetric metric;
  final List<double> values;
  final List<String> labels;

  static const _chartHeight = 240.0;

  @override
  Widget build(BuildContext context) {
    final series = values.isEmpty ? const <double>[0] : values;
    final xLabels = labels.isEmpty ? const ['—'] : labels;
    final maxY = _niceMax(series);
    final yTicks = _yTicks(maxY);
    final formatY = _yFormatter(metric);

    return SizedBox(
      height: _chartHeight + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            height: _chartHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final tick in yTicks.reversed)
                  Text(
                    formatY(tick),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedLight,
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
                  height: _chartHeight,
                  child: Stack(
                    children: [
                      for (var i = 0; i < yTicks.length; i++)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: _chartHeight * (1 - yTicks[i] / maxY),
                          child: Container(
                            height: 1,
                            color: AppColors.warmBorder.withValues(alpha: 0.6),
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
                                  height: _chartHeight,
                                  color: _barColor(metric),
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
                            color: AppColors.textMutedLight,
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

  static Color _barColor(DashboardMetric metric) {
    return switch (metric) {
      DashboardMetric.totalSales => AppColors.bronze,
      DashboardMetric.productsSold => AppColors.success,
      DashboardMetric.orders => AppColors.info,
      DashboardMetric.inventoryValue => AppColors.bronzeDark,
    };
  }

  static double _niceMax(List<double> values) {
    if (values.isEmpty) return 1;
    final raw = values.reduce((a, b) => a > b ? a : b);
    if (raw <= 0) return 1;
    final magnitude = _pow10((math.log(raw) / math.ln10).floor());
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

  static double _pow10(int exp) {
    var result = 1.0;
    for (var i = 0; i < exp.abs(); i++) {
      result *= 10;
    }
    return exp < 0 ? 1 / result : result;
  }

  static List<double> _yTicks(double maxY) {
    return [0, maxY * 0.25, maxY * 0.5, maxY * 0.75, maxY];
  }

  static String Function(double) _yFormatter(DashboardMetric metric) {
    return switch (metric) {
      DashboardMetric.totalSales => (v) => AppCurrency.format(v.toStringAsFixed(2)),
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
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.value,
    required this.maxY,
    required this.height,
    required this.color,
  });

  final double value;
  final double maxY;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final barHeight = maxY > 0 ? (value / maxY) * height : 0.0;
    return SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: barHeight.clamp(0, height),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.orderId,
    required this.amount,
    required this.status,
    required this.statusColor,
  });

  final String orderId;
  final String amount;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.sandSurface,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warmWhite,
                border: Border.all(color: AppColors.warmBorder, width: 1),
                borderRadius: BorderRadius.circular(AppSpacing.r12),
              ),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderId,
                    style: AppTypography.label.copyWith(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.r8),
                    ),
                    child: Text(
                      status,
                      style: AppTypography.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: AppTypography.title.copyWith(
                color: AppColors.charcoal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadStatusRow extends StatelessWidget {
  const _UploadStatusRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.title.copyWith(
            color: AppColors.charcoal,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  static const _actions = [
    (Icons.receipt_long_outlined, 'View Orders', AppRouteNames.sellerOrders),
    (Icons.inventory_2_outlined, 'Products', AppRouteNames.sellerProducts),
    (
      Icons.analytics_outlined,
      'Diamond projects',
      AppRouteNames.savedDiamondProjects,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTypography.title.copyWith(
            color: AppColors.charcoal,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.s12,
            mainAxisSpacing: AppSpacing.s12,
            childAspectRatio: 3.2,
          ),
          itemBuilder: (context, index) {
            final (icon, label, route) = _actions[index];
            return FilledButton(
              onPressed: () {
                context.openRoute(route);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.bronze,
                foregroundColor: AppColors.warmWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: AppSpacing.s8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

