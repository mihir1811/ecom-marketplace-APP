import '../../domain/models/seller_stats.dart';

/// Parses the `GET /seller/stats` envelope (`{ success, message, data }`).
abstract final class SellerStatsMapper {
  static SellerStats fromEnvelope(Map<String, dynamic>? root) {
    final data = _map(root?['data']);
    final orders = _map(data['orders']);
    return SellerStats(
      salesChart: chartFromJson(data['salesChart']),
      productsSoldChart: chartFromJson(data['productsSoldChart']),
      ordersChart: chartFromJson(data['ordersChart']),
      deliveredOrders: _num(orders['delivered'])?.toInt() ?? 0,
      pendingOrders: _num(orders['pending'])?.toInt() ?? 0,
      inventoryValue: _num(data['inventoryValue']) ?? 0,
      liveProducts:
          (_num(data['liveProducts']) ?? _num(data['totalProducts']))
              ?.toInt() ??
          0,
      soldProducts: _num(data['soldProducts'])?.toInt() ?? 0,
    );
  }

  /// Labels and values are aligned by index; a missing or non-numeric value
  /// is 0, never the neighbouring bucket's value.
  static SellerStatsChart chartFromJson(Object? json) {
    final map = _map(json);
    final rawLabels = map['labels'];
    final rawValues = map['values'];
    final labels = rawLabels is List
        ? [for (final l in rawLabels) l?.toString() ?? '']
        : const <String>[];
    final values = rawValues is List
        ? [for (final v in rawValues) _num(v) ?? 0.0]
        : const <double>[];
    final length = labels.length > values.length
        ? labels.length
        : values.length;
    final period = map['period']?.toString().trim().toLowerCase();
    return SellerStatsChart(
      period: period == null || period.isEmpty ? null : period,
      labels: [
        for (var i = 0; i < length; i++) i < labels.length ? labels[i] : '',
      ],
      values: [
        for (var i = 0; i < length; i++) i < values.length ? values[i] : 0,
      ],
    );
  }

  static Map<String, dynamic> _map(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return const {};
  }

  static double? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v.isFinite ? v.toDouble() : null;
    final parsed = double.tryParse(v.toString());
    return parsed != null && parsed.isFinite ? parsed : null;
  }
}
