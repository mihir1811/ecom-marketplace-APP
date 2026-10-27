import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/bag_line.dart';
import '../models/marketplace_order.dart';
import '../models/marketplace_quote.dart';

/// Jewellery marketplace pricing, orders and payment (`/marketplace`).
abstract class JewelryCheckoutRepository {
  /// Prices the bag (no sign-in). Call when the bag opens and before checkout.
  Future<Result<CartQuote, Failure>> quote(List<BagLine> lines);

  /// Saves a `PENDING_PAYMENT` order and opens a Razorpay order for it.
  /// Every success creates a new order: never retry this automatically.
  Future<Result<MarketplaceCheckoutSession, Failure>> createOrder({
    required List<BagLine> lines,
    required MarketplaceAddress address,
    String? note,
  });

  /// Confirms a Razorpay success; returns the order as `PAID`.
  Future<Result<MarketplaceOrder, Failure>> verify({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  });

  /// A fresh checkout session for an unpaid order.
  Future<Result<MarketplaceCheckoutSession, Failure>> pay(String orderId);

  /// Paid and cancelled orders, plus unpaid ones from the last 24 hours.
  Future<Result<List<MarketplaceOrder>, Failure>> orders();

  /// One order. Asks Razorpay first, so it settles any doubt about a payment.
  Future<Result<MarketplaceOrder, Failure>> order(String orderId);

  /// Cancels one piece and refunds it; returns the updated order.
  Future<Result<MarketplaceOrder, Failure>> cancelItem({
    required String orderId,
    required String itemId,
    required String reason,
    String? note,
  });
}
