import 'package:flutter_test/flutter_test.dart';

import 'package:gemstone/features/product_detail/domain/models/jewelry_unit_pricing.dart';

void main() {
  group('JewelryUnitPricing', () {
    test('deducts discount from component sum for grand total', () {
      final pricing = JewelryUnitPricing.from(
        metalPrice: 125000,
        stonePrice: 2160000,
        makingCharge: 25000,
        discountAmount: 10000,
        totalPrice: 2300000,
      );

      expect(pricing.listPrice, 2310000);
      expect(pricing.discount, 10000);
      expect(pricing.netPrice, 2300000);
      expect(pricing.hasDiscount, isTrue);
      expect(pricing.discountPercent, closeTo(10000 / 2310000 * 100, 0.0001));
    });

    test('uses api total when components are missing', () {
      final pricing = JewelryUnitPricing.from(
        discountAmount: 0,
        totalPrice: 25000,
      );

      expect(pricing.listPrice, 25000);
      expect(pricing.netPrice, 25000);
      expect(pricing.hasDiscount, isFalse);
    });

    test('flat price with discount treats api total as net', () {
      final pricing = JewelryUnitPricing.from(
        discountAmount: 5000,
        totalPrice: 85000,
      );

      expect(pricing.listPrice, 90000);
      expect(pricing.netPrice, 85000);
      expect(pricing.discountPercent, closeTo(5000 / 90000 * 100, 0.0001));
    });
  });
}
