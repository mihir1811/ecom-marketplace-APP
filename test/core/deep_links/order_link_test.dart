import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/deep_links/order_link.dart';
import 'package:gemworld/features/jewelry_checkout/data/mappers/jewelry_checkout_mapper.dart';

void main() {
  const id = '3f2b8c1e-9a4d-4e6f-8b2a-1c3d5e7f9a0b';

  group('parseOrderLink', () {
    test('buyer web link', () {
      expect(
        parseOrderLink(Uri.parse('https://jewelry.gemworld.in/orders/$id')),
        const BuyerOrderLink(id),
      );
    });

    test('shop web link', () {
      expect(
        parseOrderLink(
          Uri.parse('https://jewelry.gemworld.in/seller/orders?o=$id'),
        ),
        const ShopOrderLink(id),
      );
    });

    test('path-only form the router sees', () {
      expect(
        parseOrderLink(Uri.parse('/orders/$id')),
        const BuyerOrderLink(id),
      );
      expect(
        parseOrderLink(Uri.parse('/seller/orders?o=$id')),
        const ShopOrderLink(id),
      );
    });

    test('old template link with {{1}} before the id', () {
      expect(
        parseOrderLink(
          Uri.parse('https://jewelry.gemworld.in/orders/%7B%7B1%7D%7D$id'),
        ),
        const BuyerOrderLink(id),
      );
    });

    test('upper-case id is lower-cased; trailing slash ok', () {
      expect(
        parseOrderLink(
          Uri.parse('https://jewelry.gemworld.in/orders/${id.toUpperCase()}/'),
        ),
        const BuyerOrderLink(id),
      );
    });

    test('other links are ignored', () {
      for (final link in [
        'https://jewelry.gemworld.in/products/ring',
        'https://jewelry.gemworld.in/orders',
        'https://jewelry.gemworld.in/orders/not-an-id',
        'https://jewelry.gemworld.in/seller/orders',
        'https://jewelry.gemworld.in/seller/orders/$id',
        'https://evil.example.com/orders/$id',
        '/seller/orders',
        '/jewelry/orders/$id',
      ]) {
        expect(parseOrderLink(Uri.parse(link)), isNull, reason: link);
      }
    });
  });

  test('shop orders map from a list or a page', () {
    final row = {
      'id': id,
      'orderNumber': 'GW-1001',
      'buyerName': 'Asha',
      'shopTotal': 52000,
      'paidAt': '2026-10-30T10:00:00Z',
      'shippingAddress': {
        'fullName': 'Asha',
        'phone': '9999999999',
        'line1': '12 MG Road',
        'city': 'Surat',
        'state': 'Gujarat',
        'postalCode': '395007',
      },
      'items': [
        {'id': 'i1', 'title': 'Ring', 'quantity': 1, 'lineTotal': 52000},
      ],
      'shipment': {'status': 'ACCEPTED', 'courierName': 'BlueDart'},
    };
    for (final data in [
      [row],
      {
        'items': [row],
      },
    ]) {
      final orders = JewelryCheckoutMapper.shopOrders(data);
      expect(orders, hasLength(1));
      final o = orders.single;
      expect(o.id, id);
      expect(o.buyerName, 'Asha');
      expect(o.shopTotal, 52000);
      expect(o.items.single.title, 'Ring');
      expect(o.shipment?.status, 'ACCEPTED');
      expect(o.address?.city, 'Surat');
    }
  });
}
