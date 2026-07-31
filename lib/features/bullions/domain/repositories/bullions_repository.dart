import 'package:dio/dio.dart';

import '../models/billion.dart';
import '../models/bullions_filter_state.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';

/// Page size aligned with backend `limit` query param.
abstract final class BullionPageSize {
  static const int defaultSize = 20;
}

/// Contract for fetching bullion listings via `GET /bullion/all`.
abstract class BullionsRepository {
  /// Fetches a single page. Never loads the full catalog at once.
  Future<Result<BullionsCatalogResponse, Failure>> searchBullions({
    required BullionsFilterState filters,
    required int page,
    int pageSize = BullionPageSize.defaultSize,
    CancelToken? cancelToken,
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
