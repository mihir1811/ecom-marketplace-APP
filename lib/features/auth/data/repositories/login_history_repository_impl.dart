import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/login_session.dart';
import '../../domain/repositories/login_history_repository.dart';
import '../mappers/login_history_mapper.dart';

final loginHistoryRepositoryProvider = Provider<LoginHistoryRepository>(
  (ref) => LoginHistoryRepositoryImpl(ref.watch(dioProvider)),
);

class LoginHistoryRepositoryImpl implements LoginHistoryRepository {
  LoginHistoryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<LoginSession>, Failure>> listHistory({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.loginHistory,
        cancelToken: cancelToken,
      );
      return Result.success(
        LoginHistoryMapper.sessionsFromRoot(response.data),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ActiveSellerDevice>, Failure>> listActiveSellerDevices({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.loginHistoryActiveSeller,
        cancelToken: cancelToken,
      );
      return Result.success(
        LoginHistoryMapper.devicesFromRoot(response.data),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> revokeSession({
    required String sessionId,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.loginHistoryBySession(sessionId),
        cancelToken: cancelToken,
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
