import '../../payment/domain/models/payment_models.dart';
import '../../refunds/domain/models/refund_request.dart';
import '../../tracking/domain/models/shipment_models.dart';

enum OrderStepState { done, current, upcoming, failed }

enum OrderStatusTone { neutral, pending, progress, success, danger }

class OrderLifecycleStep {
  const OrderLifecycleStep(this.label, this.state, {this.detail});

  final String label;
  final OrderStepState state;
  final String? detail;
}

/// Customer-facing order status, derived only from backend values:
/// payment status (`/payment/orders`), seller decisions
/// (`PENDING`/`ACCEPTED`/`REJECTED`), shipment statuses (`/tracking`) and
/// refund requests (`/refunds/mine`).
class OrderLifecycle {
  const OrderLifecycle({
    required this.headline,
    required this.tone,
    required this.steps,
    this.message,
  });

  final String headline;
  final OrderStatusTone tone;
  final List<OrderLifecycleStep> steps;
  final String? message;

  bool get isRejected => headline == OrderHeadlines.rejected;
}

abstract final class OrderHeadlines {
  static const paymentPending = 'Payment Pending';
  static const paymentFailed = 'Payment Failed';
  static const approvalPending = 'Seller Approval Pending';
  static const confirmed = 'Order Confirmed';
  static const processing = 'Processing';
  static const shipped = 'Shipped';
  static const outForDelivery = 'Out for Delivery';
  static const delivered = 'Delivered';
  static const cancelled = 'Cancelled';
  static const rejected = 'Rejected';
  static const refundRequested = 'Refund Requested';
  static const refundProcessing = 'Refund Processing';
  static const refunded = 'Refunded';
}

const _refundedPaymentStatuses = {'REFUNDED', 'PARTIALLY_REFUNDED'};

OrderLifecycle buildOrderLifecycle({
  required String paymentStatus,
  required List<PaymentOrderSellerDecision> decisions,
  required List<Shipment> shipments,
  required List<RefundRequest> refunds,
}) {
  final payment = paymentStatus.trim().toUpperCase();
  final paymentRefunded = _refundedPaymentStatuses.contains(payment);

  if (payment == 'FAILED') {
    return const OrderLifecycle(
      headline: OrderHeadlines.paymentFailed,
      tone: OrderStatusTone.danger,
      message: 'The payment did not go through, so the order was not placed.',
      steps: [OrderLifecycleStep('Payment', OrderStepState.failed)],
    );
  }
  if (payment == 'PENDING') {
    return const OrderLifecycle(
      headline: OrderHeadlines.paymentPending,
      tone: OrderStatusTone.pending,
      message: 'We are waiting for the payment to be confirmed.',
      steps: [
        OrderLifecycleStep('Payment', OrderStepState.current),
        OrderLifecycleStep('Seller approval', OrderStepState.upcoming),
        OrderLifecycleStep('Processing', OrderStepState.upcoming),
        OrderLifecycleStep('Shipped', OrderStepState.upcoming),
        OrderLifecycleStep('Delivered', OrderStepState.upcoming),
      ],
    );
  }

  final rejected = decisions.where((d) => d.isRejected).toList();
  final allRejected =
      decisions.isNotEmpty && rejected.length == decisions.length;
  final anyPending = decisions.any((d) => d.isPending);
  final activeRefunds = refunds
      .where((r) => r.status != RefundStatus.cancelled)
      .toList();
  final pendingRefund = activeRefunds.any((r) => r.status.isPending);
  final acceptedRefund = activeRefunds.any(
    (r) => r.status == RefundStatus.accepted,
  );

  // Rejected by every seller: the order ends and the money goes back.
  if (allRejected) {
    final reason = rejected
        .map((d) => d.reason)
        .whereType<String>()
        .firstOrNull;
    final refundStep = paymentRefunded
        ? const OrderLifecycleStep(
            'Refunded',
            OrderStepState.done,
            detail: 'Credited to your GemWorld wallet',
          )
        : pendingRefund
        ? const OrderLifecycleStep('Refund requested', OrderStepState.current)
        : acceptedRefund
        ? const OrderLifecycleStep('Refund processing', OrderStepState.current)
        : const OrderLifecycleStep('Refund', OrderStepState.upcoming);
    return OrderLifecycle(
      headline: paymentRefunded
          ? OrderHeadlines.refunded
          : pendingRefund
          ? OrderHeadlines.refundRequested
          : acceptedRefund
          ? OrderHeadlines.refundProcessing
          : OrderHeadlines.rejected,
      tone: paymentRefunded ? OrderStatusTone.neutral : OrderStatusTone.danger,
      message: reason == null
          ? 'Seller has rejected this order.'
          : 'Seller has rejected this order: $reason',
      steps: [
        const OrderLifecycleStep('Order placed', OrderStepState.done),
        const OrderLifecycleStep('Rejected by seller', OrderStepState.failed),
        refundStep,
      ],
    );
  }

  final latest = _latestShipment(shipments);
  final shipmentStatus = latest?.status.trim().toUpperCase();
  final progress = shipmentStatus == null
      ? -1
      : ShipmentStatuses.progression.indexOf(shipmentStatus);
  final shipmentCancelled = shipmentStatus == ShipmentStatuses.cancelled;
  // A shipment only exists after the seller accepted the order.
  // Without any decision data, only a shipment proves the seller accepted.
  final confirmed = latest != null || (decisions.isNotEmpty && !anyPending);
  final partialRejection = rejected.isNotEmpty;

  final processingDone = progress >= 1; // PACKED or later.
  final shippedIndex = ShipmentStatuses.progression.indexOf(
    ShipmentStatuses.shipped,
  );
  final deliveredIndex = ShipmentStatuses.progression.indexOf(
    ShipmentStatuses.delivered,
  );

  final steps = <OrderLifecycleStep>[
    const OrderLifecycleStep('Order placed', OrderStepState.done),
    OrderLifecycleStep(
      confirmed ? 'Order confirmed' : 'Seller approval',
      confirmed ? OrderStepState.done : OrderStepState.current,
      detail: partialRejection
          ? '${rejected.length} seller${rejected.length == 1 ? '' : 's'} '
                'rejected their items'
          : null,
    ),
    OrderLifecycleStep(
      'Processing',
      !confirmed
          ? OrderStepState.upcoming
          : processingDone || progress >= shippedIndex
          ? OrderStepState.done
          : OrderStepState.current,
    ),
    OrderLifecycleStep(
      shipmentStatus == ShipmentStatuses.outForDelivery
          ? 'Out for delivery'
          : shipmentStatus == ShipmentStatuses.inTransit
          ? 'In transit'
          : 'Shipped',
      progress >= deliveredIndex
          ? OrderStepState.done
          : progress >= shippedIndex
          ? OrderStepState.current
          : OrderStepState.upcoming,
    ),
    OrderLifecycleStep(
      'Delivered',
      progress >= deliveredIndex
          ? OrderStepState.done
          : OrderStepState.upcoming,
    ),
  ];

  if (shipmentCancelled) {
    return OrderLifecycle(
      headline: OrderHeadlines.cancelled,
      tone: OrderStatusTone.danger,
      message: 'The seller cancelled the shipment for this order.',
      steps: [
        steps[0],
        steps[1],
        const OrderLifecycleStep('Cancelled', OrderStepState.failed),
        if (paymentRefunded)
          const OrderLifecycleStep('Refunded', OrderStepState.done),
      ],
    );
  }

  if (pendingRefund || acceptedRefund || paymentRefunded) {
    final headline = pendingRefund
        ? OrderHeadlines.refundRequested
        : acceptedRefund && !paymentRefunded
        ? OrderHeadlines.refundProcessing
        : OrderHeadlines.refunded;
    return OrderLifecycle(
      headline: headline,
      tone: OrderStatusTone.pending,
      message: payment == 'PARTIALLY_REFUNDED'
          ? 'Part of this order has been refunded.'
          : null,
      steps: steps,
    );
  }

  final String headline;
  final OrderStatusTone tone;
  if (!confirmed) {
    headline = OrderHeadlines.approvalPending;
    tone = OrderStatusTone.pending;
  } else if (progress >= deliveredIndex) {
    headline = OrderHeadlines.delivered;
    tone = OrderStatusTone.success;
  } else if (shipmentStatus == ShipmentStatuses.outForDelivery) {
    headline = OrderHeadlines.outForDelivery;
    tone = OrderStatusTone.progress;
  } else if (progress >= shippedIndex) {
    headline = OrderHeadlines.shipped;
    tone = OrderStatusTone.progress;
  } else if (latest != null) {
    headline = OrderHeadlines.processing;
    tone = OrderStatusTone.progress;
  } else {
    headline = OrderHeadlines.confirmed;
    tone = OrderStatusTone.success;
  }

  return OrderLifecycle(
    headline: headline,
    tone: tone,
    message: switch (headline) {
      OrderHeadlines.approvalPending =>
        'The seller has been notified and will confirm your order shortly.',
      OrderHeadlines.confirmed => 'The seller confirmed your order.',
      _ => null,
    },
    steps: steps,
  );
}

Shipment? _latestShipment(List<Shipment> shipments) {
  if (shipments.isEmpty) return null;
  final sorted = [...shipments]
    ..sort(
      (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(0)).compareTo(
        a.updatedAt ?? a.createdAt ?? DateTime(0),
      ),
    );
  return sorted.first;
}
