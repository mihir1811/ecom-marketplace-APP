import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/gemstone.dart';
import '../models/gemstone_filter_state.dart';

/// Page size aligned with backend search `limit` / `meta.perPage`.
abstract final class GemstonePageSize {
  static const int defaultSize = 20;
}

abstract class GemstoneRepository {
  /// Fetches a single page of gemstones. Never returns the full catalog.
  Future<Result<GemstoneListResponse, Failure>> getGemstones({
    required GemstoneFilterState filters,
    required int page,
    int pageSize = GemstonePageSize.defaultSize,
    String? sortBy,
    String? sellerId,
    CancelToken? cancelToken,
  });

  Future<Result<Gemstone, Failure>> getGemstoneById({
    required String id,
    CancelToken? cancelToken,
  });
}
