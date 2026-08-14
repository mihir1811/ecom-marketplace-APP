import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/payment_models.dart';

/// Payment and order operations backed by `/payment/*` APIs.
abstract class PaymentRepository {
  Future<Result<ExchangeRate, Failure>> getExchangeRate();

  Future<Result<PaymentCheckoutSession, Failure>> createOrder({
    bool wantGemworldVerification = false,
    bool useWallet = false,
  });

  Future<Result<PaymentOrder, Failure>> verifyPayment({
    required String orderId,
    required RazorpayPaymentSuccess success,
  });

  Future<Result<PaymentOrdersPage, Failure>> listOrders({
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  });

  Future<Result<PaymentOrder, Failure>> getOrder(String orderId);
}
