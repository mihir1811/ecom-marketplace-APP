import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/fee_rule.dart';
import '../../domain/repositories/fees_repository.dart';
import '../mappers/fee_rule_mapper.dart';

final feesRepositoryProvider = Provider<FeesRepository>(
  (ref) => FeesRepositoryImpl(ref.watch(dioProvider)),
);

class FeesRepositoryImpl implements FeesRepository {
  FeesRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<FeeRulesCatalog, Failure>> listActive({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.fees,
        cancelToken: cancelToken,
      );
      return Result.success(FeeRuleMapper.catalogFromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
