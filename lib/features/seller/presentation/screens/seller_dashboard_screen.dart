import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
  DashboardMetric _metric = DashboardMetric.totalSales;

  static const _metrics = <_MetricData>[
    _MetricData(
      metric: DashboardMetric.totalSales,
      title: 'Total Sales',
      value: r'$0.06',
      subtitle: 'Revenue from completed orders',
      icon: Icons.attach_money_outlined,
      iconColor: AppColors.bronze,
    ),
    _MetricData(
      metric: DashboardMetric.productsSold,
      title: 'Products Sold',
      value: '4',
      subtitle: '5 marked sold in inventory',
      icon: Icons.inventory_2_outlined,
      iconColor: AppColors.success,
    ),
    _MetricData(
      metric: DashboardMetric.orders,
      title: 'Orders',
      value: '10',
      subtitle: '4 delivered · 6 pending',
      icon: Icons.shopping_cart_outlined,
      iconColor: AppColors.info,
    ),
    _MetricData(
      metric: DashboardMetric.inventoryValue,
      title: 'Inventory Value',
      value: r'$232,387',
      subtitle: '827 active listings',
      icon: Icons.warehouse_outlined,
      iconColor: AppColors.bronzeDark,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TopHeader(
                subtitle:
                    'Welcome back! Here’s what’s happening with your business today.',
              ),
              SizedBox(height: AppSpacing.s16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final crossAxisCount = isWide ? 4 : 2;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _metrics.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSpacing.s16,
                      mainAxisSpacing: AppSpacing.s16,
                      childAspectRatio: isWide ? 1.55 : 1.35,
                    ),
                    itemBuilder: (context, index) {
                      final data = _metrics[index];
                      return _MetricCard(
                        data: data,
                        selected: _metric == data.metric,
                        onTap: () {
                          setState(() => _metric = data.metric);
                        },
                      );
                    },
                  );
                },
              ),
              SizedBox(height: AppSpacing.s16),
              _CardSection(
                title: _chartSectionTitle(_metric),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SalesRangeTabs(
                      value: _range,
                      onChanged: (v) {
                        setState(() => _range = v);
                      },
                    ),
                    SizedBox(height: AppSpacing.s16),
                    _DashboardBarChart(
                      metric: _metric,
                      range: _range,
                    ),
                    SizedBox(height: AppSpacing.s12),
                    Text(
                      'To 11/03/2026',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.s16),
              _CardSection(
                title: 'Recent Orders',
                trailing: TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All',
                    style: AppTypography.label.copyWith(
                      color: AppColors.charcoal,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _OrderRow(
                      orderId: '#OTB04666C',
                      amount: r'$50.02',
                      status: 'Paid',
                      statusColor: AppColors.success,
                    ),
                    SizedBox(height: AppSpacing.s12),
                    _OrderRow(
                      orderId: '#YTT0D1183E',
                      amount: r'$50.02',
                      status: 'Paid',
                      statusColor: AppColors.success,
                    ),
                    SizedBox(height: AppSpacing.s12),
                    _OrderRow(
                      orderId: '#F46338C4',
                      amount: r'$264.10',
                      status: 'Pending',
                      statusColor: AppColors.warning,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.s16),
              _CardSection(
                title: 'Product Upload Status',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _UploadStatusRow(
                      label: 'Successful',
                      value: '0',
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                    ),
                    SizedBox(height: 12),
                    _UploadStatusRow(
                      label: 'On Hold',
                      value: '0',
                      icon: Icons.pause_circle_outline,
                      color: AppColors.warning,
                    ),
                    SizedBox(height: 12),
                    _UploadStatusRow(
                      label: 'Failed',
                      value: '0',
                      icon: Icons.cancel_outlined,
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.s12),
              const _QuickActionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  String _chartSectionTitle(DashboardMetric metric) {
    return switch (metric) {
      DashboardMetric.totalSales => 'Sales Overview',
      DashboardMetric.productsSold => 'Products Sold',
      DashboardMetric.orders => 'Orders',
      DashboardMetric.inventoryValue => 'Inventory Value',
    };
  }
}

enum SalesRange { daily, weekly, monthly, quarterly }

enum DashboardMetric { totalSales, productsSold, orders, inventoryValue }

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
              SizedBox(height: AppSpacing.s8),
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
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.charcoal,
                foregroundColor: AppColors.warmWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 6),
                  Text('Add Product'),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.s8),
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
            SizedBox(height: AppSpacing.s12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SalesRangeTabs extends StatelessWidget {
  const _SalesRangeTabs({required this.value, required this.onChanged});

  final SalesRange value;
  final ValueChanged<SalesRange> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = {
      SalesRange.daily: 'Daily',
      SalesRange.weekly: 'Weekly',
      SalesRange.monthly: 'Monthly',
      SalesRange.quarterly: 'Quarterly',
    };

    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        for (final range in SalesRange.values)
          ChoiceChip(
            label: Text(labels[range]!),
            selected: value == range,
            onSelected: (_) => onChanged(range),
            labelStyle: AppTypography.label.copyWith(
              color: value == range
                  ? AppColors.warmWhite
                  : AppColors.charcoal,
            ),
            selectedColor: AppColors.charcoal,
            backgroundColor: AppColors.sandSurface,
            side: BorderSide(
              color: value == range
                  ? AppColors.charcoal
                  : AppColors.warmBorder,
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
      ],
    );
  }
}

class _DashboardBarChart extends StatelessWidget {
  const _DashboardBarChart({
    required this.metric,
    required this.range,
  });

  final DashboardMetric metric;
  final SalesRange range;

  static const _chartHeight = 240.0;

  @override
  Widget build(BuildContext context) {
    final values = _valuesFor(metric, range);
    final xLabels = _xLabelsFor(range);
    final maxY = _niceMax(values);
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
          SizedBox(width: AppSpacing.s8),
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
                            color: AppColors.warmBorder.withOpacity(0.6),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < values.length; i++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: _BarColumn(
                                  value: values[i],
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
                SizedBox(height: AppSpacing.s8),
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

  static List<double> _valuesFor(DashboardMetric metric, SalesRange range) {
    final key = (metric, range);
    const data = {
      (DashboardMetric.totalSales, SalesRange.daily):
          [0.01, 0.02, 0.0, 0.03, 0.01, 0.02, 0.01],
      (DashboardMetric.totalSales, SalesRange.weekly):
          [0.04, 0.02, 0.06, 0.03, 0.05, 0.04, 0.06],
      (DashboardMetric.totalSales, SalesRange.monthly):
          [0.03, 0.05, 0.04, 0.06, 0.05, 0.06, 0.06],
      (DashboardMetric.totalSales, SalesRange.quarterly):
          [0.02, 0.04, 0.05, 0.03, 0.06, 0.05, 0.06],
      (DashboardMetric.productsSold, SalesRange.daily):
          [1.0, 0.0, 2.0, 1.0, 0.0, 1.0, 1.0],
      (DashboardMetric.productsSold, SalesRange.weekly):
          [2.0, 1.0, 3.0, 2.0, 4.0, 1.0, 2.0],
      (DashboardMetric.productsSold, SalesRange.monthly):
          [3.0, 2.0, 4.0, 3.0, 5.0, 2.0, 4.0],
      (DashboardMetric.productsSold, SalesRange.quarterly):
          [2.0, 3.0, 4.0, 3.0, 5.0, 4.0, 4.0],
      (DashboardMetric.orders, SalesRange.daily):
          [2.0, 1.0, 3.0, 2.0, 1.0, 2.0, 1.0],
      (DashboardMetric.orders, SalesRange.weekly):
          [4.0, 2.0, 6.0, 3.0, 5.0, 4.0, 5.0],
      (DashboardMetric.orders, SalesRange.monthly):
          [6.0, 4.0, 8.0, 5.0, 10.0, 7.0, 9.0],
      (DashboardMetric.orders, SalesRange.quarterly):
          [5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 8.0],
      (DashboardMetric.inventoryValue, SalesRange.daily):
          [220000.0, 225000.0, 228000.0, 230000.0, 231000.0, 232000.0, 232387.0],
      (DashboardMetric.inventoryValue, SalesRange.weekly):
          [210000.0, 215000.0, 220000.0, 225000.0, 228000.0, 230000.0, 232387.0],
      (DashboardMetric.inventoryValue, SalesRange.monthly):
          [190000.0, 200000.0, 210000.0, 218000.0, 225000.0, 229000.0, 232387.0],
      (DashboardMetric.inventoryValue, SalesRange.quarterly):
          [180000.0, 195000.0, 205000.0, 215000.0, 222000.0, 228000.0, 232387.0],
    };
    return data[key] ?? const [1, 2, 3, 4, 5, 6, 7];
  }

  static List<String> _xLabelsFor(SalesRange range) {
    return switch (range) {
      SalesRange.daily => const [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ],
      SalesRange.weekly => const ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7'],
      SalesRange.monthly => const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
        ],
      SalesRange.quarterly => const ['Q1', 'Q2', 'Q3', 'Q4', 'Q5', 'Q6', 'Q7'],
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
      DashboardMetric.totalSales => (v) => '\$${v.toStringAsFixed(2)}',
      DashboardMetric.productsSold => (v) => v.toStringAsFixed(0),
      DashboardMetric.orders => (v) => v.toStringAsFixed(0),
      DashboardMetric.inventoryValue => (v) {
          if (v >= 1000) {
            return '\$${(v / 1000).toStringAsFixed(0)}k';
          }
          return '\$${v.toStringAsFixed(0)}';
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
            SizedBox(width: AppSpacing.s16),
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
                  SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
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
        SizedBox(width: AppSpacing.s12),
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
    (Icons.add_box_outlined, 'Add Product'),
    (Icons.receipt_long_outlined, 'View Orders'),
    (Icons.bar_chart_outlined, 'Analytics'),
    (Icons.format_list_bulleted, 'Inventory'),
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
        SizedBox(height: AppSpacing.s12),
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
            final (icon, label) = _actions[index];
            return FilledButton(
              onPressed: () {},
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
                  SizedBox(width: AppSpacing.s8),
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

