import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/buyer/domain/buyer_order_status.dart';
import 'package:gemstone/features/buyer/domain/models/buyer_order.dart';

BuyerOrder _order(
  String id, {
  String status = 'PAID',
  String? decision,
  double usd = 100,
  DateTime? at,
  String product = 'Ring',
  String seller = 'Maison',
}) => BuyerOrder(
  id: id,
  productLabel: product,
  sellerName: seller,
  status: status,
  amountInr: usd * 83,
  amountUsd: usd,
  currency: 'INR',
  createdAt: at,
  sellerDecision: decision,
);

void main() {
  group('buyerOrderStage', () {
    test('maps payment status and seller decision', () {
      expect(
        buyerOrderStage(_order('a', status: 'PENDING')),
        BuyerOrderStage.paymentPending,
      );
      expect(
        buyerOrderStage(_order('b', decision: 'PENDING')),
        BuyerOrderStage.awaitingSeller,
      );
      expect(
        buyerOrderStage(_order('c', decision: 'ACCEPTED')),
        BuyerOrderStage.confirmed,
      );
      expect(buyerOrderStage(_order('d')), BuyerOrderStage.confirmed);
      expect(
        buyerOrderStage(_order('e', decision: 'REJECTED')),
        BuyerOrderStage.issue,
      );
      expect(
        buyerOrderStage(_order('f', status: 'FAILED')),
        BuyerOrderStage.issue,
      );
      expect(
        buyerOrderStage(_order('g', status: 'PARTIALLY_REFUNDED')),
        BuyerOrderStage.refunded,
      );
      expect(
        buyerOrderStage(_order('h', status: 'SOMETHING_NEW')),
        BuyerOrderStage.other,
      );
    });

    test('labels read naturally', () {
      expect(
        buyerOrderStageLabel(_order('a', decision: 'PENDING')),
        'Awaiting seller',
      );
      expect(
        buyerOrderStageLabel(_order('b', status: 'PARTIALLY_REFUNDED')),
        'Partly refunded',
      );
      expect(
        buyerOrderStageLabel(_order('c', decision: 'REJECTED')),
        'Rejected by seller',
      );
      expect(
        buyerOrderStageLabel(_order('d', status: 'SOMETHING_NEW')),
        'Something new',
      );
    });
  });

  test('only successful payments count as orders', () {
    final all = [
      _order('paid'),
      _order('pending', status: 'PENDING'),
      _order('created', status: 'CREATED'),
      _order('failed', status: 'FAILED'),
      _order('cancelled', status: 'CANCELLED'),
      _order('refunded', status: 'REFUNDED'),
      _order('partly', status: 'PARTIALLY_REFUNDED'),
    ];
    expect(successfulBuyerOrders(all).map((o) => o.id), [
      'paid',
      'refunded',
      'partly',
    ]);
  });

  group('buyerOrderView', () {
    final orders = [
      _order('1', usd: 50, at: DateTime(2026, 1, 1), product: 'Pearl'),
      _order(
        '2',
        status: 'FAILED',
        usd: 300,
        at: DateTime(2026, 3, 1),
        seller: 'Atelier Rose',
      ),
      _order('3', status: 'REFUNDED', usd: 120, at: DateTime(2026, 2, 1)),
    ];

    test('filters by bucket and counts every bucket', () {
      expect(
        buyerOrderView(
          orders,
          filter: BuyerOrderFilter.issues,
          query: '',
          sort: BuyerOrderSort.newest,
        ).map((o) => o.id),
        ['2'],
      );
      final counts = buyerOrderCounts(orders);
      expect(counts[BuyerOrderFilter.all], 3);
      expect(counts[BuyerOrderFilter.active], 1);
      expect(counts[BuyerOrderFilter.refunded], 1);
      expect(counts[BuyerOrderFilter.issues], 1);
    });

    test('searches product, seller and id', () {
      List<String> find(String q) => buyerOrderView(
        orders,
        filter: BuyerOrderFilter.all,
        query: q,
        sort: BuyerOrderSort.newest,
      ).map((o) => o.id).toList();
      expect(find('pearl'), ['1']);
      expect(find('rose'), ['2']);
      expect(find('3'), ['3']);
    });

    test('sorts by date and value', () {
      List<String> sorted(BuyerOrderSort s) => buyerOrderView(
        orders,
        filter: BuyerOrderFilter.all,
        query: '',
        sort: s,
      ).map((o) => o.id).toList();
      expect(sorted(BuyerOrderSort.newest), ['2', '3', '1']);
      expect(sorted(BuyerOrderSort.oldest), ['1', '3', '2']);
      expect(sorted(BuyerOrderSort.highest), ['2', '3', '1']);
      expect(sorted(BuyerOrderSort.lowest), ['1', '3', '2']);
    });
  });
}
