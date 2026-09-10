import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/watch.dart';
import '../models/watch_filter_state.dart';

/// Page size aligned with backend `limit` query param.
abstract final class WatchPageSize {
  static const int defaultSize = 20;
}

abstract class WatchRepository {
  /// Fetches a single page via `GET /watch/all?page=&limit=`. Never loads the full catalog.
  Future<Result<WatchListResponse, Failure>> getWatches({
    required WatchFilterState filters,
    required int page,
    int pageSize = WatchPageSize.defaultSize,
    WatchSortOption sort = WatchSortOption.featured,
    String? sellerId,
    CancelToken? cancelToken,
  });
}
