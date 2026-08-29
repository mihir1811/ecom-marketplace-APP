import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../payment/data/repositories/payment_repository_impl.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../../payment/domain/repositories/payment_repository.dart';
import '../../../refunds/data/repositories/refund_repository_impl.dart';
import '../../../refunds/domain/models/refund_request.dart';
import '../../../refunds/domain/repositories/refund_repository.dart';
import '../../domain/models/seller_insights.dart';
import '../../domain/repositories/seller_insights_repository.dart';
import '../mappers/seller_insights_aggregator.dart';

/// Session-scoped orders/refunds cache so dashboard + analytics share one fetch.
class SellerInsightsFetchCache {
  List<PaymentOrder>? orders;
  DateTime? ordersAt;
  Future<Result<List<PaymentOrder>, Failure>>? ordersInFlight;

  List<RefundRequest>? refunds;
  DateTime? refundsAt;
  Future<Result<List<RefundRequest>, Failure>>? refundsInFlight;

  static const ttl = Duration(minutes: 5);

  bool isFresh(DateTime? at) =>
      at != null && DateTime.now().difference(at) < ttl;

  void clear() {
    orders = null;
    ordersAt = null;
    ordersInFlight = null;
    refunds = null;
    refundsAt = null;
    refundsInFlight = null;
  }
}

final sellerInsightsFetchCacheProvider = Provider<SellerInsightsFetchCache>(
  (ref) => SellerInsightsFetchCache(),
);

final sellerInsightsRepositoryProvider = Provider<SellerInsightsRepository>(
  (ref) => SellerInsightsRepositoryImpl(
    ref.watch(paymentRepositoryProvider),
    ref.watch(refundRepositoryProvider),
    ref.watch(sellerInsightsFetchCacheProvider),
  ),
);

/// Loads seller orders/refunds and aggregates dashboard + analytics snapshots.
class SellerInsightsRepositoryImpl implements SellerInsightsRepository {
  const SellerInsightsRepositoryImpl(
    this._payments,
    this._refunds,
    this._cache,
  );

  final PaymentRepository _payments;
  final RefundRepository _refunds;
  final SellerInsightsFetchCache _cache;

  static const _pageSize = 50;
  static const _maxPages = 6;

  @override
  void invalidateCache() => _cache.clear();

  @override
  Future<Result<SellerDashboardSnapshot, Failure>> getDashboard({
    required SellerDashboardParams params,
    CancelToken? cancelToken,
  }) async {
    final ordersResult = await _loadOrders();
    return switch (ordersResult) {
      Success(:final value) => Result.success(
        SellerInsightsAggregator.dashboard(orders: value, params: params),
      ),
      ResultFailure(:final failure) => Result.failure(failure),
    };
  }

  @override
  Future<Result<SellerAnalyticsSnapshot, Failure>> getAnalytics({
    required AnalyticsRange range,
    CancelToken? cancelToken,
  }) async {
    final ordersResult = await _loadOrders();
    if (ordersResult is ResultFailure<List<PaymentOrder>, Failure>) {
      return Result.failure(ordersResult.failure);
    }
    final orders = (ordersResult as Success<List<PaymentOrder>, Failure>).value;

    final refundsResult = await _loadRefunds();
    final refunds = switch (refundsResult) {
      Success(:final value) => value,
      ResultFailure() => const <RefundRequest>[],
    };

    return Result.success(
      SellerInsightsAggregator.analytics(
        orders: orders,
        refunds: refunds,
        range: range,
      ),
    );
  }

  Future<Result<List<PaymentOrder>, Failure>> _loadOrders() {
    if (_cache.orders != null && _cache.isFresh(_cache.ordersAt)) {
      return Future.value(Result.success(_cache.orders!));
    }
    final existing = _cache.ordersInFlight;
    if (existing != null) return existing;

    final future = _fetchAllOrders();
    _cache.ordersInFlight = future;
    return future.whenComplete(() {
      if (identical(_cache.ordersInFlight, future)) {
        _cache.ordersInFlight = null;
      }
    });
  }

  Future<Result<List<PaymentOrder>, Failure>> _fetchAllOrders() async {
    final all = <PaymentOrder>[];
    var page = 1;
    while (page <= _maxPages) {
      final result = await _payments.listOrders(page: page, limit: _pageSize);
      switch (result) {
        case ResultFailure(:final failure):
          return Result.failure(failure);
        case Success(:final value):
          all.addAll(value.orders);
          if (!value.hasMore) {
            _cache.orders = all;
            _cache.ordersAt = DateTime.now();
            return Result.success(all);
          }
          page += 1;
      }
    }
    _cache.orders = all;
    _cache.ordersAt = DateTime.now();
    return Result.success(all);
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
