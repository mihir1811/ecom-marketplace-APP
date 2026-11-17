import 'package:flutter_test/flutter_test.dart';

import 'package:gemworld/core/utils/melee_purchase_math.dart';
import 'package:gemworld/features/cart/data/mappers/cart_mapper.dart';
import 'package:gemworld/features/cart/domain/models/cart_summary.dart';

void main() {
  test('proportional lot price matches detail 10/23 of 234.34', () {
    final price = MeleePurchaseMath.proportionalLotPrice(
      lotPrice: 234.34,
      inCarat: false,
      selectedPcs: 10,
      selectedCarat: 101.9,
      totalPcs: 23,
      totalCarat: 234.34,
    );
    expect(price, closeTo(101.89, 0.01));
  });

  test('cart line prefers calculatedPrice over pricePerPcs', () {
    final price = MeleePurchaseMath.linePriceFromCartPayload(
      specifications: {
        'purchaseUnit': 'pcs',
        'selectedPcs': 10,
        'selectedCarat': 101.9,
        'calculatedPrice': 101.89,
      },
      product: {
        'totalPrice': 234.34,
        'pricePerPcs': 2.34,
        'totalPcs': 23,
        'totalCaratWeight': 234.34,
      },
    );
    expect(price, closeTo(101.89, 0.01));
  });

  test('cart line recomputes from lot share when calculatedPrice missing', () {
    final price = MeleePurchaseMath.linePriceFromCartPayload(
      specifications: {
        'purchaseUnit': 'pcs',
        'selectedPcs': 10,
        'selectedCarat': 101.9,
      },
      product: {
        'totalPrice': 234.34,
        'pricePerPcs': 2.34,
        'totalPcs': 23,
        'totalCaratWeight': 234.34,
      },
    );
    expect(price, closeTo(101.89, 0.01));
  });

  test('cartItemFromJson uses melee calculatedPrice', () {
    final item = CartMapper.cartItemFromJson({
      'id': 'cart-1',
      'productId': 'prod-1',
      'productType': 'meleeDiamond',
      'quantity': 1,
      'specifications': {
        'purchaseUnit': 'pcs',
        'selectedPcs': 10,
        'selectedCarat': 101.9,
        'calculatedPrice': 101.89,
      },
      'product': {
        'id': 'prod-1',
        'stockNumber': 'stk-0012',
        'totalPrice': 234.34,
        'pricePerPcs': 2.34,
        'totalPcs': 23,
        'totalCaratWeight': 234.34,
        'shape': 'pan',
      },
    });
    expect(item.displayPriceUsd, closeTo(101.89, 0.01));
    expect(item.quantity, 1);
  });

  test('mergeSummaryPrices keeps melee line over wrong summary total', () {
    final hydrated = CartMapper.cartItemFromJson({
      'id': 'cart-1',
      'productId': 'prod-1',
      'productType': 'meleeDiamond',
      'quantity': 1,
      'specifications': {
        'purchaseUnit': 'pcs',
        'selectedPcs': 10,
        'selectedCarat': 101.9,
        'calculatedPrice': 101.89,
      },
      'product': {
        'id': 'prod-1',
        'totalPrice': 234.34,
        'pricePerPcs': 2.34,
        'totalPcs': 23,
        'totalCaratWeight': 234.34,
      },
    });
    const summary = CartSummary(
      items: [
        CartSummaryLine(
          cartId: 'cart-1',
          productId: 'prod-1',
          productType: 'meleeDiamond',
          quantity: 1,
          unitPrice: 2.34,
          lineTotal: 23.40,
          name: '101.9ct pan Melee · 10 pcs',
        ),
      ],
      subtotal: 23.40,
      discountedSubtotal: 23.40,
    );
    final merged = CartMapper.mergeSummaryPrices([hydrated], summary);
    expect(merged.single.displayPriceUsd, closeTo(101.89, 0.01));
    expect(merged.single.title, '101.9ct pan Melee · 10 pcs');

    final reconciled = CartMapper.reconcileSummaryPrices(summary, merged);
    expect(reconciled.subtotal, closeTo(101.89, 0.01));
    expect(reconciled.discountedSubtotal, closeTo(101.89, 0.01));
  });

  test('jewellery cart prefers selected variant calculatedPrice', () {
    final item = CartMapper.cartItemFromJson({
      'id': 'cart-j1',
      'productId': 'jewel-1',
      'productType': 'jewellery',
      'quantity': 1,
      'specifications': {
        'stoneWeight': '3ct',
        'variantId': 'var-3ct',
        'unitPrice': 2300000,
        'calculatedPrice': 2300000,
      },
      'product': {
        'id': 'jewel-1',
        'name': 'Platinum Diamond Tennis Bracelet',
        'totalPrice': 1312000,
        'variants': [
          {'id': 'var-2ct', 'totalStoneCarat': 2, 'totalPrice': 1312000},
          {'id': 'var-3ct', 'totalStoneCarat': 3, 'totalPrice': 2300000},
        ],
      },
    });
    expect(item.displayPriceUsd, closeTo(2300000, 0.01));
    expect(item.title, contains('3ct'));
  });

  test(
    'jewellery cart resolves variant price when calculatedPrice missing',
    () {
      final price = MeleePurchaseMath.linePriceFromCartPayload(
        specifications: {'stoneWeight': '3ct', 'variantId': 'var-3ct'},
        product: {
          'totalPrice': 1312000,
          'variants': [
            {'id': 'var-2ct', 'totalStoneCarat': 2, 'totalPrice': 1312000},
            {'id': 'var-3ct', 'totalStoneCarat': 3, 'totalPrice': 2300000},
          ],
        },
      );
      expect(price, closeTo(2300000, 0.01));
    },
  );
}
