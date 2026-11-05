import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/features/diamond_projects/domain/diamond_project_stats_calculator.dart';
import 'package:gemworld/features/diamond_projects/domain/models/diamond_project_item.dart';

void main() {
  DiamondProjectItem item({
    required String id,
    required double carat,
    required double price,
    String shape = 'Round',
    String color = 'D',
    String clarity = 'VS1',
    String kind = 'SINGLE',
  }) {
    return DiamondProjectItem(
      diamondId: id,
      productKind: kind,
      stockNumber: id,
      shape: shape,
      color: color,
      clarity: clarity,
      carat: carat,
      price: price,
      pricePerCarat: carat == 0 ? 0 : price / carat,
    );
  }

  test('empty selection yields empty stats', () {
    expect(DiamondProjectStatsCalculator.compute(const []).isEmpty, isTrue);
  });

  test('computes KPIs, mode, and IQR outliers from loaded items', () {
    final items = [
      item(id: 'a', carat: 1, price: 80),
      item(id: 'b', carat: 1, price: 85),
      item(id: 'c', carat: 1, price: 90),
      item(id: 'd', carat: 1, price: 90),
      item(id: 'e', carat: 1.5, price: 400, color: 'E'),
    ];

    final stats = DiamondProjectStatsCalculator.compute(items);

    expect(stats.stones, 5);
    expect(stats.totalCarat, closeTo(5.5, 0.001));
    expect(stats.totalPrice, 745);
    expect(stats.modePrice, 90);
    expect(stats.modeCount, 2);
    expect(stats.outliers, hasLength(1));
    expect(stats.outliers.first.item.diamondId, 'e');
    expect(stats.outliers.first.isHigh, isTrue);
    expect(stats.shapeMix.first.label, 'Round');
    expect(stats.colorMix.first.label, 'D');
    expect(stats.scatter.where((p) => p.isOutlier), hasLength(1));
  });

  test('IQR outliers use \$/ct, not total price', () {
    final items = [
      item(id: 'a', carat: 1, price: 1000),
      item(id: 'b', carat: 1, price: 1050),
      item(id: 'c', carat: 1, price: 1100),
      item(id: 'd', carat: 1, price: 1150),
      // Large stone: high total price, normal $/ct — not an outlier.
      item(id: 'e', carat: 5, price: 5500),
      // Small stone: extreme $/ct — Tukey IQR outlier.
      item(id: 'f', carat: 0.3, price: 900),
    ];

    final stats = DiamondProjectStatsCalculator.compute(items);

    expect(stats.outliers, hasLength(1));
    expect(stats.outliers.first.item.diamondId, 'f');
    expect(stats.outliers.first.isHigh, isTrue);
    expect(
      stats.scatter.where((p) => p.isOutlier).map((p) => p.item.diamondId),
      ['f'],
    );
  });

  test('detects both low and high \$/ct Tukey outliers', () {
    final items = [
      item(id: 'low', carat: 1, price: 20),
      item(id: 'a', carat: 1, price: 100),
      item(id: 'b', carat: 1, price: 102),
      item(id: 'c', carat: 1, price: 104),
      item(id: 'd', carat: 1, price: 106),
      item(id: 'e', carat: 1, price: 108),
      item(id: 'f', carat: 1, price: 110),
      item(id: 'g', carat: 1, price: 112),
      item(id: 'h', carat: 1, price: 114),
      item(id: 'i', carat: 1, price: 116),
      item(id: 'high', carat: 1, price: 400),
    ];

    final stats = DiamondProjectStatsCalculator.compute(items);

    expect(stats.outliers, hasLength(2));
    expect(stats.outliers[0].item.diamondId, 'low');
    expect(stats.outliers[0].isHigh, isFalse);
    expect(stats.outliers[1].item.diamondId, 'high');
    expect(stats.outliers[1].isHigh, isTrue);
  });

  test('zero \$/ct rows do not hide true low outliers', () {
    final items = [
      item(id: 'z1', carat: 1, price: 0),
      item(id: 'z2', carat: 1, price: 0),
      item(id: 'z3', carat: 1, price: 0),
      item(id: 'low', carat: 1, price: 40),
      item(id: 'a', carat: 1, price: 100),
      item(id: 'b', carat: 1, price: 105),
      item(id: 'c', carat: 1, price: 110),
      item(id: 'd', carat: 1, price: 115),
      item(id: 'e', carat: 1, price: 120),
      item(id: 'high', carat: 1, price: 500),
    ];

    final stats = DiamondProjectStatsCalculator.compute(items);
    final ids = stats.outliers.map((o) => o.item.diamondId).toList();

    expect(ids, containsAll(['low', 'high']));
    expect(ids, isNot(contains('z1')));
    expect(
      stats.outliers.firstWhere((o) => o.item.diamondId == 'low').isHigh,
      isFalse,
    );
    expect(
      stats.outliers.firstWhere((o) => o.item.diamondId == 'high').isHigh,
      isTrue,
    );
  });

  test('shape-local IQR finds outliers hidden by mixed-shape inventory', () {
    // Rounds cluster tightly; one Round is a clear $/ct outlier inside Round.
    // Ovals sit on a much higher $/ct band, which would widen a global IQR
    // fence enough to hide the Round outlier (seller-dashboard case).
    final items = [
      item(id: 'r1', carat: 1, price: 100, shape: 'Round'),
      item(id: 'r2', carat: 1, price: 102, shape: 'Round'),
      item(id: 'r3', carat: 1, price: 104, shape: 'Round'),
      item(id: 'r4', carat: 1, price: 106, shape: 'Round'),
      item(id: 'r5', carat: 1, price: 108, shape: 'Round'),
      item(id: 'r6', carat: 1, price: 110, shape: 'Round'),
      item(id: 'rOut', carat: 1, price: 400, shape: 'Round'),
      item(id: 'o1', carat: 1, price: 900, shape: 'Oval'),
      item(id: 'o2', carat: 1, price: 920, shape: 'Oval'),
      item(id: 'o3', carat: 1, price: 940, shape: 'Oval'),
      item(id: 'o4', carat: 1, price: 960, shape: 'Oval'),
    ];

    final stats = DiamondProjectStatsCalculator.compute(items);
    final ids = stats.outliers.map((o) => o.item.diamondId).toList();

    expect(ids, contains('rOut'));
    expect(
      stats.outliers.firstWhere((o) => o.item.diamondId == 'rOut').isHigh,
      isTrue,
    );
  });

  test('analytics payload stays compact', () {
    final stats = DiamondProjectStatsCalculator.compute([
      item(id: 'a', carat: 1, price: 100),
      item(id: 'b', carat: 1, price: 120),
    ]);
    final json = DiamondProjectStatsCalculator.toAnalytics(stats);
    expect(json['stones'], 2);
    expect(json.containsKey('scatter'), isFalse);
    expect(json['shapeMix'], isA<Map>());
  });
  group('outlier audit', () {
    // $/ct for a comparable stone grows with size (elasticity ~1.2 here).
    double fairPpc(double carat) => 4000 * math.pow(carat, 1.2).toDouble();
    const noise = [1.0, 1.03, 0.97, 1.02, 0.98];

    List<DiamondProjectItem> sizedInventory() {
      final items = <DiamondProjectItem>[];
      var n = 0;
      for (final (carat, count) in [
        (0.3, 5),
        (0.5, 5),
        (0.7, 4),
        (1.0, 3),
        (3.0, 3),
      ]) {
        for (var i = 0; i < count; i++) {
          final ppc = fairPpc(carat) * noise[n % noise.length];
          items.add(item(id: 's${n++}', carat: carat, price: ppc * carat));
        }
      }
      return items;
    }

    test('large stones priced normally for their size are not outliers', () {
      // Raw $/ct IQR flagged every 3 ct stone here (≈15k/ct vs a 1–4k/ct
      // middle) although each is priced in line with its size.
      final stats = DiamondProjectStatsCalculator.compute(sizedInventory());
      expect(stats.outliers, isEmpty);
    });

    test('genuine extremes are still found once size is accounted for', () {
      final stats = DiamondProjectStatsCalculator.compute([
        ...sizedInventory(),
        item(id: 'tooHigh', carat: 1.0, price: fairPpc(1.0) * 3),
        item(id: 'tooLow', carat: 0.5, price: fairPpc(0.5) * 0.5 * 0.25),
      ]);
      final flagged = {
        for (final o in stats.outliers) o.item.diamondId: o.isHigh,
      };
      expect(flagged, {'tooHigh': true, 'tooLow': false});
    });

    test('melee parcels are not judged against single stones', () {
      final stats = DiamondProjectStatsCalculator.compute([
        for (var i = 0; i < 10; i++)
          item(id: 'single$i', carat: 1, price: 5000 + i * 40.0),
        item(id: 'melee1', carat: 1, price: 600, kind: 'MELEE'),
        item(id: 'melee2', carat: 1, price: 640, kind: 'MELEE'),
      ]);
      expect(stats.outliers, isEmpty);
    });

    test('too few comparable stones: no outliers are claimed', () {
      final stats = DiamondProjectStatsCalculator.compute([
        item(id: 'a', carat: 1, price: 100),
        item(id: 'b', carat: 1, price: 102),
        item(id: 'c', carat: 1, price: 104),
        item(id: 'd', carat: 1, price: 900),
      ]);
      expect(stats.outliers, isEmpty);
      expect(stats.scatter.any((p) => p.isOutlier), isFalse);
    });

    test('a low outlier in right-skewed prices is detected', () {
      // Raw IQR puts the low fence at -$90/ct, so nothing can ever be low.
      final stats = DiamondProjectStatsCalculator.compute([
        for (final (i, p) in [
          100.0,
          110.0,
          120.0,
          140.0,
          170.0,
          210.0,
          260.0,
          320.0,
          400.0,
        ].indexed)
          item(id: 'n$i', carat: 1, price: p),
        item(id: 'low', carat: 1, price: 30),
      ]);
      expect(stats.outliers.map((o) => (o.item.diamondId, o.isHigh)), [
        ('low', false),
      ]);
    });

    test('duplicates count once and unpriced stones do not skew prices', () {
      final stats = DiamondProjectStatsCalculator.compute([
        item(id: 'a', carat: 1, price: 100),
        item(id: 'a', carat: 1, price: 100),
        item(id: 'b', carat: 1, price: 300),
        item(id: 'unpriced', carat: 1, price: 0),
      ]);
      expect(stats.stones, 3);
      expect(stats.meanPrice, 200);
      expect(stats.medianPrice, 200);
      expect(stats.avgPpc, 200);
      expect(stats.ppcBuckets.fold<int>(0, (sum, b) => sum + b.count), 2);
    });

    test('summary fences bracket a typical stone', () {
      final stats = DiamondProjectStatsCalculator.compute(sizedInventory());
      expect(stats.iqrLow, greaterThan(0));
      expect(stats.iqrHigh, greaterThan(stats.iqrLow));
    });
  });
}
