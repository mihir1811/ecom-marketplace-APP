import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/home_search_result.dart';

/// Page size for each catalog in the global-search fan-out.
abstract final class HomeSearchPageSize {
  static const int defaultSize = 20;
}

/// One page of merged cross-catalog search hits.
class HomeSearchPage {
  const HomeSearchPage({
    required this.items,
    required this.hasMore,
    required this.totalCount,
    required this.page,
    this.isApproximate = false,
    this.notice,
    this.correctedQuery,
  });

  final List<HomeSearchResult> items;
  final bool hasMore;
  final int totalCount;
  final int page;

  /// True when exact search had no hits and nearest/similar items are shown.
  final bool isApproximate;

  /// Friendly banner copy for spelling or similar-results cases.
  final String? notice;

  /// Corrected spelling used for the request (when different from raw input).
  final String? correctedQuery;
}

/// Cross-catalog search used by the sticky home search bar.
abstract class HomeSearchRepository {
  /// Fetches one fan-out page (`page` + `limit` on each catalog API). Never throws.
  ///
  /// When [forceSimilar] is true, skips the exact match path and loads nearest
  /// / similar items (used for infinite scroll after an approximate first page).
  Future<Result<HomeSearchPage, Failure>> search(
    String query, {
    required int page,
    int pageSize = HomeSearchPageSize.defaultSize,
    bool forceSimilar = false,
    CancelToken? cancelToken,
  });
}
