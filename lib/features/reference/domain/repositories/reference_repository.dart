import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/reference_models.dart';

abstract class ReferenceRepository {
  Future<Result<ReferenceProfile, Failure>> getMe({CancelToken? cancelToken});

  Future<Result<List<ReferenceRequest>, Failure>> listInbound({
    String? status,
    CancelToken? cancelToken,
  });

  Future<Result<List<ReferenceRequest>, Failure>> listOutbound({
    CancelToken? cancelToken,
  });

  Future<Result<ReferencePurchasePage, Failure>> listPurchases({
    required int page,
    int limit = 20,
    CancelToken? cancelToken,
  });

  Future<Result<ReferenceRequest, Failure>> request({
    required String emailOrCode,
    CancelToken? cancelToken,
  });

  Future<Result<ReferenceRequest, Failure>> accept({
    required String id,
    CancelToken? cancelToken,
  });

  Future<Result<ReferenceRequest, Failure>> reject({
    required String id,
    CancelToken? cancelToken,
  });
}
