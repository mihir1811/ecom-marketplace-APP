import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../payment/application/razorpay_checkout_service.dart';
import '../../payment/domain/models/payment_models.dart';
import '../data/repositories/wallet_repository_impl.dart';
import '../domain/models/wallet.dart';
import '../domain/repositories/wallet_repository.dart';
import 'wallet_provider.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

enum WalletTopUpPhase {
  idle,
  creating,
  awaitingPayment,
  verifying,
  succeeded,
  failed,
}

class WalletTopUpState {
  const WalletTopUpState({
    this.phase = WalletTopUpPhase.idle,
    this.errorMessage,
    this.creditedWallet,
  });

  final WalletTopUpPhase phase;
  final String? errorMessage;
  final Wallet? creditedWallet;

  bool get isBusy =>
      phase == WalletTopUpPhase.creating ||
      phase == WalletTopUpPhase.awaitingPayment ||
      phase == WalletTopUpPhase.verifying;

  WalletTopUpState copyWith({
    WalletTopUpPhase? phase,
    String? errorMessage,
    Wallet? creditedWallet,
    bool clearError = false,
    bool clearWallet = false,
  }) {
    return WalletTopUpState(
      phase: phase ?? this.phase,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      creditedWallet: clearWallet
          ? null
          : (creditedWallet ?? this.creditedWallet),
    );
  }
}

/// Create top-up order → Razorpay Checkout → verify.
class WalletTopUpNotifier extends Notifier<WalletTopUpState>
    with DisposeTolerantNotifier<WalletTopUpState> {
  static const minAmountInr = 1.0;
  static const maxAmountInr = 100000.0;

  final RazorpayCheckoutService _razorpay = RazorpayCheckoutService();

  WalletRepository get _wallet => ref.read(walletRepositoryProvider);

  @override
  WalletTopUpState build() {
    ref.onDispose(_razorpay.dispose);
    return const WalletTopUpState();
  }

  Failure? validateAmount(double amountInr) {
    if (amountInr < minAmountInr) {
      return const ValidationFailure('Minimum top-up amount is ₹1.');
    }
    if (amountInr > maxAmountInr) {
      return const ValidationFailure('Maximum top-up amount is ₹1,00,000.');
    }
    return null;
  }

  Future<Result<Wallet, Failure>> topUp(double amountInr) async {
    if (state.isBusy) {
      return Result.failure(
        const ValidationFailure('A top-up is already in progress.'),
      );
    }

    final invalid = validateAmount(amountInr);
    if (invalid != null) {
      state = state.copyWith(
        phase: WalletTopUpPhase.failed,
        errorMessage: invalid.message,
      );
      return Result.failure(invalid);
    }

    state = state.copyWith(
      phase: WalletTopUpPhase.creating,
      clearError: true,
      clearWallet: true,
    );

    final created = await _wallet.createTopUp(amountInr: amountInr);
    if (created is ResultFailure<WalletTopUpSession, Failure>) {
      state = state.copyWith(
        phase: WalletTopUpPhase.failed,
        errorMessage: created.failure.message,
      );
      return Result.failure(created.failure);
    }

    final session = (created as Success<WalletTopUpSession, Failure>).value;
    final checkout = PaymentCheckoutSession(
      orderId: session.razorpayOrderId,
      razorpayOrderId: session.razorpayOrderId,
      amountPaise: session.amountPaise,
      currency: session.currency,
      keyId: session.keyId,
      amountInr: session.amountInr,
      userName: session.userName,
      userEmail: session.userEmail,
      description: 'Wallet top-up',
    );

    state = state.copyWith(phase: WalletTopUpPhase.awaitingPayment);
    late final Result<RazorpayPaymentSuccess, Failure> paid;
    try {
      paid = await _razorpay.open(checkout);
    } catch (_) {
      state = state.copyWith(
        phase: WalletTopUpPhase.failed,
        errorMessage: 'Could not open the payment checkout.',
      );
      return Result.failure(
        const NetworkFailure('Could not open the payment checkout.'),
      );
    }
    if (paid is ResultFailure<RazorpayPaymentSuccess, Failure>) {
      state = state.copyWith(
        phase: WalletTopUpPhase.failed,
        errorMessage: paid.failure.message,
      );
      return Result.failure(paid.failure);
    }

    final success = (paid as Success<RazorpayPaymentSuccess, Failure>).value;
    state = state.copyWith(phase: WalletTopUpPhase.verifying);
    final verified = await _wallet.verifyTopUp(success: success);
    if (verified is ResultFailure<Wallet, Failure>) {
      state = state.copyWith(
        phase: WalletTopUpPhase.failed,
        errorMessage: verified.failure.message,
      );
      return Result.failure(verified.failure);
    }

    final wallet = (verified as Success<Wallet, Failure>).value;
    state = state.copyWith(
      phase: WalletTopUpPhase.succeeded,
      creditedWallet: wallet,
      clearError: true,
    );
    ref.invalidate(walletProvider);
    await ref.read(walletTransactionsProvider.notifier).loadInitial();
    return Result.success(wallet);
  }

  void reset() {
    if (state.isBusy) return;
    state = const WalletTopUpState();
  }
}

final walletTopUpProvider =
    NotifierProvider<WalletTopUpNotifier, WalletTopUpState>(
      WalletTopUpNotifier.new,
    );
