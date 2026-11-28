import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/rough_facets.dart';
import '../models/rough_filter_state.dart';
import '../models/rough_parcel.dart';
import '../models/rough_sort_option.dart';

/// Page size the website scrolls with (`limit`, 1–200).
abstract final class RoughPageSize {
  static const int defaultSize = 24;
}

/// One page of POST /rough-diamond/search.
class RoughSearchPage {
  const RoughSearchPage({
    required this.parcels,
    required this.totalCount,
    required this.hasMore,
  });

  final List<RoughParcel> parcels;
  final int totalCount;
  final bool hasMore;
}

/// Public rough catalogue: search, filter facets and one parcel.
abstract class RoughDiamondRepository {
  /// [allTypes] searches natural and lab rough together (a seller's shop).
  Future<Result<RoughSearchPage, Failure>> search({
    required RoughFilterState filters,
    required int page,
    int pageSize = RoughPageSize.defaultSize,
    RoughSortOption sort = RoughSortOption.newest,
    String? sellerId,
    bool allTypes = false,
    CancelToken? cancelToken,
  });

  /// Only these parcels (compare, wishlist refresh), any type.
  Future<Result<List<RoughParcel>, Failure>> byIds(List<String> ids);

  Future<Result<RoughFacets, Failure>> facets(RoughDiamondType type);

  /// Sold and expired parcels come back too; only deleted ones are 404
  /// ([NotFoundFailure]).
  Future<Result<RoughParcel, Failure>> getById(String id);
}
