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

  /// Signed-in buyer's offers across every stone, newest first, with the
  /// product snapshot (`GET /product-offer/mine`).
  Future<Result<ProductOfferListPage, Failure>> listMineAll({
    required int page,
    int limit = 20,
    String? statusFilter,
    CancelToken? cancelToken,
  });

  Future<Result<ProductOfferListPage, Failure>> listSeller({
    required int page,
    int limit = 10,
    String? statusFilter,
    CancelToken? cancelToken,
  });

  /// Seller answers a buyer's offer; buyer answers the seller's
  /// counter-offer. `COUNTERED` needs [amount] (decimal string) and returns
  /// the new counter-offer.
  Future<Result<ProductOffer, Failure>> respond({
    required String id,
    required ProductOfferStatus status,
    String? amount,
    String? message,
    CancelToken? cancelToken,
  });
}
