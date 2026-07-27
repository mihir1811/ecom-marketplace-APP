import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/seller_layout.dart';

/// Seller analytics screen: revenue trend, category mix, order status,
/// top products, and engagement metrics.
class SellerAnalyticsScreen extends StatefulWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  State<SellerAnalyticsScreen> createState() => _SellerAnalyticsScreenState();
}

enum _AnalyticsRange { last7, last30, last90, year }

class _SellerAnalyticsScreenState extends State<SellerAnalyticsScreen> {
  _AnalyticsRange _range = _AnalyticsRange.last30;

  static const _rangeLabels = {
    _AnalyticsRange.last7: 'Last 7 days',
    _AnalyticsRange.last30: 'Last 30 days',
    _AnalyticsRange.last90: 'Last 90 days',
    _AnalyticsRange.year: 'This year',
  };

  @override
  Widget build(BuildContext context) {
    final data = _AnalyticsData.forRange(_range);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          child: Column(
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
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  Expanded(
                    child: Text(
                      'Analytics',
                      style: AppTypography.headline.copyWith(
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Performance insights across sales, orders, and traffic.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              _RangeSelector(
                value: _range,
                labels: _rangeLabels,
                onChanged: (v) => setState(() => _range = v),
              ),
              const SizedBox(height: AppSpacing.s16),
              _KpiGrid(kpis: data.kpis),
              const SizedBox(height: AppSpacing.s16),
              _AnalyticsCard(
                title: 'Revenue Trend',
                subtitle: 'Gross revenue over time',
                child: _RevenueLineChart(
                  values: data.revenueSeries,
                  labels: data.revenueLabels,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  final catMix = _AnalyticsCard(
                    title: 'Sales by Category',
                    subtitle: 'Revenue share per catalog',
                    child: _CategoryDonut(slices: data.categorySlices),
                  );
                  final orderStatus = _AnalyticsCard(
                    title: 'Order Status',
                    subtitle: 'Current pipeline breakdown',
                    child: _OrderStatusBars(rows: data.orderStatus),
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
              // Top products — paused for now (not needed yet).
              // _AnalyticsCard(
              //   title: 'Top Products',
              //   subtitle: 'Best sellers by revenue',
              //   child: _TopProductsList(products: data.topProducts),
              // ),
              // const SizedBox(height: AppSpacing.s16),
              _AnalyticsCard(
                title: 'Engagement Metrics',
                subtitle: 'Listing interest and catalog performance',
                child: _EngagementGrid(metrics: data.engagement),
              ),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mock analytics data (swap with repository data when backend is ready)
// ---------------------------------------------------------------------------

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

class _TopProduct {
  const _TopProduct(this.name, this.category, this.revenue, this.units);

  final String name;
  final String category;
  final double revenue;
  final int units;
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

class _AnalyticsData {
  const _AnalyticsData({
    required this.kpis,
    required this.revenueSeries,
    required this.revenueLabels,
    required this.categorySlices,
    required this.orderStatus,
    required this.topProducts,
    required this.engagement,
  });

  final List<_Kpi> kpis;
  final List<double> revenueSeries;
  final List<String> revenueLabels;
  final List<_CategorySlice> categorySlices;
  final List<_StatusRow> orderStatus;
  final List<_TopProduct> topProducts;
  final List<_EngagementMetric> engagement;

  static _AnalyticsData forRange(_AnalyticsRange range) {
    final (series, labels, revenue, orders, aov, views) = switch (range) {
      _AnalyticsRange.last7 => (
          [820.0, 1240.0, 660.0, 1480.0, 990.0, 1720.0, 1310.0],
          const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          r'$8,220',
          '31',
          r'$265',
          '2,410',
        ),
      _AnalyticsRange.last30 => (
          [3200.0, 4100.0, 3600.0, 5200.0, 4700.0, 6100.0, 5400.0, 6900.0],
          const ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8'],
          r'$39,200',
          '142',
          r'$276',
          '11,860',
        ),
      _AnalyticsRange.last90 => (
          [9800.0, 12400.0, 10900.0, 14800.0, 13200.0, 16400.0],
          const ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
          r'$77,500',
          '289',
          r'$268',
          '32,540',
        ),
      _AnalyticsRange.year => (
          [
            18200.0,
            21400.0,
            19800.0,
            24600.0,
            22900.0,
            27400.0,
            25100.0,
          ],
          const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
          r'$159,400',
          '571',
          r'$279',
          '68,220',
        ),
    };

    return _AnalyticsData(
      kpis: [
        _Kpi(
          title: 'Revenue',
          value: revenue,
          delta: '+12.4%',
          deltaUp: true,
          icon: Icons.attach_money_outlined,
          color: AppColors.bronze,
        ),
        _Kpi(
          title: 'Orders',
          value: orders,
          delta: '+8.1%',
          deltaUp: true,
          icon: Icons.shopping_cart_outlined,
          color: AppColors.info,
        ),
        _Kpi(
          title: 'Avg. Order Value',
          value: aov,
          delta: '-2.3%',
          deltaUp: false,
          icon: Icons.payments_outlined,
          color: AppColors.success,
        ),
        _Kpi(
          title: 'Product Views',
          value: views,
          delta: '+18.9%',
          deltaUp: true,
          icon: Icons.visibility_outlined,
          color: AppColors.bronzeDark,
        ),
      ],
      revenueSeries: series,
      revenueLabels: labels,
      categorySlices: const [
        _CategorySlice('Diamonds', 38, Color(0xFF5C7C9E)),
        _CategorySlice('Watches', 24, AppColors.bronze),
        _CategorySlice('Jewelry', 18, Color(0xFF8E6C88)),
        _CategorySlice('Gemstones', 12, AppColors.success),
        _CategorySlice('Bullions', 8, AppColors.charcoal),
      ],
      orderStatus: const [
        _StatusRow('Delivered', 64, AppColors.success),
        _StatusRow('Shipped', 22, AppColors.info),
        _StatusRow('Processing', 31, AppColors.warning),
        _StatusRow('Cancelled', 7, AppColors.error),
        _StatusRow('Refunded', 4, Color(0xFF8E6C88)),
      ],
      topProducts: const [
        _TopProduct('Rolex Submariner Date 41', 'Watches', 12800, 1),
        _TopProduct('2.1ct Round Brilliant, VS1', 'Diamonds', 9400, 2),
        _TopProduct('Burmese Ruby Ring 18K', 'Jewelry', 5200, 3),
        _TopProduct('Ceylon Sapphire 3.4ct', 'Gemstones', 3800, 4),
        _TopProduct('Omega Speedmaster Pro', 'Watches', 3400, 1),
      ],
      engagement: const [
        _EngagementMetric(
          label: 'Product Views',
          value: '11.9k',
          hint: 'Listing page opens',
          icon: Icons.visibility_outlined,
          color: AppColors.bronzeDark,
        ),
        _EngagementMetric(
          label: 'Wishlist Saves',
          value: '386',
          hint: 'Buyers saved your listings',
          icon: Icons.favorite_border,
          color: AppColors.error,
        ),
        _EngagementMetric(
          label: 'Conversion Rate',
          value: '1.2%',
          hint: 'Orders ÷ product views',
          icon: Icons.percent_outlined,
          color: AppColors.success,
        ),
        _EngagementMetric(
          label: 'Active Listings',
          value: '827',
          hint: 'Products currently live',
          icon: Icons.inventory_2_outlined,
          color: AppColors.bronze,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  final _AnalyticsRange value;
  final Map<_AnalyticsRange, String> labels;
  final ValueChanged<_AnalyticsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final range in _AnalyticsRange.values) ...[
            ChoiceChip(
              label: Text(labels[range]!),
              selected: value == range,
              onSelected: (_) => onChanged(range),
              selectedColor: AppColors.charcoal,
              labelStyle: AppTypography.label.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    value == range ? AppColors.warmWhite : AppColors.charcoal,
              ),
              side: const BorderSide(color: AppColors.warmBorder),
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
                color: AppColors.warmWhite,
                borderRadius: BorderRadius.circular(AppSpacing.r12),
                border: Border.all(color: AppColors.warmBorder),
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
                            color: AppColors.charcoal,
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
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    children: [
                      Icon(
                        kpi.deltaUp
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 14,
                        color:
                            kpi.deltaUp ? AppColors.success : AppColors.error,
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
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.title.copyWith(
              color: AppColors.charcoal,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMutedLight,
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

class _RevenueLineChart extends StatelessWidget {
  const _RevenueLineChart({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  static const _height = 220.0;

  @override
  Widget build(BuildContext context) {
    final maxY = values.reduce(math.max) * 1.15;

    return Column(
      children: [
        SizedBox(
          height: _height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 46,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final f in const [1.0, 0.75, 0.5, 0.25, 0.0])
                      Text(
                        _fmtShort(maxY * f),
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.textMutedLight,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: CustomPaint(
                  painter: _LineChartPainter(
                    values: values,
                    maxY: maxY,
                    lineColor: AppColors.bronze,
                    fillColor: AppColors.bronze.withValues(alpha: 0.12),
                    gridColor: AppColors.warmBorder.withValues(alpha: 0.6),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            const SizedBox(width: 54),
            for (final label in labels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.textMutedLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _fmtShort(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.values,
    required this.maxY,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<double> values;
  final double maxY;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final f in const [0.0, 0.25, 0.5, 0.75, 1.0]) {
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
    for (final p in points) {
      canvas.drawCircle(p, 4.5, dotRing);
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.maxY != maxY;
}

// ---------------------------------------------------------------------------
// Category donut
// ---------------------------------------------------------------------------

class _CategoryDonut extends StatelessWidget {
  const _CategoryDonut({required this.slices});

  final List<_CategorySlice> slices;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: CustomPaint(
            painter: _DonutPainter(slices: slices, total: total),
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
                    'of revenue',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Wrap(
          spacing: AppSpacing.s16,
          runSpacing: AppSpacing.s8,
          children: [
            for (final s in slices)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${s.label} ${s.value.toStringAsFixed(0)}%',
                    style: AppTypography.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.slices, required this.total});

  final List<_CategorySlice> slices;
  final double total;

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
    for (final s in slices) {
      final sweep = (s.value / total) * 2 * math.pi;
      paint.color = s.color;
      canvas.drawArc(rect, start, sweep - 0.03, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.slices != slices;
}

// ---------------------------------------------------------------------------
// Order status horizontal bars
// ---------------------------------------------------------------------------

class _OrderStatusBars extends StatelessWidget {
  const _OrderStatusBars({required this.rows});

  final List<_StatusRow> rows;

  @override
  Widget build(BuildContext context) {
    final maxCount =
        rows.fold<int>(0, (m, r) => math.max(m, r.count)).toDouble();

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: Row(
              children: [
                SizedBox(
                  width: 84,
                  child: Text(
                    row.label,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxCount > 0 ? row.count / maxCount : 0,
                      minHeight: 10,
                      backgroundColor: AppColors.sandSurface,
                      valueColor: AlwaysStoppedAnimation(row.color),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${row.count}',
                    textAlign: TextAlign.right,
                    style: AppTypography.label.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
//   const _TopProductsList({required this.products});
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
//                 const SizedBox(width: AppSpacing.s12),
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
//                       const SizedBox(height: 3),
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(3),
//                         child: LinearProgressIndicator(
//                           value: maxRevenue > 0
//                               ? products[i].revenue / maxRevenue
//                               : 0,
//                           minHeight: 6,
//                           backgroundColor: AppColors.sandSurface,
//                           valueColor:
//                               const AlwaysStoppedAnimation(AppColors.bronze),
//                         ),
//                       ),
//                       const SizedBox(height: 2),
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
//                 const SizedBox(width: AppSpacing.s12),
//                 Text(
//                   '\$${products[i].revenue.toStringAsFixed(0)}',
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
            color: AppColors.sandSurface,
            borderRadius: BorderRadius.circular(AppSpacing.r12),
            border: Border.all(color: AppColors.warmBorder),
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
                        color: AppColors.charcoal,
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
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.hint,
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.textMutedLight,
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
