import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/jewelry_checkout/data/mappers/jewelry_checkout_mapper.dart';
import 'package:gemstone/features/jewelry_checkout/domain/models/bag_line.dart';

void main() {
  const engraved = BagLine(
    skuId: '961863e3-7e8f-4f94-98d7-acd9372232f9',
    quantity: 1,
    listingSlug: 'half-eternity-ring',
    title: 'Half Eternity Ring',
    options: {'Metal': '10K Yellow Gold'},
    customValues: {'Personalisation': 'A & R', 'Blank': '  '},
  );

  test('the same variant engraved differently is a different line', () {
    const plain = BagLine(
      skuId: '961863e3-7e8f-4f94-98d7-acd9372232f9',
      quantity: 1,
      listingSlug: 'half-eternity-ring',
      title: 'Half Eternity Ring',
    );
    expect(engraved.key, isNot(plain.key));
    expect(plain.key, plain.skuId);
    // Blank values don't change the key (the API drops them too).
    expect(
      engraved.key,
      BagLine.keyFor(engraved.skuId, {'Personalisation': 'A & R'}),
    );
  });

  test('request body drops blank custom values', () {
    expect(engraved.toRequestJson(), {
      'skuId': '961863e3-7e8f-4f94-98d7-acd9372232f9',
      'quantity': 1,
      'customValues': {'Personalisation': 'A & R'},
    });
  });

  test('bag lines survive a storage round trip', () {
    final restored = BagLine.fromJson(engraved.toJson())!;
    expect(restored.key, engraved.key);
    expect(restored.options, engraved.options);
    expect(BagLine.fromJson({'quantity': 2}), isNull);
  });

  test('quote matches lines by sku plus custom values', () {
    final quote = JewelryCheckoutMapper.quote({
      'lines': [
        {
          'skuId': '961863e3-7e8f-4f94-98d7-acd9372232f9',
          'listingSlug': 'half-eternity-ring',
          'title': 'Half Eternity Ring',
          'shopName': 'Pureyou',
          'options': {'Metal': '10K Yellow Gold'},
          'customValues': {'Personalisation': 'A & R'},
          'unitPrice': 98610,
          'quantity': 1,
          'lineTotal': 98610,
          'maxQuantity': 20,
          'cancellationWindowHours': 24,
          'problem': null,
        },
        {
          'skuId': '00000000-0000-4000-8000-000000000000',
          'listingId': null,
          'title': 'A piece that is no longer listed',
          'shopName': '',
          'unitPrice': 0,
          'quantity': 2,
          'lineTotal': 0,
          'maxQuantity': 0,
          'problem': 'This piece is no longer available.',
        },
      ],
      'subtotal': 98610,
      'shipping': 0,
      'total': 98610,
      'currency': 'INR',
      'ready': false,
    });
    expect(quote.ready, isFalse);
    expect(quote.total, 98610);
    final line = quote.lineFor(engraved)!;
    expect(line.unitPrice, 98610);
    expect(line.problem, isNull);
    expect(quote.lines.last.problem, 'This piece is no longer available.');
  });

  test('checkout session keeps the amount in paise', () {
    final s = JewelryCheckoutMapper.session({
      'orderId': '4b0c2f8e',
      'orderNumber': 'JW-261026-7KQ2M',
      'razorpayOrderId': 'order_1',
      'amount': 9861000,
      'currency': 'INR',
      'keyId': 'rzp_live_x',
      'name': 'jewellery by GemWorld',
      'description': 'Order JW-261026-7KQ2M',
      'prefill': {'name': 'Asha', 'email': '', 'contact': '+91 98765 43210'},
    });
    expect(s.amountPaise, 9861000);
    expect(s.prefill, {'name': 'Asha', 'contact': '+91 98765 43210'});
  });

  test('order parses shipments, updates and cancel state', () {
    final order = JewelryCheckoutMapper.orderFrom({
      'id': '4b0c2f8e',
      'orderNumber': 'JW-261026-7KQ2M',
      'status': 'PAID',
      'subtotal': 98610,
      'shippingTotal': 0,
      'total': 98610,
      'refundedTotal': 0,
      'shippingAddress': {
        'fullName': 'Asha Mehta',
        'phone': '+91 98765 43210',
        'line1': '12, Rose Villa',
        'city': 'Jaipur',
        'state': 'Rajasthan',
        'postalCode': '302001',
        'country': 'IN',
      },
      'paidAt': '2026-10-26T09:12:40.118Z',
      'items': [
        {
          'id': 'c1a90d3e',
          'title': 'Half Eternity Ring',
          'shopName': 'Pureyou',
          'unitPrice': 98610,
          'quantity': 1,
          'lineTotal': 98610,
          'status': 'ACCEPTED',
          'canCancel': true,
          'cancellableUntil': '2026-10-27T09:12:40.118Z',
          'refundAmount': null,
        },
      ],
      'shipments': [
        {
          'shopName': 'Pureyou',
          'status': 'ACCEPTED',
          'itemIds': ['c1a90d3e'],
          'expectedDeliveryAt': '2026-11-04',
          'sellerPhone': '+91 98290 00000',
          'updates': [
            {'id': 'e7d1', 'status': 'ACCEPTED', 'message': 'Thank you!'},
            {'id': 'placed-d9e4', 'status': 'PLACED'},
          ],
        },
      ],
    });
    expect(order.isPaid, isTrue);
    expect(order.address?.postalCode, '302001');
    expect(order.items.single.canCancel, isTrue);
    expect(order.items.single.cancellableUntil, isNotNull);
    expect(order.shipments.single.expectedDeliveryAt, '2026-11-04');
    expect(order.shipments.single.updates.last.id, startsWith('placed-'));
  });
}
