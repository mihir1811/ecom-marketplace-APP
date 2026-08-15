import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/diamond_projects/domain/diamond_project_stats_calculator.dart';
import 'package:gemstone/features/diamond_projects/domain/models/diamond_project_item.dart';

void main() {
  DiamondProjectItem item({
    required String id,
    required double carat,
    required double price,
    String shape = 'Round',
    String color = 'D',
    String clarity = 'VS1',
  }) {
    return DiamondProjectItem(
      diamondId: id,
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
}
