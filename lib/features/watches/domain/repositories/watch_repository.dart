import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/watch.dart';
import '../models/watch_filter_state.dart';

abstract class WatchRepository {
  Future<Result<WatchListResponse, Failure>> getWatches({
    required WatchFilterState filters,
    required int page,
    int pageSize = 20,
    WatchSortOption sort = WatchSortOption.featured,
  });
}
