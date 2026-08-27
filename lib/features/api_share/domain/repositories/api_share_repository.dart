import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/api_share.dart';

abstract class ApiShareRepository {
  Future<Result<ApiShareKey, Failure>> generate({
    required String name,
    required String email,
    required List<ApiSharePermission> permissions,
    CancelToken? cancelToken,
  });

  Future<Result<List<ApiShareKey>, Failure>> list({
    CancelToken? cancelToken,
  });

  Future<Result<ApiShareKey, Failure>> updatePermissions({
    required String id,
    required List<ApiSharePermission> permissions,
    CancelToken? cancelToken,
  });

  Future<Result<void, Failure>> delete({
    required String id,
    CancelToken? cancelToken,
  });

  Future<Result<ApiShareData, Failure>> getData({
    required String apiKey,
    CancelToken? cancelToken,
  });
}
