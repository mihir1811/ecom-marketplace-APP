import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/recently_viewed.dart';
import '../../domain/repositories/recently_viewed_repository.dart';
import '../mappers/recently_viewed_mapper.dart';

final recentlyViewedRepositoryProvider = Provider<RecentlyViewedRepository>(
  (ref) => RecentlyViewedRepositoryImpl(ref.watch(dioProvider)),
);

class RecentlyViewedRepositoryImpl implements RecentlyViewedRepository {
  RecentlyViewedRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<void, Failure>> record({
    required String productId,
    required String productType,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.recentlyViewed,
        data: {'productId': productId, 'productType': productType},
        cancelToken: cancelToken,
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<RecentlyViewedListPage, Failure>> list({
    required int page,
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.recentlyViewed,
        queryParameters: {
          'page': page < 1 ? 1 : page,
          'limit': limit < 1 ? 10 : limit,
        },
        cancelToken: cancelToken,
      );
      return Result.success(
        RecentlyViewedMapper.listPageFromJson(
          response.data,
          page: page,
          limit: limit,
        ),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<RecentlyViewedId>, Failure>> listIds({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.recentlyViewedIds,
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      final list = data is List ? data : const [];
      final ids = <RecentlyViewedId>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        ids.add(RecentlyViewedMapper.idFromJson(item));
      }
      return Result.success(ids);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<int, Failure>> clear({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.recentlyViewedClear,
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      final count = data is Map<String, dynamic>
          ? (data['count'] as num?)?.toInt() ?? 0
          : 0;
      return Result.success(count);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
