import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../domain/models/payment_models.dart';

/// Non-web stub — mobile uses the Razorpay plugin path in [RazorpayCheckoutService].
Future<Result<RazorpayPaymentSuccess, Failure>> openPlatformCheckout(
  PaymentCheckoutSession session,
) async {
  return Result.failure(
    const NetworkFailure('Web checkout is not available on this platform.'),
  );
}
