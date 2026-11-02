import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../refunds/data/repositories/refund_repository_impl.dart';
import '../../../refunds/domain/models/refund_request.dart';
import '../../../refunds/domain/repositories/refund_repository.dart';
import '../../domain/models/seller_insights.dart';
import '../../domain/models/seller_stats.dart';
import '../../domain/repositories/seller_insights_repository.dart';
import '../mappers/seller_insights_aggregator.dart';
import '../mappers/seller_stats_mapper.dart';

/// Session-scoped stats/refunds cache for dashboard + analytics.
class SellerInsightsFetchCache {
  final stats = <SellerStatsQuery, (DateTime, SellerStats)>{};
  final statsInFlight =
      <SellerStatsQuery, Future<Result<SellerStats, Failure>>>{};

  List<RefundRequest>? refunds;
  DateTime? refundsAt;
  Future<Result<List<RefundRequest>, Failure>>? refundsInFlight;

  static const ttl = Duration(minutes: 5);

  bool isFresh(DateTime? at) =>
      at != null && DateTime.now().difference(at) < ttl;

  void clear() {
    stats.clear();
    statsInFlight.clear();
    refunds = null;
    refundsAt = null;
    refundsInFlight = null;
  }
}

final sellerInsightsFetchCacheProvider = Provider<SellerInsightsFetchCache>((
  ref,
) {
  ref.watch(authProvider.select((s) => s.user?.id));
  final cache = SellerInsightsFetchCache();
  ref.onDispose(cache.clear);
  return cache;
});

final sellerInsightsRepositoryProvider = Provider<SellerInsightsRepository>(
  (ref) => SellerInsightsRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(refundRepositoryProvider),
    ref.watch(sellerInsightsFetchCacheProvider),
  ),
);

/// Loads seller-scoped stats (`GET /seller/stats`) and refunds.
///
/// `GET /payment/orders` is deliberately not used here: it lists the signed-in
/// user's own purchases, not the orders other buyers placed with this seller.
class SellerInsightsRepositoryImpl implements SellerInsightsRepository {
  const SellerInsightsRepositoryImpl(this._dio, this._refunds, this._cache);

  final Dio _dio;
  final RefundRepository _refunds;
  final SellerInsightsFetchCache _cache;

  @override
  void invalidateCache() => _cache.clear();

  @override
  Future<Result<SellerDashboardSnapshot, Failure>> getDashboard({
    required SellerDashboardParams params,
    CancelToken? cancelToken,
  }) async {
    final plan = SellerInsightsAggregator.dashboardPlan(params);
    final result = await _loadStats(plan.query, cancelToken: cancelToken);
    switch (result) {
      case Success(:final value):
        final mismatch = SellerInsightsAggregator.periodMismatch(
          value,
          plan.query,
        );
        if (mismatch != null) {
          _cache.stats.remove(plan.query);
          return Result.failure(NetworkFailure(mismatch));
        }
        return Result.success(
          SellerInsightsAggregator.dashboard(
            stats: value,
            plan: plan,
            params: params,
          ),
        );
      case ResultFailure(:final failure):
        return Result.failure(failure);
    }
  }

  @override
  Future<Result<SellerAnalyticsSnapshot, Failure>> getAnalytics({
    required AnalyticsRange range,
    DateTime? from,
    DateTime? to,
    CancelToken? cancelToken,
  }) async {
    final queries = SellerInsightsAggregator.analyticsQueries(
      range,
      from: from,
      to: to,
    );
    final results = await Future.wait([
      _loadStats(queries.current, cancelToken: cancelToken),
      _loadStats(queries.previous, cancelToken: cancelToken),
    ]);
    final current = results[0];
    if (current is ResultFailure<SellerStats, Failure>) {
      return Result.failure(current.failure);
    }
    final currentStats = (current as Success<SellerStats, Failure>).value;
    final mismatch = SellerInsightsAggregator.periodMismatch(
      currentStats,
      queries.current,
    );
    if (mismatch != null) {
      _cache.stats.remove(queries.current);
      return Result.failure(NetworkFailure(mismatch));
    }
    // A failed comparison window only affects the deltas.
    final previous = switch (results[1]) {
      Success(:final value) => value,
      ResultFailure() => const SellerStats(),
    };

    final refunds = switch (await _loadRefunds()) {
      Success(:final value) => value,
      ResultFailure() => const <RefundRequest>[],
    };

    return Result.success(
      SellerInsightsAggregator.analytics(
        current: currentStats,
        previous: previous,
        currentQuery: queries.current,
        refunds: refunds,
      ),
    );
  }

  Future<Result<SellerStats, Failure>> _loadStats(
    SellerStatsQuery query, {
    CancelToken? cancelToken,
  }) {
    final cached = _cache.stats[query];
    if (cached != null && _cache.isFresh(cached.$1)) {
      return Future.value(Result.success(cached.$2));
    }
    final existing = _cache.statsInFlight[query];
    if (existing != null) return existing;

    final future = _fetchStats(query, cancelToken: cancelToken);
    _cache.statsInFlight[query] = future;
    return future.whenComplete(() {
      if (identical(_cache.statsInFlight[query], future)) {
        _cache.statsInFlight.remove(query);
      }
    });
  }

  Future<Result<SellerStats, Failure>> _fetchStats(
    SellerStatsQuery query, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.sellerStats,
        queryParameters: query.toQueryParameters(),
        cancelToken: cancelToken,
      );
      final stats = SellerStatsMapper.fromEnvelope(response.data);
      _cache.stats[query] = (DateTime.now(), stats);
      return Result.success(stats);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Future<Result<List<RefundRequest>, Failure>> _loadRefunds() {
    if (_cache.refunds != null && _cache.isFresh(_cache.refundsAt)) {
      return Future.value(Result.success(_cache.refunds!));
    }
    final existing = _cache.refundsInFlight;
    if (existing != null) return existing;

    final future = _fetchRefunds();
    _cache.refundsInFlight = future;
    return future.whenComplete(() {
      if (identical(_cache.refundsInFlight, future)) {
        _cache.refundsInFlight = null;
      }
    });
  }

  Future<Result<List<RefundRequest>, Failure>> _fetchRefunds() async {
    final result = await _refunds.listSeller(page: 1, limit: 100);
    switch (result) {
      case Success(:final value):
        _cache.refunds = value.items;
        _cache.refundsAt = DateTime.now();
        return Result.success(value.items);
      case ResultFailure(:final failure):
        return Result.failure(failure);
    }
  }
}
