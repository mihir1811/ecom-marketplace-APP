import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/diamond.dart';
import '../models/diamond_catalog_type.dart';
import '../models/diamond_filter_state.dart';
import '../models/sorting_criteria.dart';

/// Diamond catalog contract used by search/list providers.
abstract class DiamondRepository {
  /// Fetches a single page of diamonds. Never returns the full catalog.
  Future<Result<DiamondListResponse, Failure>> getDiamonds({
    required DiamondFilterState filters,
    required DiamondCatalogType catalog,
    required int page,
    int pageSize = DiamondPageSize.defaultSize,
    List<SortingCriteria> sorting = const [],
    String? sellerId,
    CancelToken? cancelToken,
  });

  /// Active natural inventory for the signed-in seller (dashboard diamond projects).
  Future<Result<DiamondListResponse, Failure>> searchSellerInventory({
    required String sellerId,
    required DiamondFilterState filters,
    required int page,
    int pageSize = 100,
    CancelToken? cancelToken,
  });

  Future<Result<Diamond, Failure>> getDiamondById({
    required String id,
    required bool isMelee,
    required bool isLabGrown,
    CancelToken? cancelToken,
  });
}

/// Page size aligned with backend search `limit` / `meta.perPage`.
/// Backend supports `page` + `limit` and returns `meta.next` for infinite scroll.
abstract final class DiamondPageSize {
  static const int defaultSize = 24;
}
