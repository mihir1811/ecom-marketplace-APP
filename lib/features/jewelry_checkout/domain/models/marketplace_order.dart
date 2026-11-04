import '../../../jewelry_reviews/domain/models/jewelry_review.dart';
import 'marketplace_charge.dart';

/// Delivery address for a marketplace order. [country] is a 2-letter ISO
/// code (India when left out). Outside India [state] and [postalCode] are
/// optional and come back as `''` when they were left out.
class MarketplaceAddress {
  const MarketplaceAddress({
    required this.fullName,
    required this.phone,
    required this.line1,
    required this.city,
    required this.state,
    required this.postalCode,
    this.line2,
    this.country = 'IN',
  });

  final String fullName;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  bool get isIndia => country.toUpperCase() == 'IN';

  String get summaryLine => [
    line1,
    if (line2 != null && line2!.trim().isNotEmpty) line2!,
    [
      city,
      [state, postalCode].where((s) => s.trim().isNotEmpty).join(' '),
    ].where((s) => s.trim().isNotEmpty).join(', '),
    if (!isIndia) country.toUpperCase(),
  ].join(', ');

  Map<String, dynamic> toJson() => {
    'fullName': fullName.trim(),
    'phone': phone.trim(),
    'line1': line1.trim(),
    if (line2 != null && line2!.trim().isNotEmpty) 'line2': line2!.trim(),
    'city': city.trim(),
    if (state.trim().isNotEmpty) 'state': state.trim(),
    if (postalCode.trim().isNotEmpty) 'postalCode': postalCode.trim(),
    'country': country.trim().toUpperCase(),
  };
}

/// GemWorld's tax invoice number for a paid order.
class MarketplaceInvoiceRef {
  const MarketplaceInvoiceRef({required this.number, this.issuedAt});

  /// `JW/26-27/00042` (a new series each April).
  final String number;
  final DateTime? issuedAt;
}

/// Razorpay session for a marketplace order. [amountPaise] is in paise.
class MarketplaceCheckoutSession {
  const MarketplaceCheckoutSession({
    required this.orderId,
    required this.orderNumber,
    required this.razorpayOrderId,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
    required this.name,
    required this.description,
    this.prefill = const {},
  });

  final String orderId;
  final String orderNumber;
  final String razorpayOrderId;
  final int amountPaise;
  final String currency;
  final String keyId;
  final String name;
  final String description;

  /// `name`, `email`, `contact`.
  final Map<String, String> prefill;
}

/// Order `status`.
abstract final class MarketplaceOrderStatus {
  static const pendingPayment = 'PENDING_PAYMENT';
  static const paid = 'PAID';
  static const failed = 'FAILED';
  static const cancelled = 'CANCELLED';
}

/// Piece / shipment / update `status`, in the order sellers move through
/// them (forward only, skipping allowed).
abstract final class MarketplaceStepStatus {
  static const placed = 'PLACED';
  static const accepted = 'ACCEPTED';
  static const inProduction = 'IN_PRODUCTION';
  static const qualityCheck = 'QUALITY_CHECK';
  static const readyToShip = 'READY_TO_SHIP';
  static const shipped = 'SHIPPED';
  static const outForDelivery = 'OUT_FOR_DELIVERY';
  static const delivered = 'DELIVERED';
  static const cancelled = 'CANCELLED';

  static const steps = [
    placed,
    accepted,
    inProduction,
    qualityCheck,
    readyToShip,
    shipped,
    outForDelivery,
    delivered,
  ];
}

/// `reason` values for cancelling a piece.
abstract final class MarketplaceCancelReason {
  static const values = [
    'CHANGED_MIND',
    'ORDERED_BY_MISTAKE',
    'WRONG_OPTION',
    'BETTER_PRICE',
    'TOO_SLOW',
    'OTHER',
  ];
}

class MarketplaceOrder {
  const MarketplaceOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.shippingTotal,
    required this.total,
    required this.refundedTotal,
    required this.items,
    required this.shipments,
    this.address,
    this.buyerNote,
    this.paymentMethod,
    this.paidAt,
    this.createdAt,
    this.taxes = const [],
    this.taxTotal = 0,
    this.invoice,
    this.hasInvoiceField = false,
  });

  final String id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double shippingTotal;

  /// One row per tax and rate; [total] includes [taxTotal].
  final List<MarketplaceCharge> taxes;
  final double taxTotal;

  /// Set once the order is paid. An order paid before invoices existed is
  /// numbered the first time its invoice is opened, so it can still be null.
  final MarketplaceInvoiceRef? invoice;

  /// The API sent an `invoice` field, so this backend issues invoices.
  final bool hasInvoiceField;
  final double total;
  final double refundedTotal;
  final MarketplaceAddress? address;
  final String? buyerNote;
  final String? paymentMethod;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final List<MarketplaceOrderItem> items;

  /// Empty until the order is paid; one per shop.
  final List<MarketplaceShipment> shipments;

  bool get isPaid => status == MarketplaceOrderStatus.paid;
  bool get isPendingPayment => status == MarketplaceOrderStatus.pendingPayment;

  /// Paid orders have a tax invoice (cancelled pieces stay on it).
  bool get canShowInvoice =>
      invoice != null || (hasInvoiceField && paidAt != null);

  String? get coverImageUrl {
    for (final item in items) {
      final url = item.imageUrl;
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  int get pieceCount => items.fold(0, (sum, i) => sum + i.quantity);
}

class MarketplaceOrderItem {
  const MarketplaceOrderItem({
    required this.id,
    required this.title,
    required this.shopName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.status,
    this.listingSlug,
    this.imageUrl,
    this.options = const {},
    this.customValues = const {},
    this.canCancel = false,
    this.cancellableUntil,
    this.cancellationWindowHours = 0,
    this.cancelledAt,
    this.cancelReason,
    this.refundAmount,
    this.refundStatus,
    this.refundedAt,
    this.taxes = const [],
    this.taxAmount = 0,
    this.review,
    this.canReview = false,
  });

  final String id;
  final String title;
  final String shopName;
  final String? listingSlug;
  final String? imageUrl;
  final Map<String, String> options;
  final Map<String, String> customValues;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final String status;
  final bool canCancel;
  final DateTime? cancellableUntil;
  final int cancellationWindowHours;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final double? refundAmount;

  /// `PENDING`, `PROCESSED` or `FAILED`.
  final String? refundStatus;
  final DateTime? refundedAt;

  /// Taxes on this piece; cancelling refunds [lineTotal] + [taxAmount].
  final List<MarketplaceCharge> taxes;
  final double taxAmount;

  /// What the buyer paid for this piece, tax included.
  double get paidTotal => lineTotal + taxAmount;

  /// The buyer's review of this line (on the seller's list: the buyer's).
  final JewelryOwnReview? review;

  /// Delivered on a paid order and not reviewed yet.
  final bool canReview;

  /// The piece has reached the buyer; reviews open only then.
  bool get isDelivered =>
      status.trim().toUpperCase() == MarketplaceStepStatus.delivered;
}

class MarketplaceShipment {
  const MarketplaceShipment({
    required this.shopName,
    required this.status,
    this.itemIds = const [],
    this.shippingMethod,
    this.courierName,
    this.trackingNumber,
    this.trackingUrl,
    this.expectedDeliveryAt,
    this.sellerPhone,
    this.updates = const [],
  });

  final String shopName;

  /// The furthest-behind piece that isn't cancelled.
  final String status;
  final List<String> itemIds;

  /// `COURIER` or `SELLER_DELIVERY`.
  final String? shippingMethod;
  final String? courierName;
  final String? trackingNumber;
  final String? trackingUrl;

  /// Seller's estimate, `YYYY-MM-DD` (a calendar date, no time zone).
  final String? expectedDeliveryAt;

  /// Only on the single-order read, only while the order is paid.
  final String? sellerPhone;

  /// Newest first; the last is always the order being placed.
  final List<MarketplaceOrderUpdate> updates;
}

class MarketplaceOrderUpdate {
  const MarketplaceOrderUpdate({
    required this.id,
    required this.status,
    this.message,
    this.location,
    this.imageUrls = const [],
    this.createdAt,
  });

  final String id;
  final String status;
  final String? message;
  final String? location;
  final List<String> imageUrls;
  final DateTime? createdAt;
}
