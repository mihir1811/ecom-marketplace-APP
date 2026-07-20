import '../models/billion.dart';
import '../models/bullions_filter_state.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';

/// Contract for fetching Bullions listings (mocked in this module).
abstract class BullionsRepository {
  Future<Result<BullionsCatalogResponse, Failure>> searchBullions({
    required BullionsFilterState filters,
    required int page,
    int pageSize,
  });
}

/// Paginated catalog response returned by the repository.
class BullionsCatalogResponse {
  const BullionsCatalogResponse({
    required this.bullions,
    required this.totalCount,
    required this.hasMore,
    required this.page,
  });

  final List<Bullion> bullions;
  final int totalCount;
  final bool hasMore;
  final int page;
}

