import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/api_share.dart';
import '../../domain/repositories/api_share_repository.dart';
import '../mappers/api_share_mapper.dart';

final apiShareRepositoryProvider = Provider<ApiShareRepository>(
  (ref) => ApiShareRepositoryImpl(ref.watch(dioProvider)),
);

class ApiShareRepositoryImpl implements ApiShareRepository {
  ApiShareRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<ApiShareKey, Failure>> generate({
    required String name,
    required String email,
    required List<ApiSharePermission> permissions,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.apiShareGenerate,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'permissions': permissions.map((p) => p.apiValue).toList(),
        },
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map) {
        return Result.failure(
          const NetworkFailure('Could not generate the API key.'),
        );
      }
      final key = ApiShareMapper.keyFromJson(Map<String, dynamic>.from(data));
      if (key.id.isEmpty || key.apiKey.isEmpty) {
        return Result.failure(
          const NetworkFailure('API key response was incomplete.'),
        );
      }
      return Result.success(key);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ApiShareKey>, Failure>> list({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.apiShare,
        cancelToken: cancelToken,
      );
      return Result.success(ApiShareMapper.keysFromRoot(response.data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<ApiShareKey, Failure>> updatePermissions({
    required String id,
    required List<ApiSharePermission> permissions,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.apiShareById(id),
        data: {
          'permissions': permissions.map((p) => p.apiValue).toList(),
        },
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map) {
        return Result.failure(
          const NetworkFailure('Could not update API key permissions.'),
        );
      }
      final key = ApiShareMapper.keyFromJson(Map<String, dynamic>.from(data));
      if (key.id.isEmpty) {
        return Result.failure(
          const NetworkFailure('Update response was incomplete.'),
        );
      }
      return Result.success(key);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> delete({
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.apiShareById(id),
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
  Future<Result<ApiShareData, Failure>> getData({
    required String apiKey,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.apiShareData,
        queryParameters: {'apiKey': apiKey},
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map) {
        return Result.failure(
          const NetworkFailure('Shared API data was incomplete.'),
        );
      }
      return Result.success(
        ApiShareMapper.dataFromJson(Map<String, dynamic>.from(data)),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
