import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/seller_product.dart';

/// Seller inventory list + mutations for natural and melee diamonds.
abstract class SellerProductRepository {
  Future<Result<List<SellerProduct>, Failure>> listProducts({
    required String sellerId,
    CancelToken? cancelToken,
  });

  Future<Result<void, Failure>> updateProduct(
    SellerProduct product, {
    CancelToken? cancelToken,
  });

  Future<Result<void, Failure>> deleteProduct(
    SellerProduct product, {
    CancelToken? cancelToken,
  });
}
