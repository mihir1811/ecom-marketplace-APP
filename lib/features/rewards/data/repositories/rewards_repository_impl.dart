import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/rewards.dart';
import '../../domain/repositories/rewards_repository.dart';
import '../mappers/rewards_mapper.dart';

final rewardsRepositoryProvider = Provider<RewardsRepository>(
  (ref) => RewardsRepositoryImpl(ref.watch(dioProvider)),
);

/// Live rewards repository backed by `/rewards*` APIs.
class RewardsRepositoryImpl implements RewardsRepository {
  const RewardsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<RewardsSummary, Failure>> getSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.rewards,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not load your reward points.'),
        );
      }
      return Result.success(RewardsMapper.summaryFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<RewardTransactionsPage, Failure>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.rewardsTransactions,
        queryParameters: {'page': page, 'limit': limit},
      );
      return Result.success(
        RewardsMapper.transactionsPageFromJson(
          response.data ?? const <String, dynamic>{},
        ),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
