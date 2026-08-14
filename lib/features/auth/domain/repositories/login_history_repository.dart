import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/login_session.dart';

abstract class LoginHistoryRepository {
  Future<Result<List<LoginSession>, Failure>> listHistory({
    CancelToken? cancelToken,
  });

  Future<Result<List<ActiveSellerDevice>, Failure>> listActiveSellerDevices({
    CancelToken? cancelToken,
  });

  Future<Result<void, Failure>> revokeSession({
    required String sessionId,
    CancelToken? cancelToken,
  });
}
