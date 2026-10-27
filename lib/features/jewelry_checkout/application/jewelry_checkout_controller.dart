import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../payment/application/razorpay_checkout_service.dart';
import '../../payment/domain/models/payment_models.dart';
import '../data/repositories/jewelry_checkout_repository_impl.dart';
import '../domain/models/bag_line.dart';
import '../domain/models/marketplace_order.dart';
import '../domain/repositories/jewelry_checkout_repository.dart';
import 'jewelry_bag_provider.dart';
import 'jewelry_orders_provider.dart';

/// How a checkout attempt ended.
sealed class JewelryCheckoutOutcome {
  const JewelryCheckoutOutcome();
}

/// The API marked the order paid.
class JewelryCheckoutPaid extends JewelryCheckoutOutcome {
  const JewelryCheckoutPaid(this.order);
  final MarketplaceOrder order;
}

/// The order exists but is not paid (Razorpay closed or failed); offer
/// "Pay now" for [orderId].
class JewelryCheckoutNotPaid extends JewelryCheckoutOutcome {
  const JewelryCheckoutNotPaid(this.message, this.orderId);
  final String message;
  final String orderId;
}

/// Nothing was charged (validation, bag changed, network).
class JewelryCheckoutFailed extends JewelryCheckoutOutcome {
  const JewelryCheckoutFailed(this.message, {this.bagChanged = false});
  final String message;

  /// The API re-priced the bag and found problems: quote again.
  final bool bagChanged;
}

/// Checkout is three calls: quote (the bag screen), create the order, then
/// verify the Razorpay payment. Only the API marks an order paid: after a
/// Razorpay error or a failed verify the order is read again, because the
/// API may already have found the payment.
class JewelryCheckoutController extends Notifier<bool> {
  final RazorpayCheckoutService _razorpay = RazorpayCheckoutService();

  JewelryCheckoutRepository get _repo =>
      ref.read(jewelryCheckoutRepositoryProvider);

  /// True while a checkout is running.
  @override
  bool build() {
    ref.onDispose(_razorpay.dispose);
    return false;
  }

  /// Call once per tap: every successful call creates a new order.
  Future<JewelryCheckoutOutcome> placeOrder({
    required List<BagLine> lines,
    required MarketplaceAddress address,
    String? note,
  }) => _run(() async {
    final created = await _repo.createOrder(
      lines: lines,
      address: address,
      note: note,
    );
    switch (created) {
      case ResultFailure(failure: final f):
        return JewelryCheckoutFailed(
          f.message,
          bagChanged: f.message.toLowerCase().contains('bag have changed'),
        );
      case Success(value: final session):
        await ref.read(jewelryBagStoreProvider).writeAddress(address);
        final outcome = await _payAndConfirm(session);
        if (outcome is JewelryCheckoutPaid) {
          ref
              .read(jewelryBagProvider.notifier)
              .removeAll(lines.map((l) => l.key));
        }
        return outcome;
    }
  });

  /// Opens Razorpay again for an unpaid order.
  Future<JewelryCheckoutOutcome> payAgain(String orderId) => _run(() async {
    final session = await _repo.pay(orderId);
    return switch (session) {
      Success(value: final s) => await _payAndConfirm(s),
      ResultFailure(failure: final f) => JewelryCheckoutFailed(f.message),
    };
  });

  Future<JewelryCheckoutOutcome> _run(
    Future<JewelryCheckoutOutcome> Function() body,
  ) async {
    if (state) {
      return const JewelryCheckoutFailed('A payment is already in progress.');
    }
    state = true;
    try {
      return await body();
    } finally {
      state = false;
      ref.invalidate(jewelryOrdersProvider);
    }
  }

  Future<JewelryCheckoutOutcome> _payAndConfirm(
    MarketplaceCheckoutSession session,
  ) async {
    final paid = await _razorpay.open(
      PaymentCheckoutSession(
        orderId: session.orderId,
        razorpayOrderId: session.razorpayOrderId,
        amountPaise: session.amountPaise,
        currency: session.currency,
        keyId: session.keyId,
        userName: session.prefill['name'],
        userEmail: session.prefill['email'],
        userPhone: session.prefill['contact'],
        description: session.description,
        checkoutName: session.name,
      ),
    );
    switch (paid) {
      case Success(value: final p):
        final verified = await _repo.verify(
          orderId: session.orderId,
          razorpayOrderId: p.razorpayOrderId,
          razorpayPaymentId: p.razorpayPaymentId,
          razorpaySignature: p.razorpaySignature,
        );
        if (verified case Success(value: final order)) {
          return JewelryCheckoutPaid(order);
        }
        return _settle(session.orderId, 'We could not confirm the payment yet.');
      case ResultFailure(failure: final Failure f):
        return _settle(session.orderId, f.message);
    }
  }

  /// The order read asks Razorpay, so a payment taken without a verify
  /// still counts.
  Future<JewelryCheckoutOutcome> _settle(String orderId, String message) async {
    final read = await _repo.order(orderId);
    if (read case Success(value: final order) when order.isPaid) {
      return JewelryCheckoutPaid(order);
    }
    return JewelryCheckoutNotPaid(message, orderId);
  }
}

final jewelryCheckoutProvider =
    NotifierProvider<JewelryCheckoutController, bool>(
      JewelryCheckoutController.new,
    );
