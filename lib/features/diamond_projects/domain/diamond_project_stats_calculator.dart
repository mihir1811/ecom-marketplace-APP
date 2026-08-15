import 'models/diamond_project_item.dart';
import 'models/diamond_project_stats.dart';

/// Computes dashboard analytics from already-loaded project items.
abstract final class DiamondProjectStatsCalculator {
  static DiamondProjectStats compute(List<DiamondProjectItem> items) {
    if (items.isEmpty) return DiamondProjectStats.empty;

    final prices = items.map((i) => i.price).toList()..sort();
    final totalCarat = items.fold<double>(0, (sum, i) => sum + i.carat);
    final totalPrice = items.fold<double>(0, (sum, i) => sum + i.price);
    final stones = items.length;
    final mean = totalPrice / stones;
    final median = _median(prices);
    final mode = _mode(prices);
    final q1 = _percentile(prices, 0.25);
    final q3 = _percentile(prices, 0.75);
    final iqr = q3 - q1;
    final low = q1 - 1.5 * iqr;
    final high = q3 + 1.5 * iqr;

    final outliers = <DiamondProjectOutlier>[];
    final scatter = <DiamondProjectScatterPoint>[];
    for (final item in items) {
      final isOutlier = item.price < low || item.price > high;
      if (isOutlier) {
        outliers.add(
          DiamondProjectOutlier(item: item, isHigh: item.price > high),
        );
      }
      scatter.add(
        DiamondProjectScatterPoint(item: item, isOutlier: isOutlier),
      );
    }

    return DiamondProjectStats(
      stones: stones,
      totalCarat: totalCarat,
      avgCarat: totalCarat / stones,
      totalPrice: totalPrice,
      avgPrice: mean,
      avgPpc: totalCarat > 0 ? totalPrice / totalCarat : 0,
      meanPrice: mean,
      medianPrice: median,
      modePrice: mode.$1,
      modeCount: mode.$2,
      iqrLow: low,
      iqrHigh: high,
      outliers: outliers,
      shapeMix: _mix(items, (i) => i.shape),
      colorMix: _mix(items, (i) => i.color),
      clarityMix: _mix(items, (i) => i.clarity),
      priceBuckets: _priceBuckets(items),
      ppcBuckets: _ppcBuckets(items),
      caratBuckets: _caratBuckets(items),
      scatter: scatter,
    );
  }

  /// Compact payload for `analytics` — KPIs + mixes, no scatter points.
  static Map<String, dynamic> toAnalytics(DiamondProjectStats stats) {
    return {
      'stones': stats.stones,
      'totalCarat': _round(stats.totalCarat),
      'avgCarat': _round(stats.avgCarat),
      'totalPrice': _round(stats.totalPrice),
      'avgPrice': _round(stats.avgPrice),
      'avgPpc': _round(stats.avgPpc),
      'median': _round(stats.medianPrice),
      'mode': _round(stats.modePrice),
      'modeCount': stats.modeCount,
      'outlierCount': stats.outliers.length,
      'iqrLow': _round(stats.iqrLow),
      'iqrHigh': _round(stats.iqrHigh),
      'shapeMix': {for (final e in stats.shapeMix) e.label: e.count},
      'colorMix': {for (final e in stats.colorMix) e.label: e.count},
      'clarityMix': {for (final e in stats.clarityMix) e.label: e.count},
    };
  }

  static List<NamedCount> _mix(
    List<DiamondProjectItem> items,
    String? Function(DiamondProjectItem) pick,
  ) {
    final counts = <String, int>{};
    for (final item in items) {
      final raw = pick(item)?.trim();
      final key = (raw == null || raw.isEmpty) ? '—' : raw;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries) NamedCount(label: e.key, count: e.value),
    ];
  }

  static List<NamedCount> _priceBuckets(List<DiamondProjectItem> items) {
    const edges = [1000.0, 5000.0, 10000.0, 25000.0, 50000.0];
    const labels = ['\$0 - \$1k', '\$1k - \$5k', '\$5k - \$10k', '\$10k - \$25k', '\$25k - \$50k', '\$50k+'];
    return _bucket(items.map((i) => i.price), edges, labels);
  }

  static List<NamedCount> _ppcBuckets(List<DiamondProjectItem> items) {
    const edges = [100.0, 120.0, 140.0, 160.0, 200.0];
    const labels = [
      '\$0 - \$100/ct',
      '\$100 - \$120/ct',
      '\$120 - \$140/ct',
      '\$140 - \$160/ct',
      '\$160 - \$200/ct',
      '\$200+/ct',
    ];
    return _bucket(items.map((i) => i.ppc), edges, labels);
  }

  static List<NamedCount> _caratBuckets(List<DiamondProjectItem> items) {
    const edges = [0.5, 1.0, 1.5, 2.0, 3.0];
    const labels = [
      '0 - 0.5 ct',
      '0.5 - 1 ct',
      '1 - 1.5 ct',
      '1.5 - 2 ct',
      '2 - 3 ct',
      '3+ ct',
    ];
    return _bucket(items.map((i) => i.carat), edges, labels);
  }

  static List<NamedCount> _bucket(
    Iterable<double> values,
    List<double> edges,
    List<String> labels,
  ) {
    final counts = List<int>.filled(labels.length, 0);
    for (final value in values) {
      var index = edges.length;
      for (var i = 0; i < edges.length; i++) {
        if (value < edges[i]) {
          index = i;
          break;
        }
      }
      counts[index]++;
    }
    return [
      for (var i = 0; i < labels.length; i++)
        if (counts[i] > 0) NamedCount(label: labels[i], count: counts[i]),
    ];
  }

  static double _median(List<double> sorted) {
    if (sorted.isEmpty) return 0;
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  static (double, int) _mode(List<double> sorted) {
    if (sorted.isEmpty) return (0, 0);
    var best = sorted.first;
    var bestCount = 1;
    var current = sorted.first;
    var currentCount = 1;
    for (var i = 1; i < sorted.length; i++) {
      if ((sorted[i] - current).abs() < 1e-9) {
        currentCount++;
      } else {
        if (currentCount > bestCount) {
          best = current;
          bestCount = currentCount;
        }
        current = sorted[i];
        currentCount = 1;
      }
    }
    if (currentCount > bestCount) {
      best = current;
      bestCount = currentCount;
    }
    return (best, bestCount);
  }

  static double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0;
    if (sorted.length == 1) return sorted.first;
    final pos = (sorted.length - 1) * p;
    final lo = pos.floor();
    final hi = pos.ceil();
    if (lo == hi) return sorted[lo];
    final t = pos - lo;
    return sorted[lo] * (1 - t) + sorted[hi] * t;
  }

  static double _round(double value) =>
      double.parse(value.toStringAsFixed(2));
}
