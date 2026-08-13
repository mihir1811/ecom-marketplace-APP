import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/payment_models.dart';
import '../../domain/repositories/payment_repository.dart';
import '../mappers/payment_mapper.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepositoryImpl(ref.watch(dioProvider)),
);

/// Live payment repository backed by `/payment/*` APIs.
class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<ExchangeRate, Failure>> getExchangeRate() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.paymentExchangeRate,
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not fetch the exchange rate.'),
        );
      }
      return Result.success(PaymentMapper.exchangeRateFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<PaymentCheckoutSession, Failure>> createOrder({
    bool wantGemworldVerification = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.paymentCreateOrder,
        data: {'wantGemworldVerification': wantGemworldVerification},
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not create the payment order.'),
        );
      }
      final session = PaymentMapper.checkoutSessionFromJson(data);
      if (session.orderId.isEmpty ||
          session.razorpayOrderId.isEmpty ||
          session.keyId.isEmpty ||
          session.amountPaise <= 0) {
        return Result.failure(
          const NetworkFailure('Payment order response was incomplete.'),
        );
      }
      return Result.success(session);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<PaymentOrder, Failure>> verifyPayment({
    required String orderId,
    required RazorpayPaymentSuccess success,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.paymentVerify,
        data: {
          'orderId': orderId,
          'razorpayOrderId': success.razorpayOrderId,
          'razorpayPaymentId': success.razorpayPaymentId,
          'razorpaySignature': success.razorpaySignature,
        },
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is Map<String, dynamic>) {
        return Result.success(PaymentMapper.orderFromJson(data));
      }
      // Some backends return only success without order body — fetch order.
      return getOrder(orderId);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<PaymentOrdersPage, Failure>> listOrders({
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.paymentOrders,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          'page': page,
          'limit': limit,
        },
        cancelToken: cancelToken,
      );
      final root = response.data ?? const <String, dynamic>{};
      return Result.success(PaymentMapper.ordersPageFromJson(root));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<PaymentOrder, Failure>> getOrder(String orderId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.paymentOrderById(orderId),
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Order not found.'),
        );
      }
      return Result.success(PaymentMapper.orderFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
