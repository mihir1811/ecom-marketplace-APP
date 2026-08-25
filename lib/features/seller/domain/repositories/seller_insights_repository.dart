import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/seller_insights.dart';

/// Seller dashboard and analytics sourced from live backend data.
abstract class SellerInsightsRepository {
  Future<Result<SellerDashboardSnapshot, Failure>> getDashboard({
    required SellerDashboardParams params,
    CancelToken? cancelToken,
  });

  Future<Result<SellerAnalyticsSnapshot, Failure>> getAnalytics({
    required AnalyticsRange range,
    CancelToken? cancelToken,
  });

  /// Drops cached orders/refunds so the next read hits the network.
  void invalidateCache();
}
