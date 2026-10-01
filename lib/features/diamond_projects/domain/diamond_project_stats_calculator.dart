import 'dart:math' as math;

import 'models/diamond_project_item.dart';
import 'models/diamond_project_stats.dart';

/// Computes dashboard analytics from already-loaded project items.
///
/// Used by both the diamond project builder and the seller dashboard, so the
/// outlier rule is defined once:
///
/// * Only priced stones with a carat weight are measured; duplicates (same
///   stone listed twice) count once.
/// * Stones are compared within their product kind (single stones and melee
///   parcels are priced on different scales) and against their own shape.
/// * $/ct grows with carat weight, so the expected log $/ct for a stone's
///   size is removed first (fitted from the data once there is enough carat
///   spread to estimate it).
/// * Tukey's fences (Q1 - 1.5·IQR, Q3 + 1.5·IQR) are applied to the residual
///   of log $/ct. Prices are right-skewed, so on the raw scale the low fence
///   usually falls below zero and cheap outliers can never be flagged.
abstract final class DiamondProjectStatsCalculator {
  /// Fewer stones than this in a product kind: no fences, no outliers.
  static const minFenceSample = 5;

  /// A shape needs this many stones to be judged against its own level;
  /// smaller shapes are judged against the whole product kind.
  static const minShapeSample = 3;

  /// Carat trend is only fitted with enough stones and carat spread.
  static const minTrendSample = 8;

  static DiamondProjectStats compute(List<DiamondProjectItem> rawItems) {
    final items = _dedupe(rawItems);
    if (items.isEmpty) return DiamondProjectStats.empty;

    final priced = items.where((i) => i.price > 0).toList();
    final prices = priced.map((i) => i.price).toList()..sort();
    final totalCarat = items.fold<double>(0, (sum, i) => sum + i.carat);
    final totalPrice = priced.fold<double>(0, (sum, i) => sum + i.price);
    final withCarat = priced.where((i) => i.carat > 0);
    final pricedCarat = withCarat.fold<double>(0, (sum, i) => sum + i.carat);
    final pricedValue = withCarat.fold<double>(0, (sum, i) => sum + i.price);
    final stones = items.length;
    final mean = priced.isEmpty ? 0.0 : totalPrice / priced.length;
    final median = _median(prices);
    final mode = _mode(prices);

    final flags = <DiamondProjectItem, bool>{};
    ({double low, double high})? summaryFences;
    var summaryKindSize = 0;
    final byKind = <String, List<DiamondProjectItem>>{};
    for (final item in items) {
      if (!_measurable(item)) continue;
      (byKind[_kindKey(item)] ??= []).add(item);
    }
    for (final group in byKind.values) {
      final result = _classify(group);
      if (result == null) continue;
      flags.addAll(result.flags);
      if (group.length > summaryKindSize) {
        summaryKindSize = group.length;
        summaryFences = result.typicalFences;
      }
    }

    final outliers = <DiamondProjectOutlier>[];
    final scatter = <DiamondProjectScatterPoint>[];
    for (final item in items) {
      final isHigh = flags[item];
      final isOutlier = isHigh != null;
      if (isOutlier) {
        outliers.add(DiamondProjectOutlier(item: item, isHigh: isHigh));
      }
      scatter.add(DiamondProjectScatterPoint(item: item, isOutlier: isOutlier));
    }

    // Keep low outliers visible in the table (not buried after many highs).
    outliers.sort((a, b) {
      final side = a.isHigh == b.isHigh ? 0 : (a.isHigh ? 1 : -1);
      if (side != 0) return side;
      return a.item.ppc.compareTo(b.item.ppc);
    });

    return DiamondProjectStats(
      stones: stones,
      totalCarat: totalCarat,
      avgCarat: totalCarat / stones,
      totalPrice: totalPrice,
      avgPrice: mean,
      avgPpc: pricedCarat > 0 ? pricedValue / pricedCarat : 0,
      meanPrice: mean,
      medianPrice: median,
      modePrice: mode.$1,
      modeCount: mode.$2,
      iqrLow: summaryFences?.low ?? 0,
      iqrHigh: summaryFences?.high ?? 0,
      outliers: outliers,
      shapeMix: _mix(items, (i) => i.shape),
      colorMix: _mix(items, (i) => i.color),
      clarityMix: _mix(items, (i) => i.clarity),
      priceBuckets: _priceBuckets(priced),
      ppcBuckets: _ppcBuckets(priced.where(_measurable).toList()),
      caratBuckets: _caratBuckets(items),
      scatter: scatter,
    );
  }

  /// Flags outliers in one product kind: `flags[item]` is `true` for high and
  /// `false` for low outliers. [typicalFences] are the fences in $/ct for a
  /// stone of the group's median size and level (the summary line).
  static ({
    Map<DiamondProjectItem, bool> flags,
    ({double low, double high}) typicalFences,
  })?
  _classify(List<DiamondProjectItem> group) {
    if (group.length < minFenceSample) return null;

    final y = [for (final i in group) math.log(i.ppc)];
    final x = [for (final i in group) math.log(i.carat)];
    final yMid = _median(List.of(y)..sort());
    final xMid = _median(List.of(x)..sort());

    // Shape level: centre each sizeable shape on its own medians so a shape
    // that trades higher (or lower) is not flagged as a whole.
    final byShape = <String, List<int>>{};
    for (var k = 0; k < group.length; k++) {
      (byShape[_shapeKey(group[k].shape)] ??= []).add(k);
    }
    final yc = List<double>.filled(group.length, 0);
    final xc = List<double>.filled(group.length, 0);
    for (final indices in byShape.values) {
      final own = indices.length >= minShapeSample;
      final yLevel = own
          ? _median([for (final k in indices) y[k]]..sort())
          : yMid;
      final xLevel = own
          ? _median([for (final k in indices) x[k]]..sort())
          : xMid;
      for (final k in indices) {
        yc[k] = y[k] - yLevel;
        xc[k] = x[k] - xLevel;
      }
    }

    // Size trend: log $/ct against log carat. Fitted twice, the second time
    // without the first pass's outliers, so one extreme stone cannot bend the
    // line toward itself. Clamped to a plausible elasticity: $/ct does not
    // fall with size for comparable stones, and > 2 means the fit is chasing
    // noise.
    var slope = 0.0;
    if (group.length >= minTrendSample && _caratSpread(x)) {
      slope = _fitSlope(xc, yc, List.filled(group.length, true));
      final firstPass = _tukey(_residuals(xc, yc, slope));
      final keep = [
        for (final r in _residuals(xc, yc, slope))
          r >= firstPass.low && r <= firstPass.high,
      ];
      slope = _fitSlope(xc, yc, keep);
    }

    final residuals = _residuals(xc, yc, slope);
    final fences = _tukey(residuals);
    final flags = <DiamondProjectItem, bool>{};
    for (var k = 0; k < group.length; k++) {
      if (residuals[k] < fences.low) flags[group[k]] = false;
      if (residuals[k] > fences.high) flags[group[k]] = true;
    }
    return (
      flags: flags,
      typicalFences: (
        low: math.exp(yMid + fences.low),
        high: math.exp(yMid + fences.high),
      ),
    );
  }

  static List<double> _residuals(
    List<double> x,
    List<double> y,
    double slope,
  ) => [for (var k = 0; k < y.length; k++) y[k] - slope * x[k]];

  /// Least-squares slope through the origin of centred values.
  static double _fitSlope(List<double> x, List<double> y, List<bool> use) {
    var sxy = 0.0;
    var sxx = 0.0;
    for (var k = 0; k < x.length; k++) {
      if (!use[k]) continue;
      sxy += x[k] * y[k];
      sxx += x[k] * x[k];
    }
    if (sxx <= 1e-12) return 0;
    return (sxy / sxx).clamp(0.0, 2.0);
  }

  /// At least two carat sizes about 20% apart, each held by 3+ stones.
  static bool _caratSpread(List<double> logCarats) {
    final bins = <int, int>{};
    for (final v in logCarats) {
      final bin = (v / math.log(1.2)).floor();
      bins[bin] = (bins[bin] ?? 0) + 1;
    }
    return bins.values.where((n) => n >= 3).length >= 2;
  }

  /// Tukey fences: Q1/Q3 (linear-interpolated percentiles) ± 1.5·IQR.
  static ({double low, double high}) _tukey(List<double> values) {
    final sorted = List.of(values)..sort();
    final q1 = _percentile(sorted, 0.25);
    final q3 = _percentile(sorted, 0.75);
    final iqr = q3 - q1;
    return (low: q1 - 1.5 * iqr, high: q3 + 1.5 * iqr);
  }

  static bool _measurable(DiamondProjectItem item) {
    final ppc = item.ppc;
    return item.price > 0 && item.carat > 0 && ppc.isFinite && ppc > 0;
  }

  static List<DiamondProjectItem> _dedupe(List<DiamondProjectItem> items) {
    final seen = <String>{};
    return [
      for (final item in items)
        if (seen.add('${item.diamondId}|${item.rowId ?? ''}')) item,
    ];
  }

  static String _kindKey(DiamondProjectItem item) =>
      item.productKind.trim().toUpperCase();

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
    return [for (final e in entries) NamedCount(label: e.key, count: e.value)];
  }

  static List<NamedCount> _priceBuckets(List<DiamondProjectItem> items) {
    const edges = [1000.0, 5000.0, 10000.0, 25000.0, 50000.0];
    const labels = [
      '\$0 - \$1k',
      '\$1k - \$5k',
      '\$5k - \$10k',
      '\$10k - \$25k',
      '\$25k - \$50k',
      '\$50k+',
    ];
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

  static String _shapeKey(String? shape) {
    final raw = shape?.trim();
    if (raw == null || raw.isEmpty) return '—';
    return raw.toLowerCase();
  }

  static double _round(double value) => double.parse(value.toStringAsFixed(2));
}
