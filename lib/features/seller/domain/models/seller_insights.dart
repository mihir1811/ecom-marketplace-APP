/// Time window for seller dashboard charts.
enum SalesRange { daily, weekly, monthly, quarterly, yearly, custom }

/// Metric driving the dashboard KPI cards and bar chart.
enum DashboardMetric { totalSales, productsSold, orders, inventoryValue }

/// Time window for the analytics screen.
enum AnalyticsRange { last7, last30, last90, year }

/// One KPI card on the seller dashboard.
class DashboardMetricCard {
  const DashboardMetricCard({
    required this.metric,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final DashboardMetric metric;
  final String title;
  final String value;
  final String subtitle;
}

/// Bar / line series with axis labels.
class InsightsChartSeries {
  const InsightsChartSeries({
    required this.values,
    required this.labels,
    this.endDate,
  });

  final List<double> values;
  final List<String> labels;
  final DateTime? endDate;
}

/// Compact recent-order row on the dashboard.
class DashboardRecentOrder {
  const DashboardRecentOrder({
    required this.id,
    required this.amountLabel,
    required this.status,
  });

  final String id;
  final String amountLabel;
  final String status;
}

/// Product-upload counters when the backend supplies them.
class DashboardUploadStatus {
  const DashboardUploadStatus({
    this.successful = 0,
    this.onHold = 0,
    this.failed = 0,
  });

  final int successful;
  final int onHold;
  final int failed;
}

/// Live seller dashboard payload assembled from backend orders.
class SellerDashboardSnapshot {
  const SellerDashboardSnapshot({
    required this.metrics,
    required this.chart,
    required this.recentOrders,
    this.uploadStatus = const DashboardUploadStatus(),
    required this.fetchedAt,
  });

  final List<DashboardMetricCard> metrics;
  final InsightsChartSeries chart;
  final List<DashboardRecentOrder> recentOrders;
  final DashboardUploadStatus uploadStatus;
  final DateTime fetchedAt;
}

/// Analytics KPI with period-over-period change.
class AnalyticsKpi {
  const AnalyticsKpi({
    required this.title,
    required this.value,
    required this.delta,
    required this.deltaUp,
  });

  final String title;
  final String value;
  final String delta;
  final bool deltaUp;
}

class AnalyticsCategorySlice {
  const AnalyticsCategorySlice(this.label, this.value);

  final String label;
  final double value;
}

class AnalyticsStatusRow {
  const AnalyticsStatusRow(this.label, this.count);

  final String label;
  final int count;
}

class AnalyticsEngagementMetric {
  const AnalyticsEngagementMetric({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;
}

/// Live seller analytics payload assembled from backend orders and refunds.
class SellerAnalyticsSnapshot {
  const SellerAnalyticsSnapshot({
    required this.kpis,
    required this.revenueSeries,
    required this.categorySlices,
    required this.orderStatus,
    required this.engagement,
    required this.fetchedAt,
  });

  final List<AnalyticsKpi> kpis;
  final InsightsChartSeries revenueSeries;
  final List<AnalyticsCategorySlice> categorySlices;
  final List<AnalyticsStatusRow> orderStatus;
  final List<AnalyticsEngagementMetric> engagement;
  final DateTime fetchedAt;
}

/// Dashboard fetch arguments (range + optional custom dates + chart metric).
class SellerDashboardParams {
  const SellerDashboardParams({
    this.range = SalesRange.monthly,
    this.metric = DashboardMetric.totalSales,
    this.customStart,
    this.customEnd,
  });

  final SalesRange range;
  final DashboardMetric metric;
  final DateTime? customStart;
  final DateTime? customEnd;

  @override
  bool operator ==(Object other) {
    return other is SellerDashboardParams &&
        other.range == range &&
        other.metric == metric &&
        other.customStart == customStart &&
        other.customEnd == customEnd;
  }

  @override
  int get hashCode => Object.hash(range, metric, customStart, customEnd);
}
