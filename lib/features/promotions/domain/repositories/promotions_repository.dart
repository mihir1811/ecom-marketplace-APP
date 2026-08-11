import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/promotion.dart';

abstract class PromotionsRepository {
  Future<Result<List<Discount>, Failure>> listDiscounts({
    CancelToken? cancelToken,
  });

  Future<Result<Discount, Failure>> createDiscount(
    DiscountInput input, {
    CancelToken? cancelToken,
  });

  Future<Result<Discount, Failure>> updateDiscount(
    String id,
    DiscountInput input, {
    CancelToken? cancelToken,
  });

  Future<Result<Discount, Failure>> deleteDiscount(
    String id, {
    CancelToken? cancelToken,
  });

  Future<Result<List<PromoCode>, Failure>> listPromoCodes({
    CancelToken? cancelToken,
  });

  Future<Result<PromoCode, Failure>> createPromoCode(
    PromoCodeInput input, {
    CancelToken? cancelToken,
  });

  Future<Result<PromoCode, Failure>> updatePromoCode(
    String id,
    PromoCodeInput input, {
    CancelToken? cancelToken,
  });

  Future<Result<PromoCode, Failure>> deletePromoCode(
    String id, {
    CancelToken? cancelToken,
  });

  Future<Result<PublicPromotions, Failure>> getPublicPromotions(
    String sellerId, {
    CancelToken? cancelToken,
  });
}
