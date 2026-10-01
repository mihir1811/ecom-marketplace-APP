/// Server period for `GET /seller/stats` chart buckets.
enum SellerStatsPeriod { daily, weekly, monthly, yearly }

/// One `GET /seller/stats` request: bucket size plus an inclusive day range.
class SellerStatsQuery {
  const SellerStatsQuery({
    required this.period,
    required this.from,
    required this.to,
  });

  final SellerStatsPeriod period;

  /// First and last calendar day (local dates, time ignored).
  final DateTime from;
  final DateTime to;

  Map<String, String> toQueryParameters() => {
    'period': period.name,
    'fromDate': _day(from),
    'toDate': _day(to),
  };

  /// Cache key; equal queries hit the network once per TTL.
  String get key => '${period.name}|${_day(from)}|${_day(to)}';

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is SellerStatsQuery && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// One server chart: a value per bucket, aligned with [labels].
class SellerStatsChart {
  const SellerStatsChart({
    this.labels = const [],
    this.values = const [],
    this.period,
  });

  static const empty = SellerStatsChart();

  final List<String> labels;
  final List<double> values;

  /// Bucket size the server actually used (`SalesChartDto.period`), when sent.
  final String? period;

  double get total => values.fold(0, (sum, v) => sum + v);
}

/// Seller-scoped dashboard data from `GET /seller/stats`.
///
/// Charts only contain orders that include this seller's items, bucketed by
/// order date inside the requested range; periods without orders are 0.
class SellerStats {
  const SellerStats({
    this.salesChart = SellerStatsChart.empty,
    this.productsSoldChart = SellerStatsChart.empty,
    this.ordersChart = SellerStatsChart.empty,
    this.deliveredOrders = 0,
    this.pendingOrders = 0,
    this.inventoryValue = 0,
    this.liveProducts = 0,
    this.soldProducts = 0,
  });

  final SellerStatsChart salesChart;
  final SellerStatsChart productsSoldChart;
  final SellerStatsChart ordersChart;

  /// All-time order counts (not limited to the requested range).
  final int deliveredOrders;
  final int pendingOrders;

  /// Current value of live listings — a snapshot, there is no history.
  final double inventoryValue;
  final int liveProducts;
  final int soldProducts;
}
