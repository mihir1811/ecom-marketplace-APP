import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/product_share.dart';
import '../../domain/repositories/product_share_repository.dart';
import '../mappers/product_share_mapper.dart';

final productShareRepositoryProvider = Provider<ProductShareRepository>(
  (ref) => ProductShareRepositoryImpl(ref.watch(dioProvider)),
);

class ProductShareRepositoryImpl implements ProductShareRepository {
  ProductShareRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<ProductShareLink, Failure>> create({
    required String productType,
    required String productId,
    required ProductShareChannel channel,
    bool includePrice = false,
    bool includeImages = true,
    bool includeVideos = true,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.productShare,
        data: {
          'productType': productType,
          'productId': productId,
          'channel': channel.apiValue,
          'includePrice': includePrice,
          'includeImages': includeImages,
          'includeVideos': includeVideos,
        },
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not create the share link.'),
        );
      }
      final link = ProductShareMapper.linkFromJson(data);
      if (link.id.isEmpty || link.token.isEmpty) {
        return Result.failure(
          const NetworkFailure('Share link response was incomplete.'),
        );
      }
      return Result.success(link);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<ProductShareEmailResult, Failure>> sendEmail({
    required String shareId,
    required String email,
    String? name,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.productShareEmail(shareId),
        data: {
          'email': email.trim(),
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        },
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not send the share email.'),
        );
      }
      return Result.success(ProductShareMapper.emailFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<SharedProductPayload, Failure>> getByToken({
    required String token,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.productShareByToken(token),
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Share link not found.'),
        );
      }
      return Result.success(ProductShareMapper.sharedFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
