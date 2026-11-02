import '../../../../core/utils/app_currency.dart';
import '../../../refunds/domain/models/refund_request.dart';
import '../../domain/models/seller_insights.dart';
import '../../domain/models/seller_stats.dart';
import '../../domain/seller_chart_buckets.dart';

/// What to request from `GET /seller/stats` for a dashboard range, and the
/// calendar buckets the chart shows.
class SellerDashboardPlan {
  factory SellerDashboardPlan({
    required SellerStatsQuery query,
    List<SellerChartBucket>? buckets,
  }) {
    final source = SellerChartBuckets.forQuery(query);
    return SellerDashboardPlan._(query, source, buckets ?? source);
  }

  const SellerDashboardPlan._(this.query, this.sourceBuckets, this.buckets);

  final SellerStatsQuery query;

  /// Buckets the server returns for [query].
  final List<SellerChartBucket> sourceBuckets;

  /// Buckets the chart shows. Differs from [sourceBuckets] only for the
  /// quarterly view: the server has no quarter period, so its monthly values
  /// are summed per calendar quarter.
  final List<SellerChartBucket> buckets;

  bool get regroups => !identical(buckets, sourceBuckets);
}

/// Builds dashboard and analytics snapshots from seller-scoped stats.
///
/// Every chart bucket comes from the server's bucket for that period, so a
/// period before the seller had orders stays 0 instead of inheriting a later
/// value. Inventory value is a current snapshot and is only placed in the
/// bucket that contains today.
abstract final class SellerInsightsAggregator {
  /// Bars shown by each preset range; the last one is the current period
  /// to date.
  static const presetBuckets = 7;

  static SellerDashboardPlan dashboardPlan(
    SellerDashboardParams params, {
    DateTime? now,
  }) {
    final today = _day(now ?? DateTime.now());
    final y = today.year;
    final m = today.month;
    final d = today.day;
    const back = presetBuckets - 1;
    SellerStatsQuery query(SellerStatsPeriod period, DateTime from) =>
        SellerStatsQuery(period: period, from: from, to: today);

    switch (params.range) {
      case SalesRange.daily:
        return SellerDashboardPlan(
          query: query(SellerStatsPeriod.daily, DateTime(y, m, d - back)),
        );
      case SalesRange.weekly:
        // Monday-aligned so the first bar is a whole week, as the server
        // buckets weeks from Monday.
        final monday = SellerChartBuckets.weekStart(today);
        return SellerDashboardPlan(
          query: query(
            SellerStatsPeriod.weekly,
            DateTime(monday.year, monday.month, monday.day - 7 * back),
          ),
        );
      case SalesRange.monthly:
        return SellerDashboardPlan(
          query: query(SellerStatsPeriod.monthly, DateTime(y, m - back, 1)),
        );
      case SalesRange.quarterly:
        final from = DateTime(
          y,
          SellerChartBuckets.quarterStartMonth(m) - 3 * back,
          1,
        );
        return SellerDashboardPlan(
          query: query(SellerStatsPeriod.monthly, from),
          buckets: SellerChartBuckets.quarters(from, today),
        );
      case SalesRange.yearly:
        return SellerDashboardPlan(
          query: query(SellerStatsPeriod.yearly, DateTime(y - back, 1, 1)),
        );
      case SalesRange.custom:
        final start = params.customStart;
        final end = params.customEnd;
        if (start == null || end == null) {
          return SellerDashboardPlan(
            query: query(SellerStatsPeriod.daily, DateTime(y, m, d - 29)),
          );
        }
        var from = _day(start);
        var to = _day(end);
        if (to.isBefore(from)) (from, to) = (to, from);
        return SellerDashboardPlan(
          query: SellerStatsQuery(
            period: _periodForSpan(from, to),
            from: from,
            to: to,
          ),
        );
    }
  }

  /// Why [stats] cannot be charted as [query]'s buckets, or `null` when it
  /// can. Guards against showing e.g. monthly totals under "Daily".
  static String? periodMismatch(SellerStats stats, SellerStatsQuery query) {
    final requested = query.period.name;
    final charts = [
      stats.salesChart,
      stats.productsSoldChart,
      stats.ordersChart,
    ];
    for (final chart in charts) {
      final served = chart.period;
      if (served != null && served != requested) {
        return 'The server returned $served figures instead of $requested. '
            'Please try again.';
      }
    }
    final buckets = SellerChartBuckets.forQuery(query);
    for (final chart in charts) {
      if (SellerChartBuckets.align(chart, buckets) == null) {
        return 'The server returned figures that do not match the '
            '$requested periods requested. Please try again.';
      }
    }
    return null;
  }

  static SellerDashboardSnapshot dashboard({
    required SellerStats stats,
    required SellerDashboardPlan plan,
    SellerDashboardParams params = const SellerDashboardParams(),
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final buckets = plan.buckets;
    List<double> series(SellerStatsChart chart) {
      final aligned =
          SellerChartBuckets.align(chart, plan.sourceBuckets) ??
          List<double>.filled(plan.sourceBuckets.length, 0);
      return plan.regroups
          ? SellerChartBuckets.regroup(aligned, plan.sourceBuckets, buckets)
          : aligned;
    }

    final sales = series(stats.salesChart);
    final units = series(stats.productsSoldChart);
    final orders = series(stats.ordersChart);

    // Inventory has no history: only the bucket holding today gets today's
    // value, so a past range never shows it.
    final today = _day(clock);
    final totalSales = _sum(sales);
    final unitsSold = _sum(units).round();
    final orderCount = _sum(orders).round();

    return SellerDashboardSnapshot(
      metrics: [
        DashboardMetricCard(
          metric: DashboardMetric.totalSales,
          title: 'Total Sales',
          value: AppCurrency.usd(totalSales),
          subtitle: 'Revenue from paid orders in this period',
        ),
        DashboardMetricCard(
          metric: DashboardMetric.productsSold,
          title: 'Products Sold',
          value: '$unitsSold',
          subtitle: '$unitsSold units on paid orders',
        ),
        DashboardMetricCard(
          metric: DashboardMetric.orders,
          title: 'Orders',
          value: '$orderCount',
          subtitle:
              'All time: ${stats.deliveredOrders} delivered · '
              '${stats.pendingOrders} pending',
        ),
        DashboardMetricCard(
          metric: DashboardMetric.inventoryValue,
          title: 'Inventory Value',
          value: AppCurrency.usd(stats.inventoryValue),
          subtitle: stats.inventoryValue > 0
              ? '${stats.liveProducts} live listings today'
              : 'No priced active listings',
        ),
      ],
      chartBuckets: [
        for (var i = 0; i < buckets.length; i++)
          InsightsChartBucket(
            label: buckets[i].label,
            detail: buckets[i].detail,
            totalSales: sales[i],
            productsSold: units[i],
            orders: orders[i],
            inventoryValue: buckets[i].contains(today)
                ? stats.inventoryValue
                : 0,
          ),
      ],
      chartEndDate: plan.query.to,
      recentOrders: const [],
      fetchedAt: clock,
      params: params,
    );
  }

  /// Current window and the equally long window right before it.
  static ({SellerStatsQuery current, SellerStatsQuery previous})
  analyticsQueries(
    AnalyticsRange range, {
    DateTime? now,
    DateTime? from,
    DateTime? to,
  }) {
    final today = _day(now ?? DateTime.now());
    final y = today.year;
    final m = today.month;
    final d = today.day;

    ({SellerStatsQuery current, SellerStatsQuery previous}) trailing(
      int days,
      SellerStatsPeriod period,
    ) {
      return (
        current: SellerStatsQuery(
          period: period,
          from: DateTime(y, m, d - (days - 1)),
          to: today,
        ),
        previous: SellerStatsQuery(
          period: period,
          from: DateTime(y, m, d - (2 * days - 1)),
          to: DateTime(y, m, d - days),
        ),
      );
    }

    return switch (range) {
      AnalyticsRange.last7 => trailing(7, SellerStatsPeriod.daily),
      AnalyticsRange.last30 => trailing(30, SellerStatsPeriod.daily),
      AnalyticsRange.last90 => trailing(90, SellerStatsPeriod.weekly),
      AnalyticsRange.custom => _customQueries(
        from ?? DateTime(y, m, d - 29),
        to ?? today,
      ),
      // Year to date vs the same days of last year.
      AnalyticsRange.year => (
        current: SellerStatsQuery(
          period: SellerStatsPeriod.monthly,
          from: DateTime(y, 1, 1),
          to: today,
        ),
        previous: SellerStatsQuery(
          period: SellerStatsPeriod.monthly,
          from: DateTime(y - 1, 1, 1),
          to: _clampDay(y - 1, m, d),
        ),
      ),
    };
  }

  /// Picked days vs the equally long stretch right before them.
  static ({SellerStatsQuery current, SellerStatsQuery previous}) _customQueries(
    DateTime start,
    DateTime end,
  ) {
    var from = _day(start);
    var to = _day(end);
    if (to.isBefore(from)) (from, to) = (to, from);
    final days = _daysBetween(from, to) + 1;
    final period = _periodForSpan(from, to);
    return (
      current: SellerStatsQuery(period: period, from: from, to: to),
      previous: SellerStatsQuery(
        period: period,
        from: DateTime(from.year, from.month, from.day - days),
        to: DateTime(from.year, from.month, from.day - 1),
      ),
    );
  }

  static SellerAnalyticsSnapshot analytics({
    required SellerStats current,
    required SellerStats previous,
    required SellerStatsQuery currentQuery,
    required List<RefundRequest> refunds,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final buckets = SellerChartBuckets.forQuery(currentQuery);
    final revenueValues =
        SellerChartBuckets.align(current.salesChart, buckets) ??
        List<double>.filled(buckets.length, 0);
    final revenue = _sum(revenueValues);
    final prevRevenue = previous.salesChart.total;
    final orders = current.ordersChart.total;
    final prevOrders = previous.ordersChart.total;
    final units = current.productsSoldChart.total;
    final prevUnits = previous.productsSoldChart.total;
    final aov = orders <= 0 ? 0.0 : revenue / orders;
    final prevAov = prevOrders <= 0 ? 0.0 : prevRevenue / prevOrders;

    return SellerAnalyticsSnapshot(
      kpis: [
        AnalyticsKpi(
          title: 'Revenue',
          value: AppCurrency.usd(revenue),
          delta: _deltaLabel(revenue, prevRevenue),
          deltaUp: revenue >= prevRevenue,
        ),
        AnalyticsKpi(
          title: 'Orders',
          value: '${orders.round()}',
          delta: _deltaLabel(orders, prevOrders),
          deltaUp: orders >= prevOrders,
        ),
        AnalyticsKpi(
          title: 'Avg. Order Value',
          value: AppCurrency.usd(aov),
          delta: _deltaLabel(aov, prevAov),
          deltaUp: aov >= prevAov,
        ),
        AnalyticsKpi(
          title: 'Units Sold',
          value: _compact(units),
          delta: _deltaLabel(units, prevUnits),
          deltaUp: units >= prevUnits,
        ),
      ],
      revenueSeries: InsightsChartSeries(
        values: revenueValues,
        labels: [for (final b in buckets) b.label],
        details: [for (final b in buckets) b.detail],
        endDate: currentQuery.to,
      ),
      // `/seller/stats` has no category or per-status breakdown for a date
      // range; empty lists show the screen's "no data" state instead of
      // figures from the wrong orders.
      categorySlices: const [],
      orderStatus: const [],
      engagement: [
        AnalyticsEngagementMetric(
          label: 'Units Sold',
          value: _compact(units),
          hint: 'Items on paid orders',
        ),
        AnalyticsEngagementMetric(
          label: 'Refund Requests',
          value: '${refunds.length}',
          hint: 'Seller refund inbox',
        ),
        AnalyticsEngagementMetric(
          label: 'Live Listings',
          value: '${current.liveProducts}',
          hint: 'Available, hold or memo today',
        ),
        AnalyticsEngagementMetric(
          label: 'Sold Products',
          value: '${current.soldProducts}',
          hint: 'Listings marked sold',
        ),
      ],
      fetchedAt: clock,
    );
  }

  /// Bucket size that keeps a custom range readable (about 4–31 bars).
  static SellerStatsPeriod _periodForSpan(DateTime from, DateTime to) {
    final days = _daysBetween(from, to) + 1;
    if (days <= 31) return SellerStatsPeriod.daily;
    if (days <= 182) return SellerStatsPeriod.weekly;
    if (days <= 3 * 366) return SellerStatsPeriod.monthly;
    return SellerStatsPeriod.yearly;
  }

  static double _sum(List<double> values) =>
      values.fold(0, (sum, v) => sum + v);

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Calendar-day difference, immune to DST hour shifts.
  static int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  /// [day] in [month] of [year], clamped to the month's length (Feb 29).
  static DateTime _clampDay(int year, int month, int day) {
    final last = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > last ? last : day);
  }

  static String _deltaLabel(double current, double previous) {
    if (previous == 0) {
      if (current == 0) return '0%';
      return '+100%';
    }
    final pct = ((current - previous) / previous.abs()) * 100;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  static String _compact(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}
