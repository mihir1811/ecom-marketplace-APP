/// USD→INR rate from GET /payment/exchange-rate.
class ExchangeRate {
  const ExchangeRate({
    required this.rate,
    required this.from,
    required this.to,
    this.source,
    this.updatedAt,
  });

  final double rate;
  final String from;
  final String to;
  final String? source;
  final DateTime? updatedAt;
}

/// Create-order payload used to open Razorpay Checkout (or wallet-only pay).
class PaymentCheckoutSession {
  const PaymentCheckoutSession({
    required this.orderId,
    required this.razorpayOrderId,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
    this.amountUsd,
    this.amountInr,
    this.exchangeRate,
    this.walletAppliedInr,
    this.rewardPointsUsed = 0,
    this.rewardPointsAmountInr = 0,
    this.razorpayAmountInr,
    this.paidWithWallet = false,
    this.status,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.description,
  });

  final String orderId;
  final String razorpayOrderId;
  final int amountPaise;
  final String currency;
  final String keyId;
  final double? amountUsd;
  final double? amountInr;
  final double? exchangeRate;
  final double? walletAppliedInr;

  /// Points the server actually spent on this order and their ₹ value.
  final int rewardPointsUsed;
  final double rewardPointsAmountInr;

  /// What Razorpay charges after points and wallet.
  final double? razorpayAmountInr;

  /// Server flag: nothing left for Razorpay (wallet and / or points paid it).
  final bool paidWithWallet;
  final String? status;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? description;

  /// True when wallet and / or reward points covered the payable amount and
  /// Razorpay is not needed.
  bool get isFullyPaidByWallet {
    if (paidWithWallet) return true;
    final paidStatus = status?.toUpperCase();
    if (paidStatus == 'PAID' || paidStatus == 'CAPTURED') return true;
    if (orderId.isEmpty) return false;
    final applied = walletAppliedInr ?? 0;
    final dueInr = amountInr ?? (amountPaise / 100);
    if (applied > 0 && amountPaise <= 0) return true;
    if (applied > 0 && dueInr <= 0) return true;
    if (rewardPointsUsed > 0 && amountPaise <= 0 && razorpayOrderId.isEmpty) {
      return true;
    }
    return amountPaise <= 0 &&
        razorpayOrderId.isEmpty &&
        keyId.isEmpty &&
        applied > 0;
  }
}

/// Razorpay success fields required by POST /payment/verify.
class RazorpayPaymentSuccess {
  const RazorpayPaymentSuccess({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;
}

/// Paid / pending marketplace order from payment APIs.
class PaymentOrder {
  const PaymentOrder({
    required this.id,
    required this.status,
    required this.amount,
    required this.amountUsd,
    required this.currency,
    required this.createdAt,
    this.receipt,
    this.invoiceNumber,
    this.invoiceUrl,
    this.orderType,
    this.items = const [],
    this.pricing,
    this.sellers = const [],
    this.sellerDecisions = const [],
    this.rewardPoints = PaymentOrderRewardPoints.none,
  });

  final String id;
  final String status;
  final double amount;
  final double amountUsd;
  final String currency;
  final DateTime? createdAt;
  final String? receipt;
  final String? invoiceNumber;
  final String? invoiceUrl;
  final String? orderType;
  final List<PaymentOrderItem> items;
  final PaymentOrderPricing? pricing;
  final List<PaymentOrderSeller> sellers;

  /// Each seller's accept / reject decision, when the API includes it.
  final List<PaymentOrderSellerDecision> sellerDecisions;

  /// Points spent on and earned by this order.
  final PaymentOrderRewardPoints rewardPoints;

  PaymentOrderSellerDecision? decisionFor(String sellerId) {
    for (final d in sellerDecisions) {
      if (d.sellerId == sellerId) return d;
    }
    return null;
  }

  String get primaryProductLabel =>
      items.isEmpty ? 'Order' : items.map((e) => e.name).join(', ');

  String get primarySellerName {
    if (sellers.isNotEmpty) return sellers.first.companyName;
    final withSeller = items.where((e) => e.sellerName != null);
    if (withSeller.isNotEmpty) return withSeller.first.sellerName!;
    return 'Seller';
  }
}

/// The `rewardPoints` block of an order.
class PaymentOrderRewardPoints {
  const PaymentOrderRewardPoints({
    this.used = 0,
    this.usedAmountInr = 0,
    this.earnsPoints = false,
    this.earned,
    this.clubName,
    this.earnMultiplier = 1,
  });

  static const none = PaymentOrderRewardPoints();

  /// Points spent on this order and their ₹ value.
  final int used;
  final double usedAmountInr;

  /// False when placed while the programme was off.
  final bool earnsPoints;

  /// Null until the order completes, then a number (can be 0).
  final int? earned;

  /// The buyer's club when the order was placed, and its bonus (already
  /// included in [earned]).
  final String? clubName;
  final double earnMultiplier;

  bool get hasClubBonus => clubName != null && earnMultiplier > 1;
}

class PaymentOrderItem {
  const PaymentOrderItem({
    required this.productId,
    required this.productType,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.image,
    this.sellerId,
    this.sellerName,
    this.isReturned = false,
  });

  final String productId;
  final String productType;
  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? image;
  final String? sellerId;
  final String? sellerName;
  final bool isReturned;
}

class PaymentOrderPricing {
  const PaymentOrderPricing({
    this.subtotal = 0,
    this.discountedSubtotal = 0,
    this.promotionDiscount = 0,
    this.gst = 0,
    this.transactionFee = 0,
    this.platformFee = 0,
    this.gemworldVerificationCommission = 0,
    this.totalUsd = 0,
    this.exchangeRate = 0,
    this.subtotalInr = 0,
    this.totalInr = 0,
  });

  final double subtotal;
  final double discountedSubtotal;
  final double promotionDiscount;
  final double gst;
  final double transactionFee;
  final double platformFee;
  final double gemworldVerificationCommission;
  final double totalUsd;
  final double exchangeRate;
  final double subtotalInr;
  final double totalInr;
}

/// Seller approval states from Swagger (`/seller/orders` status filter).
abstract final class SellerDecisionStatuses {
  static const pending = 'PENDING';
  static const accepted = 'ACCEPTED';
  static const rejected = 'REJECTED';

  static const all = {pending, accepted, rejected};
}

/// One seller's decision on their portion of a marketplace order.
class PaymentOrderSellerDecision {
  const PaymentOrderSellerDecision({
    required this.sellerId,
    required this.status,
    this.sellerName,
    this.reason,
    this.sellerNote,
    this.decidedAt,
  });

  final String sellerId;

  /// One of [SellerDecisionStatuses].
  final String status;
  final String? sellerName;
  final String? reason;
  final String? sellerNote;
  final DateTime? decidedAt;

  bool get isPending => status == SellerDecisionStatuses.pending;
  bool get isAccepted => status == SellerDecisionStatuses.accepted;
  bool get isRejected => status == SellerDecisionStatuses.rejected;
}

class PaymentOrderSeller {
  const PaymentOrderSeller({
    required this.id,
    required this.companyName,
    this.sellerType,
    this.city,
    this.country,
    this.isVerified = false,
  });

  final String id;
  final String companyName;
  final String? sellerType;
  final String? city;
  final String? country;
  final bool isVerified;
}

class PaymentOrdersPage {
  const PaymentOrdersPage({
    required this.orders,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<PaymentOrder> orders;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
