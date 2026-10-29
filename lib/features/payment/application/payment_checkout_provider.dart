import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../cart/application/cart_provider.dart';
import '../../cart/application/fees_providers.dart';
import '../../rewards/application/rewards_provider.dart';
import '../../wallet/application/wallet_provider.dart';
import '../data/repositories/payment_repository_impl.dart';
import '../domain/models/payment_models.dart';
import '../domain/repositories/payment_repository.dart';
import 'razorpay_checkout_service.dart';

/// Short-lived FX cache for cart INR estimates.
final exchangeRateProvider = FutureProvider.autoDispose<ExchangeRate>((
  ref,
) async {
  final link = ref.keepAlive();
  Timer? timer;
  timer = Timer(const Duration(minutes: 2), link.close);
  ref.onDispose(() => timer?.cancel());

  final result = await ref.watch(paymentRepositoryProvider).getExchangeRate();
  return switch (result) {
    Success(:final value) => value,
    ResultFailure(:final failure) => throw failure,
  };
});

enum CheckoutPhase {
  idle,
  creatingOrder,
  awaitingPayment,
  verifying,
  succeeded,
  failed,
}

class CheckoutState {
  const CheckoutState({
    this.phase = CheckoutPhase.idle,
    this.wantGemworldVerification = false,
    this.useWallet = false,
    this.usePoints = false,
    this.errorMessage,
    this.paidOrder,
  });

  final CheckoutPhase phase;
  final bool wantGemworldVerification;
  final bool useWallet;

  /// Buyer turned on "Use reward points"; the server applies the limits.
  final bool usePoints;
  final String? errorMessage;
  final PaymentOrder? paidOrder;

  bool get isBusy =>
      phase == CheckoutPhase.creatingOrder ||
      phase == CheckoutPhase.awaitingPayment ||
      phase == CheckoutPhase.verifying;

  CheckoutState copyWith({
    CheckoutPhase? phase,
    bool? wantGemworldVerification,
    bool? useWallet,
    bool? usePoints,
    String? errorMessage,
    PaymentOrder? paidOrder,
    bool clearError = false,
    bool clearOrder = false,
  }) {
    return CheckoutState(
      phase: phase ?? this.phase,
      wantGemworldVerification:
          wantGemworldVerification ?? this.wantGemworldVerification,
      useWallet: useWallet ?? this.useWallet,
      usePoints: usePoints ?? this.usePoints,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      paidOrder: clearOrder ? null : (paidOrder ?? this.paidOrder),
    );
  }
}

/// Single-flight checkout: create-order → Razorpay → server verify.
class PaymentCheckoutNotifier extends Notifier<CheckoutState> {
  final RazorpayCheckoutService _razorpay = RazorpayCheckoutService();

  PaymentRepository get _payments => ref.read(paymentRepositoryProvider);

  @override
  CheckoutState build() {
    ref.onDispose(_razorpay.dispose);

    ref.listen(exchangeRateProvider, (prev, next) {
      next.whenData((rate) {
        ref.read(cartProvider.notifier).setExchangeRate(rate.rate);
      });
    });

    return const CheckoutState();
  }

  void setWantGemworldVerification(bool value) {
    if (state.isBusy) return;
    state = state.copyWith(wantGemworldVerification: value);
  }

  void setUseWallet(bool value) {
    if (state.isBusy) return;
    state = state.copyWith(useWallet: value);
  }

  void setUsePoints(bool value) {
    if (state.isBusy) return;
    state = state.copyWith(usePoints: value);
  }

  Future<Result<PaymentOrder, Failure>> checkout({double? payableInr}) async {
    if (state.isBusy) {
      return Result.failure(
        const ValidationFailure('Payment is already in progress.'),
      );
    }

    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      return Result.failure(const ValidationFailure('Your cart is empty.'));
    }
    if (cart.items.any((e) => !e.isAvailable)) {
      return Result.failure(
        const ValidationFailure('Remove unavailable items before payment.'),
      );
    }
    if (!cart.canCheckout || cart.address == null) {
      return Result.failure(
        const ValidationFailure(
          'Please add and select a delivery address before payment.',
        ),
      );
    }

    final fees = ref.read(activeFeesProvider).valueOrNull;
    final wantVerification =
        state.wantGemworldVerification &&
        (fees?.offersGemworldVerification ?? false);
    final useWallet = state.useWallet;
    final rewards = ref.read(rewardsProvider).valueOrNull;
    final usePoints = state.usePoints && (rewards?.canSpend ?? false);

    state = state.copyWith(
      phase: CheckoutPhase.creatingOrder,
      clearError: true,
      clearOrder: true,
    );

    final synced = await ref
        .read(cartProvider.notifier)
        .syncSelectedAddressForCheckout();
    if (synced is ResultFailure<void, Failure>) {
      state = state.copyWith(
        phase: CheckoutPhase.failed,
        errorMessage: synced.failure.message,
      );
      return Result.failure(synced.failure);
    }

    final created = await _payments.createOrder(
      wantGemworldVerification: wantVerification,
      useWallet: useWallet,
      usePoints: usePoints,
    );
    if (created is ResultFailure<PaymentCheckoutSession, Failure>) {
      state = state.copyWith(
        phase: CheckoutPhase.failed,
        errorMessage: created.failure.message,
      );
      if (usePoints) refreshRewards(ref);
      return Result.failure(created.failure);
    }

    final session = (created as Success<PaymentCheckoutSession, Failure>).value;

    final walletSettled =
        session.isFullyPaidByWallet ||
        ((useWallet || usePoints) &&
            session.orderId.isNotEmpty &&
            session.amountPaise <= 0 &&
            session.razorpayOrderId.isEmpty);

    if (walletSettled) {
      state = state.copyWith(phase: CheckoutPhase.verifying);
      var order = PaymentOrder(
        id: session.orderId,
        status: session.status ?? 'PAID',
        amount: session.amountInr ?? 0,
        amountUsd: session.amountUsd ?? 0,
        currency: session.currency,
        createdAt: DateTime.now(),
      );
      final detailed = await _payments.getOrder(session.orderId);
      if (detailed case Success(:final value)) {
        order = value;
      }
      state = state.copyWith(
        phase: CheckoutPhase.succeeded,
        paidOrder: order,
        clearError: true,
      );
      if (session.rewardPointsUsed > 0 || usePoints) refreshRewards(ref);
      await Future.wait([
        ref.read(cartProvider.notifier).refresh(),
        ref.read(walletProvider.notifier).refresh(),
      ]);
      return Result.success(order);
    }

    state = state.copyWith(phase: CheckoutPhase.awaitingPayment);
    late final Result<RazorpayPaymentSuccess, Failure> paid;
    try {
      paid = await _razorpay.open(session);
    } catch (_) {
      state = state.copyWith(
        phase: CheckoutPhase.failed,
        errorMessage: 'Could not open the payment checkout.',
      );
      await ref.read(cartProvider.notifier).refresh();
      return Result.failure(
        const NetworkFailure('Could not open the payment checkout.'),
      );
    }
    if (paid is ResultFailure<RazorpayPaymentSuccess, Failure>) {
      state = state.copyWith(
        phase: CheckoutPhase.failed,
        errorMessage: paid.failure.message,
      );
      await ref.read(cartProvider.notifier).refresh();
      return Result.failure(paid.failure);
    }

    final success = (paid as Success<RazorpayPaymentSuccess, Failure>).value;

    state = state.copyWith(phase: CheckoutPhase.verifying);
    final verified = await _payments.verifyPayment(
      orderId: session.orderId,
      success: success,
    );
    // Points leave the balance at verify; a failure such as "Not enough
    // reward points" needs the fresh balance too.
    if (session.rewardPointsUsed > 0 || usePoints) refreshRewards(ref);

    if (verified is ResultFailure<PaymentOrder, Failure>) {
      state = state.copyWith(
        phase: CheckoutPhase.failed,
        errorMessage: verified.failure.message,
      );
      await ref.read(cartProvider.notifier).refresh();
      return Result.failure(verified.failure);
    }

    var order = (verified as Success<PaymentOrder, Failure>).value;
    // Prefer full order detail (sellers / items) for the success dialog.
    final detailed = await _payments.getOrder(session.orderId);
    if (detailed case Success(:final value)) {
      order = value;
    }

    state = state.copyWith(
      phase: CheckoutPhase.succeeded,
      paidOrder: order,
      clearError: true,
    );
    await Future.wait([
      ref.read(cartProvider.notifier).refresh(),
      if (useWallet) ref.read(walletProvider.notifier).refresh(),
    ]);
    return Result.success(order);
  }

  /// Orders over the online-payment limit (charges included) can't be paid
  /// in the app; `create-order` refuses them with this code.
  static bool needsContactGemworld(Failure failure) =>
      failure is ValidationFailure &&
      failure.code == 'CONTACT_GEMWORLD_REQUIRED';

  /// `POST /payment/contact-gemworld`: the bag becomes a pending order that
  /// GemWorld completes with the buyer. Accepted offers and auction wins in
  /// it pause their 24-hour clocks meanwhile.
  Future<Result<String, Failure>> contactGemworld({
    required String contactPhone,
    String? note,
  }) async {
    if (state.isBusy) {
      return Result.failure(
        const ValidationFailure('Payment is already in progress.'),
      );
    }
    final result = await _payments.contactGemworld(
      contactPhone: contactPhone,
      note: note,
    );
    if (result is Success<String, Failure>) {
      state = state.copyWith(phase: CheckoutPhase.idle, clearError: true);
      await ref.read(cartProvider.notifier).refresh();
    }
    return result;
  }

  void reset() {
    if (state.isBusy) return;
    state = CheckoutState(
      wantGemworldVerification: state.wantGemworldVerification,
      useWallet: state.useWallet,
      usePoints: state.usePoints,
    );
  }
}

final paymentCheckoutProvider =
    NotifierProvider<PaymentCheckoutNotifier, CheckoutState>(
      PaymentCheckoutNotifier.new,
    );

final orderDetailProvider = FutureProvider.autoDispose
    .family<PaymentOrder, String>((ref, orderId) async {
      final result = await ref
          .watch(paymentRepositoryProvider)
          .getOrder(orderId);
      return switch (result) {
        Success(:final value) => value,
        ResultFailure(:final failure) => throw failure,
      };
    });
