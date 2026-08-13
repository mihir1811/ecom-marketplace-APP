import '../../../../core/utils/app_currency.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../../refunds/domain/models/refund_request.dart';
import '../../domain/models/seller_insights.dart';

/// Builds dashboard and analytics snapshots from live orders and refunds.
abstract final class SellerInsightsAggregator {
  static const _paidStatuses = {
    'PAID',
    'CAPTURED',
    'SUCCESS',
    'COMPLETED',
    'DELIVERED',
  };

  static SellerDashboardSnapshot dashboard({
    required List<PaymentOrder> orders,
    required SellerDashboardParams params,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final window = _windowForSales(params, clock);
    final inWindow = _inRange(orders, window.$1, window.$2);
    final paid = inWindow.where(_isPaid).toList();

    final sales = _sumUsd(paid);
    final units = _unitsSold(paid);
    final pendingCount = inWindow.where((o) => !_isPaid(o)).length;
    final buckets = _bind(
      orders,
      _salesBucketDefs(params, clock, window.$1, window.$2),
    );

    return SellerDashboardSnapshot(
      metrics: [
        DashboardMetricCard(
          metric: DashboardMetric.totalSales,
          title: 'Total Sales',
          value: AppCurrency.usd(sales),
          subtitle: 'Revenue from completed orders',
        ),
        DashboardMetricCard(
          metric: DashboardMetric.productsSold,
          title: 'Products Sold',
          value: '$units',
          subtitle: '$units units on paid orders',
        ),
        DashboardMetricCard(
          metric: DashboardMetric.orders,
          title: 'Orders',
          value: '${inWindow.length}',
          subtitle: '${paid.length} paid · $pendingCount pending',
        ),
        DashboardMetricCard(
          metric: DashboardMetric.inventoryValue,
          title: 'Inventory Value',
          value: AppCurrency.usd(0),
          subtitle: 'Listing inventory is not on the orders API',
        ),
      ],
      chart: InsightsChartSeries(
        values: [
          for (final bucket in buckets) _metricValue(params.metric, bucket.$2),
        ],
        labels: [for (final bucket in buckets) bucket.$1],
        endDate: window.$2,
      ),
      recentOrders: _recent(orders),
      fetchedAt: clock,
    );
  }

  static SellerAnalyticsSnapshot analytics({
    required List<PaymentOrder> orders,
    required List<RefundRequest> refunds,
    required AnalyticsRange range,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final current = _windowForAnalytics(range, clock);
    final span = current.$2.difference(current.$1);
    final previous = (current.$1.subtract(span), current.$1);

    final currentOrders = _inRange(orders, current.$1, current.$2);
    final previousOrders = _inRange(orders, previous.$1, previous.$2);
    final currentPaid = currentOrders.where(_isPaid).toList();
    final previousPaid = previousOrders.where(_isPaid).toList();

    final revenue = _sumUsd(currentPaid);
    final prevRevenue = _sumUsd(previousPaid);
    final aov = currentPaid.isEmpty ? 0.0 : revenue / currentPaid.length;
    final prevAov =
        previousPaid.isEmpty ? 0.0 : prevRevenue / previousPaid.length;
    final units = _unitsSold(currentPaid);
    final prevUnits = _unitsSold(previousPaid);

    final buckets = _bind(
      orders,
      _analyticsBucketDefs(range, clock, current.$1, current.$2),
    );

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
          value: '${currentOrders.length}',
          delta: _deltaLabel(
            currentOrders.length.toDouble(),
            previousOrders.length.toDouble(),
          ),
          deltaUp: currentOrders.length >= previousOrders.length,
        ),
        AnalyticsKpi(
          title: 'Avg. Order Value',
          value: AppCurrency.usd(aov),
          delta: _deltaLabel(aov, prevAov),
          deltaUp: aov >= prevAov,
        ),
        AnalyticsKpi(
          title: 'Units Sold',
          value: _compact(units.toDouble()),
          delta: _deltaLabel(units.toDouble(), prevUnits.toDouble()),
          deltaUp: units >= prevUnits,
        ),
      ],
      revenueSeries: InsightsChartSeries(
        values: [
          for (final bucket in buckets) _sumUsd(bucket.$2.where(_isPaid)),
        ],
        labels: [for (final bucket in buckets) bucket.$1],
        endDate: current.$2,
      ),
      categorySlices: _categorySlices(currentPaid),
      orderStatus: _statusRows(currentOrders),
      engagement: [
        AnalyticsEngagementMetric(
          label: 'Units Sold',
          value: _compact(units.toDouble()),
          hint: 'Items on paid orders',
        ),
        AnalyticsEngagementMetric(
          label: 'Refund Requests',
          value: '${refunds.length}',
          hint: 'Seller refund inbox',
        ),
        AnalyticsEngagementMetric(
          label: 'Paid Rate',
          value: currentOrders.isEmpty
              ? '0%'
              : '${((currentPaid.length / currentOrders.length) * 100).toStringAsFixed(1)}%',
          hint: 'Paid orders ÷ all orders',
        ),
        AnalyticsEngagementMetric(
          label: 'Unique Products',
          value: '${_uniqueProducts(currentPaid)}',
          hint: 'Distinct SKUs on paid orders',
        ),
      ],
      fetchedAt: clock,
    );
  }

  static List<(String, List<PaymentOrder>)> _bind(
    List<PaymentOrder> orders,
    List<(String, DateTime, DateTime)> defs,
  ) {
    return [
      for (final def in defs) (def.$1, _inRange(orders, def.$2, def.$3)),
    ];
  }

  static bool _isPaid(PaymentOrder order) =>
      _paidStatuses.contains(order.status.toUpperCase());

  static double _sumUsd(Iterable<PaymentOrder> orders) {
    var total = 0.0;
    for (final order in orders) {
      total += order.amountUsd > 0 ? order.amountUsd : order.amount;
    }
    return total;
  }

  static int _unitsSold(Iterable<PaymentOrder> orders) {
    var units = 0;
    for (final order in orders) {
      if (order.items.isEmpty) {
        units += 1;
        continue;
      }
      for (final item in order.items) {
        units += item.quantity;
      }
    }
    return units;
  }

  static int _uniqueProducts(Iterable<PaymentOrder> orders) {
    final ids = <String>{};
    for (final order in orders) {
      for (final item in order.items) {
        if (item.productId.isNotEmpty) ids.add(item.productId);
      }
    }
    return ids.length;
  }

  static double _metricValue(
    DashboardMetric metric,
    List<PaymentOrder> bucket,
  ) {
    final paid = bucket.where(_isPaid).toList();
    return switch (metric) {
      DashboardMetric.totalSales => _sumUsd(paid),
      DashboardMetric.productsSold => _unitsSold(paid).toDouble(),
      DashboardMetric.orders => bucket.length.toDouble(),
      DashboardMetric.inventoryValue => 0,
    };
  }

  static List<PaymentOrder> _inRange(
    List<PaymentOrder> orders,
    DateTime start,
    DateTime end,
  ) {
    return [
      for (final order in orders)
        if (order.createdAt != null &&
            !order.createdAt!.isBefore(start) &&
            !order.createdAt!.isAfter(end))
          order,
    ];
  }

  static List<DashboardRecentOrder> _recent(List<PaymentOrder> orders) {
    final sorted = [...orders]..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return [
      for (final order in sorted.take(5))
        DashboardRecentOrder(
          id: order.receipt ?? order.id,
          amountLabel: AppCurrency.usd(
            order.amountUsd > 0 ? order.amountUsd : order.amount,
          ),
          status: _titleCase(order.status),
        ),
    ];
  }

  static List<AnalyticsCategorySlice> _categorySlices(
    List<PaymentOrder> paid,
  ) {
    final totals = <String, double>{};
    for (final order in paid) {
      if (order.items.isEmpty) {
        totals['Other'] = (totals['Other'] ?? 0) +
            (order.amountUsd > 0 ? order.amountUsd : order.amount);
        continue;
      }
      for (final item in order.items) {
        final label = _categoryLabel(item.productType);
        totals[label] = (totals[label] ?? 0) + item.lineTotal;
      }
    }
    final sum = totals.values.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) return const [];
    final slices = [
      for (final entry in totals.entries)
        AnalyticsCategorySlice(entry.key, (entry.value / sum) * 100),
    ]..sort((a, b) => b.value.compareTo(a.value));
    return slices;
  }

  static List<AnalyticsStatusRow> _statusRows(List<PaymentOrder> orders) {
    final counts = <String, int>{};
    for (final order in orders) {
      final label = _titleCase(order.status);
      counts[label] = (counts[label] ?? 0) + 1;
    }
    final rows = [
      for (final entry in counts.entries)
        AnalyticsStatusRow(entry.key, entry.value),
    ]..sort((a, b) => b.count.compareTo(a.count));
    return rows;
  }

  static String _categoryLabel(String type) {
    final t = type.toLowerCase();
    if (t.contains('diamond')) return 'Diamonds';
    if (t.contains('watch')) return 'Watches';
    if (t.contains('jewel')) return 'Jewelry';
    if (t.contains('gem')) return 'Gemstones';
    if (t.contains('bullion')) return 'Bullions';
    if (type.trim().isEmpty) return 'Other';
    return _titleCase(type);
  }

  static (DateTime, DateTime) _windowForSales(
    SellerDashboardParams params,
    DateTime clock,
  ) {
    final end = DateTime(clock.year, clock.month, clock.day, 23, 59, 59);
    if (params.range == SalesRange.custom &&
        params.customStart != null &&
        params.customEnd != null) {
      return (
        DateTime(
          params.customStart!.year,
          params.customStart!.month,
          params.customStart!.day,
        ),
        DateTime(
          params.customEnd!.year,
          params.customEnd!.month,
          params.customEnd!.day,
          23,
          59,
          59,
        ),
      );
    }
    return switch (params.range) {
      SalesRange.daily => (end.subtract(const Duration(days: 6)), end),
      SalesRange.weekly => (end.subtract(const Duration(days: 48)), end),
      SalesRange.monthly => (DateTime(end.year, end.month - 6, 1), end),
      SalesRange.quarterly => (DateTime(end.year, end.month - 18, 1), end),
      SalesRange.yearly => (DateTime(end.year - 6, 1, 1), end),
      SalesRange.custom => (end.subtract(const Duration(days: 29)), end),
    };
  }

  static (DateTime, DateTime) _windowForAnalytics(
    AnalyticsRange range,
    DateTime clock,
  ) {
    final end = DateTime(clock.year, clock.month, clock.day, 23, 59, 59);
    return switch (range) {
      AnalyticsRange.last7 => (end.subtract(const Duration(days: 6)), end),
      AnalyticsRange.last30 => (end.subtract(const Duration(days: 29)), end),
      AnalyticsRange.last90 => (end.subtract(const Duration(days: 89)), end),
      AnalyticsRange.year => (DateTime(end.year, 1, 1), end),
    };
  }

  static List<(String, DateTime, DateTime)> _salesBucketDefs(
    SellerDashboardParams params,
    DateTime clock,
    DateTime start,
    DateTime end,
  ) {
    return switch (params.range) {
      SalesRange.daily => _dayBuckets(start, end),
      SalesRange.weekly =>
        _fixedBuckets(end, days: 7, count: 7, prefix: 'W'),
      SalesRange.monthly => _monthBuckets(clock, 7),
      SalesRange.quarterly => _quarterBuckets(clock, 7),
      SalesRange.yearly => _yearBuckets(clock, 7),
      SalesRange.custom => _dayBuckets(start, end, maxBuckets: 7),
    };
  }

  static List<(String, DateTime, DateTime)> _analyticsBucketDefs(
    AnalyticsRange range,
    DateTime clock,
    DateTime start,
    DateTime end,
  ) {
    return switch (range) {
      AnalyticsRange.last7 => _dayBuckets(start, end),
      AnalyticsRange.last30 =>
        _fixedBuckets(end, days: 7, count: 5, prefix: 'W'),
      AnalyticsRange.last90 => _monthBuckets(clock, 6),
      AnalyticsRange.year => _monthBuckets(clock, 7),
    };
  }

  static List<(String, DateTime, DateTime)> _dayBuckets(
    DateTime start,
    DateTime end, {
    int maxBuckets = 7,
  }) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = end.difference(start).inDays + 1;
    final step = days <= maxBuckets ? 1 : (days / maxBuckets).ceil();
    final buckets = <(String, DateTime, DateTime)>[];
    var cursor = DateTime(start.year, start.month, start.day);
    while (!cursor.isAfter(end) && buckets.length < maxBuckets) {
      final bucketEnd = DateTime(
        cursor.year,
        cursor.month,
        cursor.day + step - 1,
        23,
        59,
        59,
      );
      final clampedEnd = bucketEnd.isAfter(end) ? end : bucketEnd;
      buckets.add((labels[(cursor.weekday - 1) % 7], cursor, clampedEnd));
      cursor = cursor.add(Duration(days: step));
    }
    return buckets;
  }

  static List<(String, DateTime, DateTime)> _fixedBuckets(
    DateTime end, {
    required int days,
    required int count,
    required String prefix,
  }) {
    final buckets = <(String, DateTime, DateTime)>[];
    var cursor = DateTime(end.year, end.month, end.day, 23, 59, 59);
    for (var i = count - 1; i >= 0; i--) {
      final bucketEnd = cursor;
      final bucketStart = DateTime(
        cursor.year,
        cursor.month,
        cursor.day - (days - 1),
      );
      buckets.insert(0, ('$prefix${i + 1}', bucketStart, bucketEnd));
      cursor = bucketStart.subtract(const Duration(seconds: 1));
    }
    return buckets;
  }

  static List<(String, DateTime, DateTime)> _monthBuckets(
    DateTime clock,
    int count,
  ) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return [
      for (var i = count - 1; i >= 0; i--)
        (
          names[DateTime(clock.year, clock.month - i, 1).month - 1],
          DateTime(clock.year, clock.month - i, 1),
          DateTime(clock.year, clock.month - i + 1, 0, 23, 59, 59),
        ),
    ];
  }

  static List<(String, DateTime, DateTime)> _quarterBuckets(
    DateTime clock,
    int count,
  ) {
    final buckets = <(String, DateTime, DateTime)>[];
    var year = clock.year;
    var quarter = ((clock.month - 1) ~/ 3) + 1;
    for (var i = 0; i < count; i++) {
      final startMonth = (quarter - 1) * 3 + 1;
      buckets.insert(0, (
        'Q$quarter',
        DateTime(year, startMonth, 1),
        DateTime(year, startMonth + 3, 0, 23, 59, 59),
      ));
      quarter -= 1;
      if (quarter < 1) {
        quarter = 4;
        year -= 1;
      }
    }
    return buckets;
  }

  static List<(String, DateTime, DateTime)> _yearBuckets(
    DateTime clock,
    int count,
  ) {
    return [
      for (var i = count - 1; i >= 0; i--)
        (
          '${clock.year - i}',
          DateTime(clock.year - i, 1, 1),
          DateTime(clock.year - i, 12, 31, 23, 59, 59),
        ),
    ];
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

  static String _titleCase(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Unknown';
    final parts = trimmed
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'));
    return [
      for (final part in parts)
        part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
    ].join(' ');
  }
}
