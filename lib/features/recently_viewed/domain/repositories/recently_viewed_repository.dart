import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/recently_viewed.dart';

abstract class RecentlyViewedRepository {
  Future<Result<void, Failure>> record({
    required String productId,
    required String productType,
    CancelToken? cancelToken,
  });

  Future<Result<RecentlyViewedListPage, Failure>> list({
    required int page,
    int limit = 10,
    CancelToken? cancelToken,
  });

  Future<Result<List<RecentlyViewedId>, Failure>> listIds({
    CancelToken? cancelToken,
  });

  Future<Result<int, Failure>> clear({CancelToken? cancelToken});
}
