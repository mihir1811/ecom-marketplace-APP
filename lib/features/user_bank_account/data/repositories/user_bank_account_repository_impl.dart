import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/response_parser.dart';
import '../../domain/models/user_bank_account.dart';
import '../../domain/repositories/user_bank_account_repository.dart';
import '../mappers/user_bank_account_mapper.dart';

final userBankAccountRepositoryProvider = Provider<UserBankAccountRepository>(
  (ref) => UserBankAccountRepositoryImpl(ref.watch(dioProvider)),
);

class UserBankAccountRepositoryImpl implements UserBankAccountRepository {
  UserBankAccountRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<UserBankAccountStatus, Failure>> getStatus({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.userBankAccountStatus,
        cancelToken: cancelToken,
      );
      return Result.success(
        UserBankAccountMapper.statusFromJson(response.data),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserBankAccount, Failure>> getAccount({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.userBankAccount,
        cancelToken: cancelToken,
      );
      final data = ResponseParser.entity(response.data);
      if (data == null) {
        return Result.failure(const NetworkFailure('Bank account not found.'));
      }
      return Result.success(UserBankAccountMapper.fromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserBankAccount, Failure>> upsert(
    UserBankAccountInput input, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.userBankAccount,
        data: input.toJson(),
        cancelToken: cancelToken,
      );
      final data = ResponseParser.entity(response.data);
      if (data == null) {
        return Result.failure(
          const NetworkFailure('Could not save bank account.'),
        );
      }
      return Result.success(UserBankAccountMapper.fromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> delete({CancelToken? cancelToken}) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.userBankAccount,
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
