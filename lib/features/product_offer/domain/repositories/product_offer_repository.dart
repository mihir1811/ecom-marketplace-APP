import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/product_offer.dart';

abstract class ProductOfferRepository {
  Future<Result<ProductOffer, Failure>> create({
    required String productId,
    required String productType,
    required String amount,
    String? message,
    CancelToken? cancelToken,
  });

  Future<Result<List<ProductOffer>, Failure>> listMine({
    required String productType,
    required String productId,
    CancelToken? cancelToken,
  });

  Future<Result<ProductOfferListPage, Failure>> listSeller({
    required int page,
    int limit = 10,
    String? search,
    String? statusFilter,
    CancelToken? cancelToken,
  });

  Future<Result<ProductOffer, Failure>> respond({
    required String id,
    required ProductOfferStatus status,
    CancelToken? cancelToken,
  });
}
