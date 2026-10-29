/// Seller decision on an incoming order (`GET /seller/orders?status=`).
///
/// Swagger defines exactly `PENDING`, `ACCEPTED` and `REJECTED`; anything
/// else is kept as [unknown] so the UI never offers actions for it.
enum SellerOrderStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  rejected('REJECTED'),
  unknown('');

  const SellerOrderStatus(this.apiValue);

  final String apiValue;

  static SellerOrderStatus fromApi(String? raw) {
    final value = raw?.trim().toUpperCase() ?? '';
    for (final status in values) {
      if (status != unknown && status.apiValue == value) return status;
    }
    return unknown;
  }

  /// Seller-facing label.
  String get label => switch (this) {
    pending => 'Awaiting your approval',
    accepted => 'Confirmed',
    rejected => 'Rejected',
    unknown => 'Unknown',
  };

  /// Only a pending order can be accepted or rejected.
  bool get canDecide => this == pending;
}

class SellerOrderCustomer {
  const SellerOrderCustomer({
    required this.name,
    this.id,
    this.email,
    this.phone,
  });

  final String? id;
  final String name;
  final String? email;
  final String? phone;
}

class SellerOrderItem {
  const SellerOrderItem({
    required this.name,
    required this.quantity,
    this.productId,
    this.productType,
    this.stockNumber,
    this.unitPrice,
    this.lineTotal,
    this.image,
  });

  final String? productId;
  final String? productType;
  final String name;
  final String? stockNumber;
  final int quantity;
  final double? unitPrice;
  final double? lineTotal;
  final String? image;
}

/// One incoming order for the signed-in seller.
class SellerOrder {
  const SellerOrder({
    required this.id,
    required this.orderId,
    required this.status,
    required this.rawStatus,
    required this.items,
    this.displayId,
    this.customer,
    this.amount,
    this.amountUsd,
    this.amountInr,
    this.currency,
    this.paymentStatus,
    this.itemCount,
    this.createdAt,
    this.updatedAt,
    this.decidedAt,
    this.rejectionReason,
    this.sellerNote,
    this.shippingAddress,
    this.isAuctionSale = false,
  });

  /// Id used by `/seller/orders/{id}` (accept / reject / detail).
  final String id;

  /// Marketplace (payment) order id; shipments and refunds reference it.
  final String orderId;
  final String? displayId;
  final SellerOrderStatus status;

  /// Status string exactly as the API sent it.
  final String rawStatus;
  final SellerOrderCustomer? customer;
  final List<SellerOrderItem> items;
  final double? amount;
  final double? amountUsd;
  final double? amountInr;
  final String? currency;
  final String? paymentStatus;
  final int? itemCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? decidedAt;
  final String? rejectionReason;
  final String? sellerNote;
  final String? shippingAddress;

  /// This seller's part of the order is only auction wins. It starts
  /// `ACCEPTED`, with no memo and nothing to accept: it is a sale to ship.
  final bool isAuctionSale;

  String get shortId {
    final display = displayId?.trim();
    if (display != null && display.isNotEmpty) return display;
    final source = orderId.isNotEmpty ? orderId : id;
    final compact = source.replaceAll('-', '');
    return (compact.length > 8 ? compact.substring(0, 8) : compact)
        .toUpperCase();
  }

  String get customerLabel {
    final name = customer?.name.trim();
    return name == null || name.isEmpty ? 'Customer' : name;
  }

  int get totalQuantity {
    if (items.isEmpty) return itemCount ?? 0;
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  String get productSummary {
    if (items.isEmpty) {
      final count = itemCount ?? 0;
      return count == 1 ? '1 item' : '$count items';
    }
    final first = items.first.name;
    return items.length == 1 ? first : '$first +${items.length - 1} more';
  }

  SellerOrder copyWith({
    SellerOrderStatus? status,
    String? rawStatus,
    String? rejectionReason,
    String? sellerNote,
    DateTime? decidedAt,
  }) {
    return SellerOrder(
      id: id,
      orderId: orderId,
      displayId: displayId,
      status: status ?? this.status,
      rawStatus: rawStatus ?? this.rawStatus,
      customer: customer,
      items: items,
      amount: amount,
      amountUsd: amountUsd,
      amountInr: amountInr,
      currency: currency,
      paymentStatus: paymentStatus,
      itemCount: itemCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      decidedAt: decidedAt ?? this.decidedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      sellerNote: sellerNote ?? this.sellerNote,
      shippingAddress: shippingAddress,
      isAuctionSale: isAuctionSale,
    );
  }
}

class SellerOrdersPage {
  const SellerOrdersPage({
    required this.orders,
    required this.page,
    required this.total,
    required this.lastPage,
  });

  final List<SellerOrder> orders;
  final int page;
  final int total;
  final int lastPage;

  bool get hasMore => page < lastPage;
}
