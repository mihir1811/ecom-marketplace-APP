import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/jewelry.dart';
import '../models/jewelry_filter_state.dart';

/// Page size aligned with backend `limit` / `meta.perPage`.
abstract final class JewelryPageSize {
  static const int defaultSize = 20;
}

abstract class JewelryRepository {
  /// Fetches a single page via `GET /jewellery?page=&limit=`. Never loads the full catalog.
  Future<Result<JewelryListResponse, Failure>> getJewelry({
    required JewelryFilterState filters,
    required int page,
    int pageSize = JewelryPageSize.defaultSize,
    JewelrySortOption sort = JewelrySortOption.featured,
    CancelToken? cancelToken,
  });
}
