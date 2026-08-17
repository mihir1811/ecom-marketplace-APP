import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/diamonds/domain/models/diamond.dart';
import 'package:gemstone/features/diamonds/domain/models/diamond_listing_summary_stats.dart';

Diamond _d({required double carat, required double price}) {
  return Diamond(
    id: 'id-$carat-$price',
    shape: 'Round',
    carat: carat,
    price: price,
    cut: 'EX',
    color: 'D',
    clarity: 'VS1',
    certificate: 'GIA',
  );
}

void main() {
  test('aggregates PCS, carat, PPC, total, and avg total', () {
    final stats = DiamondListingSummaryStats.fromDiamonds([
      _d(carat: 0.5, price: 50),
      _d(carat: 1.0, price: 100),
      _d(carat: 0.5, price: 50),
    ]);

    expect(stats.pcs, 3);
    expect(stats.totalCarat, closeTo(2.0, 0.001));
    expect(stats.totalPrice, closeTo(200, 0.001));
    expect(stats.avgTotal, closeTo(200 / 3, 0.001));
    expect(stats.pricePerCarat, closeTo(100, 0.001));
  });

  test('empty list yields empty stats', () {
    expect(DiamondListingSummaryStats.fromDiamonds(const []), isEmpty);
  });
}
