import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/seller_review.dart';
import '../../domain/repositories/seller_review_repository.dart';
import '../mappers/seller_review_mapper.dart';

final sellerReviewRepositoryProvider = Provider<SellerReviewRepository>(
  (ref) => SellerReviewRepositoryImpl(ref.watch(dioProvider)),
);

class SellerReviewRepositoryImpl implements SellerReviewRepository {
  const SellerReviewRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<SellerReviewsPage, Failure>> listReviews({
    String? orderId,
    String? sellerId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.sellerReviews,
        queryParameters: {
          if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
          if (sellerId != null && sellerId.isNotEmpty) 'sellerId': sellerId,
          'page': page,
          'limit': limit,
        },
      );
      final root = response.data ?? const <String, dynamic>{};
      return Result.success(SellerReviewMapper.pageFromResponse(root));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<SellerReview, Failure>> submitReview(
    SubmitSellerReviewInput input,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.sellerReviews,
        data: {
          'sellerId': input.sellerId,
          'orderId': input.orderId,
          'rating': input.rating,
          if (input.title != null && input.title!.trim().isNotEmpty)
            'title': input.title!.trim(),
          if (input.comment != null && input.comment!.trim().isNotEmpty)
            'comment': input.comment!.trim(),
        },
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not submit the review.'),
        );
      }
      return Result.success(SellerReviewMapper.fromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
