import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/refunds/domain/models/refund_request.dart';
import 'package:gemstone/features/seller/domain/models/seller_order.dart';
import 'package:gemstone/features/seller/domain/seller_order_board.dart';

SellerOrder _order(
  String id, {
  SellerOrderStatus status = SellerOrderStatus.pending,
  String? raw,
  String customer = 'Asha',
  String? email,
  String? phone,
  double? usd,
  DateTime? at,
  String? payment = 'PAID',
}) {
  return SellerOrder(
    id: id,
    orderId: 'po-$id',
    status: status,
    rawStatus: raw ?? status.apiValue,
    items: const [],
    customer: SellerOrderCustomer(name: customer, email: email, phone: phone),
    amountUsd: usd,
    createdAt: at,
    paymentStatus: payment,
  );
}

RefundRequest _refund(
  String id, {
  required String orderId,
  RefundStatus status = RefundStatus.pending,
  String buyer = '',
  double usd = 10,
  DateTime? at,
}) {
  return RefundRequest(
    id: id,
    orderId: orderId,
    userId: 'u1',
    sellerId: 's1',
    status: status,
    reason: 'Damaged',
    amountInr: 0,
    amountUsd: usd,
    createdAtLabel: '',
    updatedAtLabel: '',
    user: RefundPartyUser(id: 'u1', name: buyer),
    createdAt: at,
  );
}

List<String> _ids(List<SellerOrderBoardEntry> entries) => [
  for (final e in entries) e.refund?.id ?? e.order!.id,
];

void main() {
  group('categories', () {
    test('seller decision and payment status pick the order tab', () {
      expect(
        sellerOrderCategoryOf(_order('1')),
        SellerOrderCategory.pending,
      );
      expect(
        sellerOrderCategoryOf(
          _order('2', status: SellerOrderStatus.accepted),
        ),
        SellerOrderCategory.confirmed,
      );
      expect(
        sellerOrderCategoryOf(
          _order('3', status: SellerOrderStatus.rejected),
        ),
        SellerOrderCategory.cancelled,
      );
      // Post-acceptance fulfilment statuses stay under Confirmed.
      expect(
        sellerOrderCategoryOf(
          _order('4', status: SellerOrderStatus.unknown, raw: 'SHIPPED'),
        ),
        SellerOrderCategory.confirmed,
      );
      expect(
        sellerOrderCategoryOf(
          _order('5', status: SellerOrderStatus.unknown, raw: 'CANCELLED'),
        ),
        SellerOrderCategory.cancelled,
      );
      expect(
        sellerOrderCategoryOf(_order('6', payment: 'FAILED')),
        SellerOrderCategory.cancelled,
      );
    });

    test('refund status picks the refund tab', () {
      expect(
        sellerRefundCategoryOf(_refund('r', orderId: 'x')),
        SellerOrderCategory.refundRequested,
      );
      expect(
        sellerRefundCategoryOf(
          _refund('r', orderId: 'x', status: RefundStatus.accepted),
        ),
        SellerOrderCategory.refundApproved,
      );
      expect(
        sellerRefundCategoryOf(
          _refund('r', orderId: 'x', status: RefundStatus.rejected),
        ),
        SellerOrderCategory.refundRejected,
      );
      expect(
        sellerRefundCategoryOf(
          _refund('r', orderId: 'x', status: RefundStatus.cancelled),
        ),
        SellerOrderCategory.refundWithdrawn,
      );
    });

    test('an accepted order moves from Pending to Confirmed', () {
      final pending = _order('1');
      final before = SellerOrderBoard(orders: [pending], refunds: const []);
      expect(before.counts()[SellerOrderCategory.pending], 1);

      final accepted = pending.copyWith(status: SellerOrderStatus.accepted);
      final after = SellerOrderBoard(orders: [accepted], refunds: const []);
      expect(after.counts()[SellerOrderCategory.pending], 0);
      expect(after.counts()[SellerOrderCategory.confirmed], 1);
      expect(
        _ids(
          after.entries(
            SellerOrderCategory.confirmed,
            const SellerOrderFilters(),
          ),
        ),
        ['1'],
      );
    });
  });

  group('customer details', () {
    test('refund rows carry the linked order customer contact', () {
      final board = SellerOrderBoard(
        orders: [
          _order(
            '1',
            status: SellerOrderStatus.accepted,
            customer: 'Ravi',
            email: 'ravi@example.com',
            phone: '+91 90000 00000',
          ),
        ],
        refunds: [_refund('r1', orderId: 'po-1')],
      );
      final entry = board
          .entries(
            SellerOrderCategory.refundRequested,
            const SellerOrderFilters(),
          )
          .single;
      expect(entry.order?.id, '1');
      expect(entry.customerName, 'Ravi');
      expect(entry.order?.customer?.email, 'ravi@example.com');
      expect(entry.order?.customer?.phone, '+91 90000 00000');

      // And the order row knows about its refund.
      final orderRow = board
          .entries(SellerOrderCategory.confirmed, const SellerOrderFilters())
          .single;
      expect(orderRow.refundState, SellerOrderRefundState.requested);
    });

    test('an active refund outranks a newer withdrawn one', () {
      final board = SellerOrderBoard(
        orders: [_order('1', status: SellerOrderStatus.accepted)],
        refunds: [
          _refund('old', orderId: 'po-1', at: DateTime(2026, 9, 1)),
          _refund(
            'new',
            orderId: 'po-1',
            status: RefundStatus.cancelled,
            at: DateTime(2026, 9, 5),
          ),
        ],
      );
      final row = board
          .entries(SellerOrderCategory.confirmed, const SellerOrderFilters())
          .single;
      expect(row.latestRefund?.id, 'old');
    });
  });

  group('sort and filter', () {
    final orders = [
      _order('a', customer: 'zoe', usd: 50, at: DateTime(2026, 9, 10, 9)),
      _order(
        'b',
        customer: 'Amit',
        usd: 500,
        at: DateTime(2026, 9, 20, 23, 59),
        payment: 'PARTIALLY_REFUNDED',
      ),
      _order('c', customer: 'meera', usd: 5, at: DateTime(2026, 9, 21)),
      _order('d', customer: 'Dev', usd: 75),
    ];
    final board = SellerOrderBoard(orders: orders, refunds: const []);
    List<String> run(SellerOrderFilters f) =>
        _ids(board.entries(SellerOrderCategory.pending, f));

    test('sorts by date, value and customer name', () {
      expect(run(const SellerOrderFilters()), ['c', 'b', 'a', 'd']);
      expect(
        run(const SellerOrderFilters(sort: SellerOrderSort.oldest)),
        ['a', 'b', 'c', 'd'],
      );
      expect(
        run(const SellerOrderFilters(sort: SellerOrderSort.highestValue)),
        ['b', 'd', 'a', 'c'],
      );
      expect(
        run(const SellerOrderFilters(sort: SellerOrderSort.lowestValue)),
        ['c', 'a', 'd', 'b'],
      );
      expect(
        run(const SellerOrderFilters(sort: SellerOrderSort.customerName)),
        ['b', 'd', 'c', 'a'],
      );
    });

    test('date range is inclusive of whole local days', () {
      expect(
        run(
          SellerOrderFilters(
            from: DateTime(2026, 9, 20),
            to: DateTime(2026, 9, 20),
          ),
        ),
        ['b'],
      );
      expect(run(SellerOrderFilters(from: DateTime(2026, 9, 11))), ['c', 'b']);
    });

    test('payment status, refund state and search narrow the list', () {
      expect(
        run(const SellerOrderFilters(paymentStatuses: {'PARTIALLY_REFUNDED'})),
        ['b'],
      );
      expect(
        run(
          const SellerOrderFilters(
            refundStates: {SellerOrderRefundState.requested},
          ),
        ),
        isEmpty,
      );
      expect(run(const SellerOrderFilters(search: 'MEER')), ['c']);
      expect(board.paymentStatuses(), ['PAID', 'PARTIALLY_REFUNDED']);
    });

    test('filters never hide rows from other tabs or change counts', () {
      expect(board.counts()[SellerOrderCategory.pending], 4);
      expect(
        board
            .entries(
              SellerOrderCategory.confirmed,
              const SellerOrderFilters(search: 'zoe'),
            )
            .isEmpty,
        isTrue,
      );
    });
  });
}
