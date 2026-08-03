import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../domain/models/payment_models.dart';

/// Opens Razorpay Checkout on web via checkout.js (loads script if missing).
Future<Result<RazorpayPaymentSuccess, Failure>> openPlatformCheckout(
  PaymentCheckoutSession session,
) async {
  try {
    await _ensureCheckoutScript();
  } catch (_) {
    return Result.failure(
      const NetworkFailure(
        'Could not load the payment checkout. Refresh the page and try again.',
      ),
    );
  }

  if (!_isRazorpayAvailable()) {
    return Result.failure(
      const NetworkFailure(
        'Payment checkout is unavailable. Refresh the page and try again.',
      ),
    );
  }

  final completer = Completer<Result<RazorpayPaymentSuccess, Failure>>();

  void completeOnce(Result<RazorpayPaymentSuccess, Failure> result) {
    if (!completer.isCompleted) completer.complete(result);
  }

  void onSuccess(JSAny? response) {
    try {
      final map = _jsObjectToMap(response);
      final paymentId = '${map['razorpay_payment_id'] ?? ''}'.trim();
      final orderId = '${map['razorpay_order_id'] ?? ''}'.trim();
      final signature = '${map['razorpay_signature'] ?? ''}'.trim();
      if (paymentId.isEmpty || orderId.isEmpty || signature.isEmpty) {
        completeOnce(
          Result.failure(
            const NetworkFailure(
              'Payment succeeded but confirmation details were incomplete.',
            ),
          ),
        );
        return;
      }
      completeOnce(
        Result.success(
          RazorpayPaymentSuccess(
            razorpayOrderId: orderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: signature,
          ),
        ),
      );
    } catch (_) {
      completeOnce(
        Result.failure(
          const NetworkFailure('Could not read the payment response.'),
        ),
      );
    }
  }

  void onDismiss() {
    completeOnce(
      Result.failure(
        const ValidationFailure('Payment was cancelled.'),
      ),
    );
  }

  void onFailed(JSAny? response) {
    try {
      final map = _jsObjectToMap(response);
      final error = map['error'];
      var message = 'Payment failed. Please try again.';
      if (error is Map) {
        final description = error['description'];
        if (description != null && '$description'.trim().isNotEmpty) {
          message = '$description'.trim();
        }
      }
      completeOnce(Result.failure(ValidationFailure(message)));
    } catch (_) {
      completeOnce(
        Result.failure(
          const ValidationFailure('Payment failed. Please try again.'),
        ),
      );
    }
  }

  // Do not put Dart functions in the map before jsify — attach after.
  final options = <String, Object?>{
    'key': session.keyId,
    'amount': session.amountPaise,
    'currency': session.currency,
    'name': 'Gemstone',
    'description': 'Order ${session.orderId}',
    'order_id': session.razorpayOrderId,
    'prefill': <String, Object?>{
      if (session.userName != null && session.userName!.isNotEmpty)
        'name': session.userName,
      if (session.userEmail != null && session.userEmail!.isNotEmpty)
        'email': session.userEmail,
      if (session.userPhone != null && session.userPhone!.isNotEmpty)
        'contact': session.userPhone,
    },
    'theme': <String, Object?>{'color': '#8B6914'},
    'modal': <String, Object?>{},
  };

  try {
    final jsOptions = options.jsify();
    if (jsOptions == null) {
      return Result.failure(
        const NetworkFailure('Could not open the payment checkout.'),
      );
    }

    final jsOptionsObj = jsOptions as JSObject;
    jsOptionsObj.setProperty('handler'.toJS, onSuccess.toJS);

    final modal = jsOptionsObj.getProperty('modal'.toJS);
    if (modal != null) {
      (modal as JSObject).setProperty('ondismiss'.toJS, onDismiss.toJS);
    } else {
      jsOptionsObj.setProperty(
        'modal'.toJS,
        {'ondismiss': onDismiss.toJS}.jsify(),
      );
    }

    final ctor = web.window.getProperty('Razorpay'.toJS);
    if (ctor == null) {
      return Result.failure(
        const NetworkFailure(
          'Payment checkout is unavailable. Refresh the page and try again.',
        ),
      );
    }

    final instance = (ctor as JSFunction).callAsConstructor(jsOptions);
    final rzp = instance as JSObject;
    rzp.callMethod('on'.toJS, 'payment.failed'.toJS, onFailed.toJS);
    rzp.callMethod('open'.toJS);
  } catch (_) {
    return Result.failure(
      const NetworkFailure('Could not open the payment checkout.'),
    );
  }

  return completer.future.timeout(
    const Duration(minutes: 10),
    onTimeout: () => Result.failure(
      const ValidationFailure('Payment timed out. Please try again.'),
    ),
  );
}

bool _isRazorpayAvailable() {
  try {
    return web.window.hasProperty('Razorpay'.toJS).toDart;
  } catch (_) {
    return web.window.getProperty('Razorpay'.toJS) != null;
  }
}

Future<void> _ensureCheckoutScript() async {
  if (_isRazorpayAvailable()) return;

  final existing = web.document.querySelector('#rzp-jssdk');
  if (existing != null) {
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (_isRazorpayAvailable()) return;
    }
  }

  final completer = Completer<void>();
  final script = web.HTMLScriptElement()
    ..id = 'rzp-jssdk'
    ..src = 'https://checkout.razorpay.com/v1/checkout.js'
    ..async = true;

  script.onload = (web.Event _) {
    if (!completer.isCompleted) completer.complete();
  }.toJS;

  script.onerror = (web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('Razorpay script failed to load'));
    }
  }.toJS;

  (web.document.head ?? web.document.body)?.append(script);
  await completer.future.timeout(const Duration(seconds: 15));

  for (var i = 0; i < 30; i++) {
    if (_isRazorpayAvailable()) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('Razorpay global missing after script load');
}

Map<Object?, Object?> _jsObjectToMap(JSAny? value) {
  if (value == null) return const {};
  final dartified = value.dartify();
  if (dartified is Map) {
    return Map<Object?, Object?>.from(dartified);
  }
  return const {};
}
