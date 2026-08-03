import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/cart_summary.dart';
import '../../domain/repositories/cart_repository.dart';
import '../mappers/cart_mapper.dart';

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepositoryImpl(ref.watch(dioProvider)),
);

/// Live cart repository backed by `/cart/*` APIs.
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<CartItem>, Failure>> getCart({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.cart,
        cancelToken: cancelToken,
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      final list = data is List ? data : const [];
      final items = <CartItem>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final mapped = CartMapper.cartItemFromJson(item);
        if (mapped.cartId.isEmpty) continue;
        items.add(mapped);
      }
      return Result.success(items);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<CartSummary, Failure>> getSummary({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.cartSummary,
        cancelToken: cancelToken,
      );
      return Result.success(_parseSummary(response.data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> addItem({
    required String productId,
    required String productType,
    int quantity = 1,
    Map<String, dynamic>? specifications,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.cartAdd,
        data: {
          'productId': productId,
          'productType': productType,
          'quantity': quantity < 1 ? 1 : quantity,
          if (specifications != null) 'specifications': specifications,
        },
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> updateQuantity({
    required String cartId,
    required int quantity,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.cartUpdate,
        data: {'cartId': cartId, 'quantity': quantity},
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> removeItem({required String cartId}) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.cartRemove,
        data: {'cartId': cartId},
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> clearCart() async {
    try {
      await _dio.delete<Map<String, dynamic>>(ApiEndpoints.cart);
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<CartSummary, Failure>> applyPromo({
    required String code,
    String? sellerId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.cartApplyPromo,
        data: {
          'code': code,
          if (sellerId != null && sellerId.isNotEmpty) 'sellerId': sellerId,
        },
      );
      return Result.success(_parseSummary(response.data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<CartSummary, Failure>> removePromo({
    required String code,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.cartPromoCode,
        data: {'code': code},
      );
      return Result.success(_parseSummary(response.data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  CartSummary _parseSummary(Map<String, dynamic>? root) {
    final data = root?['data'];
    if (data is Map<String, dynamic>) {
      return CartMapper.summaryFromJson(data);
    }
    return CartSummary.empty;
  }
}
