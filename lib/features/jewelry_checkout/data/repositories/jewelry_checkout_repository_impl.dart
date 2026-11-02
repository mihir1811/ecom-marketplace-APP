import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../jewelry/data/mappers/marketplace_json.dart';
import '../../domain/models/bag_line.dart';
import '../../domain/models/marketplace_invoice.dart';
import '../../domain/models/marketplace_order.dart';
import '../../domain/models/marketplace_quote.dart';
import '../../domain/models/shop_order.dart';
import '../../domain/repositories/jewelry_checkout_repository.dart';
import '../mappers/jewelry_checkout_mapper.dart';

final jewelryCheckoutRepositoryProvider = Provider<JewelryCheckoutRepository>(
  (ref) => JewelryCheckoutRepositoryImpl(ref.watch(dioProvider)),
);

/// Live marketplace checkout backed by `/marketplace/cart/quote`,
/// `/marketplace/cart` and `/marketplace/orders/*`.
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
  Future<Result<int, Failure>> syncBag(List<BagLine> lines) => _guard(() async {
    final response = await _dio.put<Object?>(
      ApiEndpoints.marketplaceCart,
      data: {'items': lines.map((l) => l.toRequestJson()).toList()},
    );
    final items = MarketplaceJson.obj(
      MarketplaceJson.data(response.data),
    )['items'];
    return items is num ? items.toInt() : 0;
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
  Future<Result<List<ShopOrder>, Failure>> shopOrders() => _guard(() async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.marketplaceSellerOrders,
    );
    return JewelryCheckoutMapper.shopOrders(
      MarketplaceJson.data(response.data),
    );
  });

  @override
  Future<Result<MarketplaceInvoice, Failure>> invoice(String orderId) => _guard(
    () async {
      final response = await _dio.get<Object?>(
        ApiEndpoints.marketplaceOrderInvoice(orderId),
      );
      return JewelryCheckoutMapper.invoice(MarketplaceJson.data(response.data));
    },
  );

  /// The storefront lists live on another host: a bare client, so the
  /// sign-in token never leaves the API.
  static final Dio _storefront = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  @override
  Future<Result<List<({String code, String name})>, Failure>> locations({
    String? country,
    String? state,
  }) => _guard(() async {
    final response = await _storefront.get<Object?>(
      ApiEndpoints.jewelryStorefrontLocations,
      queryParameters: {'country': ?country, 'state': ?state},
    );
    final items = MarketplaceJson.obj(response.data)['items'];
    if (items is! List) return const [];
    return [
      for (final e in items)
        if (e is Map)
          (code: '${e['code'] ?? ''}'.trim(), name: '${e['name'] ?? ''}'.trim())
        else if (e != null && '$e'.trim().isNotEmpty)
          (code: '$e'.trim(), name: '$e'.trim()),
    ].where((l) => l.code.isNotEmpty && l.name.isNotEmpty).toList();
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
