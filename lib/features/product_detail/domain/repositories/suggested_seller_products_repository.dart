import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/pagination/paginated_async_notifier.dart';
import '../models/product_detail.dart';

/// Page size for same-seller suggestions (≈4 viewport widths of 3 cards).
abstract final class SuggestedSellerProductsPageSize {
  static const int defaultSize = 12;
}

/// Loads more listings from the same seller as the open product detail.
abstract class SuggestedSellerProductsRepository {
  Future<Result<PaginatedPage<ProductDetail>, Failure>> getPage({
    required ProductSegment segment,
    required String excludeProductId,
    String? sellerId,
    String? companyName,
    required int page,
    int pageSize = SuggestedSellerProductsPageSize.defaultSize,
    CancelToken? cancelToken,
  });
}
