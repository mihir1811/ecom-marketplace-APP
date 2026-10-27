import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../jewelry/data/mappers/marketplace_json.dart';
import '../../domain/models/bag_line.dart';
import '../../domain/models/marketplace_order.dart';
import '../../domain/models/marketplace_quote.dart';
import '../../domain/repositories/jewelry_checkout_repository.dart';
import '../mappers/jewelry_checkout_mapper.dart';

final jewelryCheckoutRepositoryProvider = Provider<JewelryCheckoutRepository>(
  (ref) => JewelryCheckoutRepositoryImpl(ref.watch(dioProvider)),
);

/// Live marketplace checkout backed by `/marketplace/cart/quote` and
/// `/marketplace/orders/*`.
class JewelryCheckoutRepositoryImpl implements JewelryCheckoutRepository {
  JewelryCheckoutRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<CartQuote, Failure>> quote(List<BagLine> lines) =>
      _guard(() async {
        final response = await _dio.post<Object?>(
          ApiEndpoints.marketplaceCartQuote,
          data: {'items': lines.map((l) => l.toRequestJson()).toList()},
        );
        return JewelryCheckoutMapper.quote(MarketplaceJson.data(response.data));
      });

  @override
  Future<Result<MarketplaceCheckoutSession, Failure>> createOrder({
    required List<BagLine> lines,
    required MarketplaceAddress address,
    String? note,
  }) => _guard(() async {
    final trimmed = note?.trim() ?? '';
    final response = await _dio.post<Object?>(
      ApiEndpoints.marketplaceOrders,
      data: {
        'items': lines.map((l) => l.toRequestJson()).toList(),
        'address': address.toJson(),
        if (trimmed.isNotEmpty) 'note': trimmed,
      },
    );
    return JewelryCheckoutMapper.session(MarketplaceJson.data(response.data));
  });

  @override
  Future<Result<MarketplaceOrder, Failure>> verify({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) => _guard(() async {
    final response = await _dio.post<Object?>(
      ApiEndpoints.marketplaceOrderVerify(orderId),
      data: {
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      },
    );
    return JewelryCheckoutMapper.orderFrom(MarketplaceJson.data(response.data));
  });

  @override
  Future<Result<MarketplaceCheckoutSession, Failure>> pay(String orderId) =>
      _guard(() async {
        final response = await _dio.post<Object?>(
          ApiEndpoints.marketplaceOrderPay(orderId),
        );
        return JewelryCheckoutMapper.session(
          MarketplaceJson.data(response.data),
        );
      });

  @override
  Future<Result<List<MarketplaceOrder>, Failure>> orders() => _guard(() async {
    final response = await _dio.get<Object?>(ApiEndpoints.marketplaceOrders);
    return JewelryCheckoutMapper.orders(MarketplaceJson.data(response.data));
  });

  @override
  Future<Result<MarketplaceOrder, Failure>> order(String orderId) =>
      _guard(() async {
        final response = await _dio.get<Object?>(
          ApiEndpoints.marketplaceOrder(orderId),
        );
        return JewelryCheckoutMapper.orderFrom(
          MarketplaceJson.data(response.data),
        );
      });

  @override
  Future<Result<MarketplaceOrder, Failure>> cancelItem({
    required String orderId,
    required String itemId,
    required String reason,
    String? note,
  }) => _guard(() async {
    final trimmed = note?.trim() ?? '';
    final response = await _dio.post<Object?>(
      ApiEndpoints.marketplaceOrderItemCancel(orderId, itemId),
      data: {'reason': reason, if (trimmed.isNotEmpty) 'note': trimmed},
    );
    return JewelryCheckoutMapper.orderFrom(MarketplaceJson.data(response.data));
  });

  static Future<Result<T, Failure>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.success(await run());
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
