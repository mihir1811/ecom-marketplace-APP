import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/reference_models.dart';
import '../../domain/repositories/reference_repository.dart';
import '../mappers/reference_mapper.dart';

final referenceRepositoryProvider = Provider<ReferenceRepository>(
  (ref) => ReferenceRepositoryImpl(ref.watch(dioProvider)),
);

class ReferenceRepositoryImpl implements ReferenceRepository {
  const ReferenceRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<ReferenceProfile, Failure>> getMe({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.referenceMe,
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not load reference profile.'),
        );
      }
      return Result.success(ReferenceMapper.profileFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ReferenceRequest>, Failure>> listInbound({
    String? status,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.referenceInbound,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
        },
        cancelToken: cancelToken,
      );
      return Result.success(
        ReferenceMapper.requestListFromJson(response.data?['data']),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ReferenceRequest>, Failure>> listOutbound({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.referenceOutbound,
        cancelToken: cancelToken,
      );
      return Result.success(
        ReferenceMapper.requestListFromJson(response.data?['data']),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<ReferencePurchasePage, Failure>> listPurchases({
    required int page,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.referencePurchases,
        queryParameters: {
          'page': page < 1 ? 1 : page,
          'limit': limit < 1 ? 20 : limit,
        },
        cancelToken: cancelToken,
      );
      return Result.success(
        ReferenceMapper.purchasesFromJson(
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
  Future<Result<ReferenceRequest, Failure>> request({
    required String emailOrCode,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.referenceRequest,
        data: {'emailOrCode': emailOrCode.trim()},
        cancelToken: cancelToken,
      );
      return _parseRequest(response.data, 'Could not send reference request.');
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<ReferenceRequest, Failure>> accept({
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.referenceAccept(id),
        cancelToken: cancelToken,
      );
      return _parseRequest(response.data, 'Could not accept the request.');
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<ReferenceRequest, Failure>> reject({
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.referenceReject(id),
        cancelToken: cancelToken,
      );
      return _parseRequest(response.data, 'Could not reject the request.');
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Result<ReferenceRequest, Failure> _parseRequest(
    Map<String, dynamic>? root,
    String fallback,
  ) {
    final data = root?['data'];
    if (data is! Map<String, dynamic>) {
      return Result.failure(NetworkFailure(fallback));
    }
    final request = ReferenceMapper.requestFromJson(data);
    if (request.id.isEmpty) {
      return Result.failure(NetworkFailure(fallback));
    }
    return Result.success(request);
  }
}
