import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../domain/models/payment_models.dart';
import 'razorpay_platform_checkout_stub.dart'
    if (dart.library.html) 'razorpay_platform_checkout_web.dart'
    as platform;

/// Thin Razorpay Checkout wrapper — amounts/keys come only from the server.
class RazorpayCheckoutService {
  Razorpay? _mobileRazorpay;
  Completer<Result<RazorpayPaymentSuccess, Failure>>? _pending;

  Future<Result<RazorpayPaymentSuccess, Failure>> open(
    PaymentCheckoutSession session,
  ) async {
    if (_pending != null && !_pending!.isCompleted) {
      return Result.failure(
        const ValidationFailure('A payment is already in progress.'),
      );
    }

    // Web: checkout.js via JS interop (plugin has no reliable web channel).
    if (kIsWeb) {
      return platform.openPlatformCheckout(session);
    }

    return _openMobile(session);
  }

  Future<Result<RazorpayPaymentSuccess, Failure>> _openMobile(
    PaymentCheckoutSession session,
  ) {
    final completer = Completer<Result<RazorpayPaymentSuccess, Failure>>();
    _pending = completer;

    final razorpay = Razorpay();
    _mobileRazorpay = razorpay;

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (dynamic response) {
      final success = response is PaymentSuccessResponse ? response : null;
      final paymentId = success?.paymentId?.trim() ?? '';
      final orderId = success?.orderId?.trim() ?? '';
      final signature = success?.signature?.trim() ?? '';
      if (paymentId.isEmpty || orderId.isEmpty || signature.isEmpty) {
        _complete(
          Result.failure(
            const NetworkFailure(
              'Payment succeeded but confirmation details were incomplete.',
            ),
          ),
        );
        return;
      }
      _complete(
        Result.success(
          RazorpayPaymentSuccess(
            razorpayOrderId: orderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: signature,
          ),
        ),
      );
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (dynamic response) {
      final failure = response is PaymentFailureResponse ? response : null;
      final code = failure?.code;
      final message = failure?.message?.trim();
      if (code == Razorpay.PAYMENT_CANCELLED) {
        _complete(
          Result.failure(const ValidationFailure('Payment was cancelled.')),
        );
        return;
      }
      _complete(
        Result.failure(
          ValidationFailure(
            (message != null && message.isNotEmpty)
                ? message
                : 'Payment failed. Please try again.',
          ),
        ),
      );
    });

    final options = <String, dynamic>{
      'key': session.keyId,
      'amount': session.amountPaise,
      'currency': session.currency,
      'name': session.checkoutName ?? 'GemWorld',
      'description': session.description ?? 'Order ${session.orderId}',
      'order_id': session.razorpayOrderId,
      'prefill': {
        if (session.userName != null) 'name': session.userName,
        if (session.userEmail != null) 'email': session.userEmail,
        if (session.userPhone != null) 'contact': session.userPhone,
      },
      'theme': {'color': '#8B6914'},
    };

    Future<void>(() async {
      try {
        razorpay.open(options);
      } catch (_) {
        _complete(
          Result.failure(
            const NetworkFailure('Could not open the payment checkout.'),
          ),
        );
      }
    });

    return completer.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () {
        dispose();
        return Result.failure(
          const ValidationFailure('Payment timed out. Please try again.'),
        );
      },
    );
  }

  void _complete(Result<RazorpayPaymentSuccess, Failure> result) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    pending.complete(result);
    _pending = null;
    dispose();
  }

  void dispose() {
    _mobileRazorpay?.clear();
    _mobileRazorpay = null;
  }
}
