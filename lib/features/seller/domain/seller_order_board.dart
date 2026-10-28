import '../../../core/utils/currency_rates.dart';
import '../../refunds/domain/models/refund_request.dart';
import 'models/seller_order.dart';

/// Tabs on the seller Orders screen.
///
/// Order tabs come from the seller decision on `/seller/orders`
/// (`PENDING` / `ACCEPTED` / `REJECTED`); refund tabs from `/refunds/seller`
/// (`PENDING` / `ACCEPTED` / `REJECTED` / `CANCELLED`).
enum SellerOrderCategory {
  pending('Pending', 'No orders are waiting for your approval.'),
  confirmed('Confirmed', 'No confirmed orders yet.'),
  cancelled('Canceled', 'No canceled orders.'),
  refundRequested('Refund Requests', 'No open refund requests.'),
  refundApproved('Refund Approved', 'No approved refunds.'),
  refundRejected('Refund Rejected', 'No rejected refunds.'),
  refundWithdrawn('Refund Withdrawn', 'No refund requests were withdrawn.');

  const SellerOrderCategory(this.label, this.emptyMessage);

  final String label;
  final String emptyMessage;

  bool get isRefund => index >= refundRequested.index;
}

/// Payment statuses that mean the order did not go through.
const _cancelledPayments = {'CANCELLED', 'CANCELED', 'FAILED'};

/// Tab for one order.
///
/// A seller rejection is shown as canceled (the backend refunds the buyer).
/// Statuses outside the documented three are treated as post-acceptance
/// fulfilment states (e.g. `SHIPPED`) unless they name a cancellation.
SellerOrderCategory sellerOrderCategoryOf(SellerOrder order) {
  final payment = order.paymentStatus?.trim().toUpperCase() ?? '';
  final raw = order.rawStatus.trim().toUpperCase();
  if (_cancelledPayments.contains(payment)) {
    return SellerOrderCategory.cancelled;
  }
  return switch (order.status) {
    SellerOrderStatus.pending => SellerOrderCategory.pending,
    SellerOrderStatus.accepted => SellerOrderCategory.confirmed,
    SellerOrderStatus.rejected => SellerOrderCategory.cancelled,
    SellerOrderStatus.unknown =>
      raw.contains('CANCEL') || raw.contains('REJECT')
          ? SellerOrderCategory.cancelled
          : raw.isEmpty
          ? SellerOrderCategory.pending
          : SellerOrderCategory.confirmed,
  };
}

SellerOrderCategory sellerRefundCategoryOf(RefundRequest refund) =>
    switch (refund.status) {
      RefundStatus.pending => SellerOrderCategory.refundRequested,
      RefundStatus.accepted => SellerOrderCategory.refundApproved,
      RefundStatus.rejected => SellerOrderCategory.refundRejected,
      RefundStatus.cancelled => SellerOrderCategory.refundWithdrawn,
    };

enum SellerOrderSort {
  newest('Newest first'),
  oldest('Oldest first'),
  highestValue('Highest value'),
  lowestValue('Lowest value'),
  customerName('Customer name');

  const SellerOrderSort(this.label);
  final String label;
}

/// Refund state of an order, for filtering order tabs.
enum SellerOrderRefundState {
  none('No refund'),
  requested('Refund requested'),
  approved('Refund approved'),
  rejected('Refund rejected');

  const SellerOrderRefundState(this.label);
  final String label;
}

/// Sort and filters applied locally to the loaded orders and refunds.
class SellerOrderFilters {
  const SellerOrderFilters({
    this.sort = SellerOrderSort.newest,
    this.from,
    this.to,
    this.paymentStatuses = const {},
    this.refundStates = const {},
    this.search = '',
  });

  final SellerOrderSort sort;

  /// Inclusive local calendar days; either may be open.
  final DateTime? from;
  final DateTime? to;

  /// Upper-case API payment statuses; empty means any.
  final Set<String> paymentStatuses;

  /// Order tabs only; empty means any.
  final Set<SellerOrderRefundState> refundStates;
  final String search;

  bool get hasDateRange => from != null || to != null;

  /// Number of filters (not sort / search) in effect, for the filter badge.
  int get activeCount =>
      (hasDateRange ? 1 : 0) +
      (paymentStatuses.isNotEmpty ? 1 : 0) +
      (refundStates.isNotEmpty ? 1 : 0);

  SellerOrderFilters copyWith({
    SellerOrderSort? sort,
    DateTime? from,
    DateTime? to,
    bool clearDates = false,
    Set<String>? paymentStatuses,
    Set<SellerOrderRefundState>? refundStates,
    String? search,
  }) {
    return SellerOrderFilters(
      sort: sort ?? this.sort,
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
      paymentStatuses: paymentStatuses ?? this.paymentStatuses,
      refundStates: refundStates ?? this.refundStates,
      search: search ?? this.search,
    );
  }
}

/// One row on the board: an order (order tabs) or a refund request with
/// its order when that order is loaded (refund tabs).
class SellerOrderBoardEntry {
  const SellerOrderBoardEntry._({this.order, this.refund, this.latestRefund});

  final SellerOrder? order;
  final RefundRequest? refund;

  /// Newest refund request on [order] (order tabs), if any.
  final RefundRequest? latestRefund;

  DateTime? get date => refund?.createdAt ?? order?.createdAt;

  /// Comparable value in USD.
  double get valueUsd {
    final r = refund;
    if (r != null) return r.amountUsd;
    return order == null ? 0 : sellerOrderValueUsd(order!);
  }

  String get customerName {
    final fromRefund = refund?.user?.name.trim();
    if (fromRefund != null && fromRefund.isNotEmpty) return fromRefund;
    final fromOrder = order?.customer?.name.trim();
    if (fromOrder != null && fromOrder.isNotEmpty) return fromOrder;
    return refund != null ? 'Buyer' : 'Customer';
  }

  String get paymentStatus => order?.paymentStatus?.trim().toUpperCase() ?? '';

  SellerOrderRefundState get refundState {
    return switch (latestRefund?.status) {
      null || RefundStatus.cancelled => SellerOrderRefundState.none,
      RefundStatus.pending => SellerOrderRefundState.requested,
      RefundStatus.accepted => SellerOrderRefundState.approved,
      RefundStatus.rejected => SellerOrderRefundState.rejected,
    };
  }

  String get key =>
      refund != null ? 'refund:${refund!.id}' : 'order:${order!.id}';
}

/// Order value in USD for sorting; INR-only orders are converted.
double sellerOrderValueUsd(SellerOrder order) {
  final usd = order.amountUsd;
  if (usd != null && usd > 0) return usd;
  final inr = order.amountInr;
  if (inr != null && inr > 0) return inrToUsd(inr);
  final amount = order.amount ?? 0;
  return order.currency?.toUpperCase() == 'INR' ? inrToUsd(amount) : amount;
}

/// Splits, joins, filters and sorts the loaded orders and refunds.
///
/// Pure and synchronous: switching tabs, sorting or filtering never calls
/// the API.
class SellerOrderBoard {
  SellerOrderBoard({
    required List<SellerOrder> orders,
    required List<RefundRequest> refunds,
  }) : _orders = orders,
       _refunds = refunds {
    for (final order in orders) {
      if (order.orderId.isNotEmpty) _ordersByOrderId[order.orderId] = order;
      _ordersByOrderId.putIfAbsent(order.id, () => order);
    }
    for (final refund in refunds) {
      final existing = _latestRefund[refund.orderId];
      if (existing == null || _outranks(refund, existing)) {
        _latestRefund[refund.orderId] = refund;
      }
    }
  }

  final List<SellerOrder> _orders;
  final List<RefundRequest> _refunds;
  final _ordersByOrderId = <String, SellerOrder>{};
  final _latestRefund = <String, RefundRequest>{};

  SellerOrder? orderFor(RefundRequest refund) =>
      _ordersByOrderId[refund.orderId];

  /// Unfiltered number of rows per tab.
  Map<SellerOrderCategory, int> counts() {
    final counts = {for (final c in SellerOrderCategory.values) c: 0};
    for (final order in _orders) {
      final c = sellerOrderCategoryOf(order);
      counts[c] = counts[c]! + 1;
    }
    for (final refund in _refunds) {
      final c = sellerRefundCategoryOf(refund);
      counts[c] = counts[c]! + 1;
    }
    return counts;
  }

  /// Distinct payment statuses among loaded orders, for the filter sheet.
  List<String> paymentStatuses() {
    final values = <String>{
      for (final order in _orders)
        if ((order.paymentStatus ?? '').trim().isNotEmpty)
          order.paymentStatus!.trim().toUpperCase(),
    };
    return values.toList()..sort();
  }

  List<SellerOrderBoardEntry> entries(
    SellerOrderCategory category,
    SellerOrderFilters filters,
  ) {
    final rows = category.isRefund
        ? [
            for (final refund in _refunds)
              if (sellerRefundCategoryOf(refund) == category)
                SellerOrderBoardEntry._(
                  order: orderFor(refund),
                  refund: refund,
                ),
          ]
        : [
            for (final order in _orders)
              if (sellerOrderCategoryOf(order) == category)
                SellerOrderBoardEntry._(
                  order: order,
                  latestRefund:
                      _latestRefund[order.orderId] ?? _latestRefund[order.id],
                ),
          ];
    final filtered = rows.where((e) => _matches(e, category, filters)).toList();
    filtered.sort((a, b) => _compare(a, b, filters.sort));
    return filtered;
  }

  static bool _matches(
    SellerOrderBoardEntry entry,
    SellerOrderCategory category,
    SellerOrderFilters filters,
  ) {
    final date = entry.date;
    if (filters.from != null) {
      if (date == null || date.isBefore(_day(filters.from!))) return false;
    }
    if (filters.to != null) {
      final end = _day(filters.to!);
      final dayAfter = DateTime(end.year, end.month, end.day + 1);
      if (date == null || !date.isBefore(dayAfter)) return false;
    }
    if (filters.paymentStatuses.isNotEmpty &&
        !filters.paymentStatuses.contains(entry.paymentStatus)) {
      return false;
    }
    if (!category.isRefund &&
        filters.refundStates.isNotEmpty &&
        !filters.refundStates.contains(entry.refundState)) {
      return false;
    }
    final query = filters.search.trim().toLowerCase();
    if (query.isNotEmpty && !_searchText(entry).contains(query)) return false;
    return true;
  }

  static String _searchText(SellerOrderBoardEntry entry) {
    final order = entry.order;
    final refund = entry.refund;
    return [
      entry.customerName,
      order?.shortId,
      order?.id,
      order?.orderId,
      order?.customer?.email,
      order?.customer?.phone,
      order?.productSummary,
      refund?.id,
      refund?.orderId,
      refund?.reason,
    ].whereType<String>().join(' ').toLowerCase();
  }

  static int _compare(
    SellerOrderBoardEntry a,
    SellerOrderBoardEntry b,
    SellerOrderSort sort,
  ) {
    int newestFirst() => _compareDates(a.date, b.date, descending: true);
    final primary = switch (sort) {
      SellerOrderSort.newest => newestFirst(),
      SellerOrderSort.oldest => _compareDates(a.date, b.date),
      SellerOrderSort.highestValue => b.valueUsd.compareTo(a.valueUsd),
      SellerOrderSort.lowestValue => a.valueUsd.compareTo(b.valueUsd),
      SellerOrderSort.customerName => a.customerName.toLowerCase().compareTo(
        b.customerName.toLowerCase(),
      ),
    };
    if (primary != 0) return primary;
    final byDate = newestFirst();
    return byDate != 0 ? byDate : a.key.compareTo(b.key);
  }

  /// Undated rows always sort last.
  static int _compareDates(
    DateTime? a,
    DateTime? b, {
    bool descending = false,
  }) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return descending ? b.compareTo(a) : a.compareTo(b);
  }

  /// An active request beats a withdrawn one; otherwise the newer wins.
  static bool _outranks(RefundRequest a, RefundRequest b) {
    final aActive = a.status != RefundStatus.cancelled;
    final bActive = b.status != RefundStatus.cancelled;
    if (aActive != bActive) return aActive;
    return _compareDates(a.createdAt, b.createdAt, descending: true) < 0;
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
