import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/response_parser.dart';
import '../../domain/models/constant_category.dart';
import '../../domain/repositories/constant_category_repository.dart';
import '../mappers/constant_category_mapper.dart';

final constantCategoryRepositoryProvider =
    Provider<ConstantCategoryRepository>(
  (ref) => ConstantCategoryRepositoryImpl(ref.watch(dioProvider)),
);

class ConstantCategoryRepositoryImpl implements ConstantCategoryRepository {
  ConstantCategoryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<ConstantCategoryListPage, Failure>> list({
    required int page,
    int limit = 10,
    String? search,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.constantCategory,
        queryParameters: {
          'page': page < 1 ? 1 : page,
          'limit': limit < 1 ? 10 : limit,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
        cancelToken: cancelToken,
      );
      return Result.success(
        ConstantCategoryMapper.listPageFromJson(
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
  Future<Result<ConstantCategoryEntry, Failure>> update({
    required String id,
    required ConstantCategoryUpdateInput input,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.constantCategoryById(id),
        data: input.toJson(),
        cancelToken: cancelToken,
      );
      final data = ResponseParser.entity(response.data);
      if (data == null) {
        return Result.failure(
          const NetworkFailure('Could not update constant category.'),
        );
      }
      return Result.success(ConstantCategoryMapper.fromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
