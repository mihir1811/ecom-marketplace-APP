import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/product_share.dart';

abstract class ProductShareRepository {
  Future<Result<ProductShareLink, Failure>> create({
    required String productType,
    required String productId,
    required ProductShareChannel channel,
    bool includePrice = false,
    bool includeImages = true,
    bool includeVideos = true,
    CancelToken? cancelToken,
  });

  Future<Result<ProductShareEmailResult, Failure>> sendEmail({
    required String shareId,
    required String email,
    String? name,
    CancelToken? cancelToken,
  });

  Future<Result<SharedProductPayload, Failure>> getByToken({
    required String token,
    CancelToken? cancelToken,
  });
}
