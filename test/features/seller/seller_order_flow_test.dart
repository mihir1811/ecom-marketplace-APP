import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/buyer/domain/order_lifecycle.dart';
import 'package:gemstone/features/notifications/domain/models/app_notification.dart';
import 'package:gemstone/features/notifications/domain/notification_open_target.dart';
import 'package:gemstone/features/payment/data/mappers/payment_mapper.dart';
import 'package:gemstone/features/payment/domain/models/payment_models.dart';
import 'package:gemstone/features/refunds/domain/models/refund_request.dart';
import 'package:gemstone/features/seller/data/mappers/seller_order_mapper.dart';
import 'package:gemstone/features/seller/domain/models/seller_order.dart';
import 'package:gemstone/features/tracking/domain/models/shipment_models.dart';

PaymentOrderSellerDecision _decision(String status, {String? reason}) =>
    PaymentOrderSellerDecision(sellerId: 's1', status: status, reason: reason);

Shipment _shipment(String status) =>
    Shipment(id: 'sh1', orderId: 'o1', sellerId: 's1', status: status);

RefundRequest _refund(RefundStatus status) => RefundRequest(
  id: 'r1',
  orderId: 'o1',
  userId: 'u1',
  sellerId: 's1',
  status: status,
  reason: 'rejected',
  amountInr: 100,
  amountUsd: 1,
  createdAtLabel: '',
  updatedAtLabel: '',
);

void main() {
  group('SellerOrderMapper', () {
    test('parses a paginated seller-order row with embedded order', () {
      final page = SellerOrderMapper.pageFromResponse(
        {
          'success': true,
          'data': {
            'data': [
              {
                'id': 'so-1',
                'orderId': 'po-1',
                'status': 'PENDING',
                'createdAt': '2026-09-30T10:00:00.000Z',
                'order': {
                  'user': {'name': 'Asha', 'email': 'asha@example.com'},
                  'items': [
                    {
                      'name': '1.02ct Round',
                      'quantity': 2,
                      'lineTotal': 4800,
                      'productType': 'diamond',
                    },
                  ],
                  'currency': 'INR',
                },
                'amount': 410000,
              },
            ],
            'meta': {
              'total': 12,
              'currentPage': 1,
              'perPage': 10,
              'lastPage': 2,
            },
          },
        },
        page: 1,
        limit: 10,
      );

      expect(page.total, 12);
      expect(page.hasMore, isTrue);
      final order = page.orders.single;
      expect(order.id, 'so-1');
      expect(order.orderId, 'po-1');
      expect(order.status, SellerOrderStatus.pending);
      expect(order.status.canDecide, isTrue);
      expect(order.customerLabel, 'Asha');
      expect(order.customer?.email, 'asha@example.com');
      expect(order.totalQuantity, 2);
      expect(order.currency, 'INR');
    });

    test('parses the flat RecentOrderDto shape', () {
      final page = SellerOrderMapper.pageFromResponse(
        {
          'data': [
            {
              'id': 'so-2',
              'displayId': 'A1B2C3D4',
              'customerName': 'Ravi',
              'amount': 120,
              'status': 'REJECTED',
              'createdAt': '2026-09-29T08:00:00Z',
              'itemCount': 3,
              'rejectionReason': 'Sold elsewhere',
            },
          ],
        },
        page: 1,
        limit: 10,
      );
      final order = page.orders.single;
      expect(order.shortId, 'A1B2C3D4');
      expect(order.status, SellerOrderStatus.rejected);
      expect(order.status.canDecide, isFalse);
      expect(order.rejectionReason, 'Sold elsewhere');
      expect(order.productSummary, '3 items');
      expect(page.hasMore, isFalse);
    });

    test('unknown statuses never allow a decision', () {
      expect(SellerOrderStatus.fromApi('SHIPPED'), SellerOrderStatus.unknown);
      expect(SellerOrderStatus.fromApi('accepted'), SellerOrderStatus.accepted);
      expect(SellerOrderStatus.unknown.canDecide, isFalse);
    });

    test('fromResponse returns null when the API echoes no order', () {
      expect(
        SellerOrderMapper.fromResponse({'success': true, 'message': 'ok'}),
        isNull,
      );
    });
  });

  group('PaymentMapper.sellerDecisionsFromJson', () {
    test('reads a sellerOrders list', () {
      final decisions = PaymentMapper.sellerDecisionsFromJson({
        'sellerOrders': [
          {
            'sellerId': 's1',
            'status': 'REJECTED',
            'rejectionReason': 'Out of stock',
          },
          {'sellerId': 's2', 'status': 'ACCEPTED'},
        ],
      });
      expect(decisions, hasLength(2));
      expect(decisions.first.isRejected, isTrue);
      expect(decisions.first.reason, 'Out of stock');
      expect(decisions.last.isAccepted, isTrue);
    });

    test('ignores payment statuses such as PAID', () {
      final decisions = PaymentMapper.sellerDecisionsFromJson({
        'status': 'PAID',
        'sellers': [
          {'id': 's1', 'companyName': 'Shree', 'status': 'PAID'},
        ],
        'items': [
          {'sellerId': 's1', 'name': 'x'},
        ],
      });
      expect(decisions, isEmpty);
    });

    test('applies an order-level status to every seller', () {
      final decisions = PaymentMapper.sellerDecisionsFromJson({
        'sellerOrderStatus': 'PENDING',
        'items': [
          {'sellerId': 's1'},
          {'sellerId': 's2'},
        ],
      });
      expect(decisions.map((d) => d.sellerId), ['s1', 's2']);
      expect(decisions.every((d) => d.isPending), isTrue);
    });
  });

  group('buildOrderLifecycle', () {
    OrderLifecycle build({
      String payment = 'PAID',
      List<PaymentOrderSellerDecision> decisions = const [],
      List<Shipment> shipments = const [],
      List<RefundRequest> refunds = const [],
    }) => buildOrderLifecycle(
      paymentStatus: payment,
      decisions: decisions,
      shipments: shipments,
      refunds: refunds,
    );

    test('paid and waiting for the seller', () {
      final l = build(decisions: [_decision('PENDING')]);
      expect(l.headline, OrderHeadlines.approvalPending);
      expect(l.steps[1].state, OrderStepState.current);
    });

    test('accepted becomes confirmed', () {
      final l = build(decisions: [_decision('ACCEPTED')]);
      expect(l.headline, OrderHeadlines.confirmed);
      expect(l.steps[1].state, OrderStepState.done);
      expect(l.steps[2].state, OrderStepState.current);
    });

    test('shipment statuses drive processing / shipped / delivered', () {
      expect(
        build(shipments: [_shipment('PROCESSING')]).headline,
        OrderHeadlines.processing,
      );
      expect(
        build(shipments: [_shipment('IN_TRANSIT')]).headline,
        OrderHeadlines.shipped,
      );
      expect(
        build(shipments: [_shipment('OUT_FOR_DELIVERY')]).headline,
        OrderHeadlines.outForDelivery,
      );
      final delivered = build(shipments: [_shipment('DELIVERED')]);
      expect(delivered.headline, OrderHeadlines.delivered);
      expect(
        delivered.steps.every((s) => s.state == OrderStepState.done),
        isTrue,
      );
    });

    test('rejected, then refund requested, then refunded', () {
      final rejected = build(
        decisions: [_decision('REJECTED', reason: 'Sold elsewhere')],
      );
      expect(rejected.headline, OrderHeadlines.rejected);
      expect(rejected.isRejected, isTrue);
      expect(rejected.message, contains('Sold elsewhere'));

      expect(
        build(
          decisions: [_decision('REJECTED')],
          refunds: [_refund(RefundStatus.pending)],
        ).headline,
        OrderHeadlines.refundRequested,
      );
      expect(
        build(
          decisions: [_decision('REJECTED')],
          refunds: [_refund(RefundStatus.accepted)],
        ).headline,
        OrderHeadlines.refundProcessing,
      );
      expect(
        build(payment: 'REFUNDED', decisions: [_decision('REJECTED')]).headline,
        OrderHeadlines.refunded,
      );
    });

    test('cancelled refund requests are ignored', () {
      expect(
        build(
          decisions: [_decision('REJECTED')],
          refunds: [_refund(RefundStatus.cancelled)],
        ).headline,
        OrderHeadlines.rejected,
      );
    });

    test('cancelled shipment and failed payment', () {
      expect(
        build(shipments: [_shipment('CANCELLED')]).headline,
        OrderHeadlines.cancelled,
      );
      expect(build(payment: 'FAILED').headline, OrderHeadlines.paymentFailed);
      expect(build(payment: 'PENDING').headline, OrderHeadlines.paymentPending);
    });
  });

  group('ShipmentStatuses.nextOptions', () {
    test('never offers a backwards move', () {
      final next = ShipmentStatuses.nextOptions('SHIPPED');
      expect(next, isNot(contains('PROCESSING')));
      expect(next, isNot(contains('PACKED')));
      expect(next, contains('OUT_FOR_DELIVERY'));
      expect(next, contains('CANCELLED'));
    });

    test('terminal shipments take no updates', () {
      expect(ShipmentStatuses.nextOptions('DELIVERED'), isEmpty);
      expect(ShipmentStatuses.nextOptions('CANCELLED'), isEmpty);
    });

    test('a new shipment can start anywhere', () {
      expect(ShipmentStatuses.nextOptions(null).first, 'PROCESSING');
    });
  });

  group('notification routing', () {
    AppNotification n(String type, Map<String, String> data) => AppNotification(
      id: '1',
      type: type,
      title: 't',
      body: 'b',
      link: '',
      data: data,
      isRead: false,
      createdAt: DateTime(2026),
    );

    test('buyers open the order detail on accept / reject', () {
      final target = notificationOpenTarget(
        n('ORDER_REJECTED', {'orderId': 'po-1'}),
        isSeller: false,
      );
      expect((target as NotificationInApp).route, '/buyer/orders/po-1');
    });

    test('sellers open the incoming order for other order events', () {
      final target = notificationOpenTarget(
        n('ORDER_PLACED', {'sellerOrderId': 'so-1', 'orderId': 'po-1'}),
        isSeller: true,
      );
      expect((target as NotificationInApp).route, '/seller/orders/so-1');
    });
  });
}
