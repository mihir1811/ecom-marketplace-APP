import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/cart_summary.dart';

/// Cart catalog operations backed by `/cart/*` APIs.
abstract class CartRepository {
  Future<Result<List<CartItem>, Failure>> getCart({CancelToken? cancelToken});

  Future<Result<CartSummary, Failure>> getSummary({CancelToken? cancelToken});

  Future<Result<void, Failure>> addItem({
    required String productId,
    required String productType,
    int quantity = 1,
    Map<String, dynamic>? specifications,
  });

  Future<Result<void, Failure>> updateQuantity({
    required String cartId,
    required int quantity,
  });

  Future<Result<void, Failure>> removeItem({required String cartId});

  Future<Result<void, Failure>> clearCart();

  Future<Result<CartSummary, Failure>> applyPromo({
    required String code,
    String? sellerId,
  });

  Future<Result<CartSummary, Failure>> removePromo({required String code});
}
