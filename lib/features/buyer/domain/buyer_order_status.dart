import 'models/buyer_order.dart';

/// Where a buyer order summary stands, from the payment status and the
/// combined seller decision the list API returns.
enum BuyerOrderStage {
  paymentPending,
  awaitingSeller,
  confirmed,
  refunded,
  issue,
  other,
}

/// Status buckets of the buyer Orders screen.
enum BuyerOrderFilter {
  all('All'),
  active('In progress'),
  refunded('Refunded'),
  issues('Needs attention');

  const BuyerOrderFilter(this.label);
  final String label;

  bool matches(BuyerOrderStage stage) => switch (this) {
    BuyerOrderFilter.all => true,
    BuyerOrderFilter.active =>
      stage == BuyerOrderStage.paymentPending ||
          stage == BuyerOrderStage.awaitingSeller ||
          stage == BuyerOrderStage.confirmed ||
          stage == BuyerOrderStage.other,
    BuyerOrderFilter.refunded => stage == BuyerOrderStage.refunded,
    BuyerOrderFilter.issues => stage == BuyerOrderStage.issue,
  };
}

/// Sort orders of the buyer Orders screen.
enum BuyerOrderSort {
  newest('Newest first'),
  oldest('Oldest first'),
  highest('Highest value'),
  lowest('Lowest value');

  const BuyerOrderSort(this.label);
  final String label;
}

/// Whether the order's payment went through (paid, or paid and later
/// refunded). Pending, failed and cancelled payments are not orders the
/// buyer placed.
bool isSuccessfulBuyerPayment(BuyerOrder order) {
  final status = order.status.trim().toUpperCase();
  return status == 'PAID' || status.contains('REFUND');
}

/// [orders] whose payment succeeded, in their original order.
List<BuyerOrder> successfulBuyerOrders(List<BuyerOrder> orders) =>
    orders.where(isSuccessfulBuyerPayment).toList();

BuyerOrderStage buyerOrderStage(BuyerOrder order) {
  final status = order.status.trim().toUpperCase();
  if (status == 'FAILED' || status.startsWith('CANCEL')) {
    return BuyerOrderStage.issue;
  }
  if (status.contains('REFUND')) return BuyerOrderStage.refunded;
  if (status == 'PENDING' || status == 'CREATED') {
    return BuyerOrderStage.paymentPending;
  }
  if (status == 'PAID') {
    return switch (order.sellerDecision) {
      'REJECTED' => BuyerOrderStage.issue,
      'PENDING' => BuyerOrderStage.awaitingSeller,
      _ => BuyerOrderStage.confirmed,
    };
  }
  return BuyerOrderStage.other;
}

/// Short customer-facing status for a list row.
String buyerOrderStageLabel(BuyerOrder order) {
  final status = order.status.trim().toUpperCase();
  return switch (buyerOrderStage(order)) {
    BuyerOrderStage.paymentPending => 'Payment pending',
    BuyerOrderStage.awaitingSeller => 'Awaiting seller',
    BuyerOrderStage.confirmed => 'Confirmed',
    BuyerOrderStage.refunded =>
      status == 'PARTIALLY_REFUNDED' ? 'Partly refunded' : 'Refunded',
    BuyerOrderStage.issue =>
      status == 'FAILED'
          ? 'Payment failed'
          : status.startsWith('CANCEL')
          ? 'Cancelled'
          : 'Rejected by seller',
    BuyerOrderStage.other => _humanize(order.status),
  };
}

/// One sentence telling the buyer what happens next.
String buyerOrderNextStep(BuyerOrder order) {
  return switch (buyerOrderStage(order)) {
    BuyerOrderStage.paymentPending => 'Waiting for your payment to clear',
    BuyerOrderStage.awaitingSeller => 'The seller is reviewing your order',
    BuyerOrderStage.confirmed => 'Confirmed — track it in the order',
    BuyerOrderStage.refunded => 'Refund credited to your wallet',
    BuyerOrderStage.issue =>
      order.status.trim().toUpperCase() == 'FAILED'
          ? 'The payment did not go through'
          : 'Open the order to request your refund',
    BuyerOrderStage.other => 'Open the order for details',
  };
}

/// Filters, searches and sorts [orders] for display.
List<BuyerOrder> buyerOrderView(
  List<BuyerOrder> orders, {
  required BuyerOrderFilter filter,
  required String query,
  required BuyerOrderSort sort,
}) {
  final q = query.trim().toLowerCase();
  final out = [
    for (final o in orders)
      if (filter.matches(buyerOrderStage(o)) &&
          (q.isEmpty ||
              o.productLabel.toLowerCase().contains(q) ||
              o.sellerName.toLowerCase().contains(q) ||
              o.id.toLowerCase().contains(q)))
        o,
  ];
  int byDate(BuyerOrder a, BuyerOrder b) =>
      (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0));
  switch (sort) {
    case BuyerOrderSort.newest:
      out.sort((a, b) => byDate(b, a));
    case BuyerOrderSort.oldest:
      out.sort(byDate);
    case BuyerOrderSort.highest:
      out.sort((a, b) => b.amountUsd.compareTo(a.amountUsd));
    case BuyerOrderSort.lowest:
      out.sort((a, b) => a.amountUsd.compareTo(b.amountUsd));
  }
  return out;
}

/// Order count per filter bucket.
Map<BuyerOrderFilter, int> buyerOrderCounts(List<BuyerOrder> orders) {
  final counts = {for (final f in BuyerOrderFilter.values) f: 0};
  for (final o in orders) {
    final stage = buyerOrderStage(o);
    for (final f in BuyerOrderFilter.values) {
      if (f.matches(stage)) counts[f] = counts[f]! + 1;
    }
  }
  return counts;
}

String _humanize(String raw) {
  final words = raw.trim().toLowerCase().replaceAll('_', ' ');
  return words.isEmpty ? 'Order' : words[0].toUpperCase() + words.substring(1);
}
