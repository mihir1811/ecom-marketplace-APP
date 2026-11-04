import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/promotion.dart';
import '../../domain/repositories/promotions_repository.dart';
import '../mappers/promotions_mapper.dart';

final promotionsRepositoryProvider = Provider<PromotionsRepository>(
  (ref) => PromotionsRepositoryImpl(ref.watch(dioProvider)),
);

class PromotionsRepositoryImpl implements PromotionsRepository {
  PromotionsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<Discount>, Failure>> listDiscounts({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.promotionsDiscounts,
        cancelToken: cancelToken,
      );
      return Result.success(PromotionsMapper.discountsFromRoot(response.data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Discount, Failure>> createDiscount(
    DiscountInput input, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.promotionsDiscounts,
        data: input.toJson(),
        cancelToken: cancelToken,
      );
      final discount = PromotionsMapper.discountFromResponse(response.data);
      if (discount == null) {
        return Result.failure(
          const NetworkFailure('Could not create discount.'),
        );
      }
      return Result.success(discount);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Discount, Failure>> updateDiscount(
    String id,
    DiscountInput input, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.promotionsDiscountById(id),
        data: input.toJson(),
        cancelToken: cancelToken,
      );
      final discount = PromotionsMapper.discountFromResponse(response.data);
      if (discount == null) {
        return Result.failure(
          const NetworkFailure('Could not update discount.'),
        );
      }
      return Result.success(discount);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Discount, Failure>> deleteDiscount(
    String id, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.promotionsDiscountById(id),
        cancelToken: cancelToken,
      );
      final discount = PromotionsMapper.discountFromResponse(response.data);
      if (discount == null) {
        return Result.failure(
          const NetworkFailure('Could not delete discount.'),
        );
      }
      return Result.success(discount);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<PromoCode>, Failure>> listPromoCodes({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.promotionsPromoCodes,
        cancelToken: cancelToken,
      );
      return Result.success(PromotionsMapper.promoCodesFromRoot(response.data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<PromoCode, Failure>> createPromoCode(
    PromoCodeInput input, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.promotionsPromoCodes,
        data: input.toJson(),
        cancelToken: cancelToken,
      );
      final promo = PromotionsMapper.promoCodeFromResponse(response.data);
      if (promo == null) {
        return Result.failure(
          const NetworkFailure('Could not create promo code.'),
        );
      }
      return Result.success(promo);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<PromoCode, Failure>> updatePromoCode(
    String id,
    PromoCodeInput input, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.promotionsPromoCodeById(id),
        data: input.toJson(),
        cancelToken: cancelToken,
      );
      final promo = PromotionsMapper.promoCodeFromResponse(response.data);
      if (promo == null) {
        return Result.failure(
          const NetworkFailure('Could not update promo code.'),
        );
      }
      return Result.success(promo);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<PromoCode, Failure>> deletePromoCode(
    String id, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.promotionsPromoCodeById(id),
        cancelToken: cancelToken,
      );
      final promo = PromotionsMapper.promoCodeFromResponse(response.data);
      if (promo == null) {
        return Result.failure(
          const NetworkFailure('Could not delete promo code.'),
        );
      }
      return Result.success(promo);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<PublicPromotions, Failure>> getPublicPromotions(
    String sellerId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.promotionsPublic(sellerId),
        cancelToken: cancelToken,
      );
      return Result.success(PromotionsMapper.publicFromRoot(response.data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
