import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../payment/data/repositories/payment_repository_impl.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../../payment/domain/repositories/payment_repository.dart';
import '../../../refunds/data/repositories/refund_repository_impl.dart';
import '../../../refunds/domain/models/refund_request.dart';
import '../../../refunds/domain/repositories/refund_repository.dart';
import '../../domain/models/seller_insights.dart';
import '../../domain/models/seller_product.dart';
import '../../domain/repositories/seller_insights_repository.dart';
import '../../domain/repositories/seller_product_repository.dart';
import '../mappers/seller_insights_aggregator.dart';
import 'seller_product_repository_impl.dart';

/// Session-scoped orders/refunds/inventory cache for dashboard + analytics.
class SellerInsightsFetchCache {
  List<PaymentOrder>? orders;
  DateTime? ordersAt;
  Future<Result<List<PaymentOrder>, Failure>>? ordersInFlight;

  List<RefundRequest>? refunds;
  DateTime? refundsAt;
  Future<Result<List<RefundRequest>, Failure>>? refundsInFlight;

  double? inventoryValue;
  DateTime? inventoryAt;
  Future<Result<double, Failure>>? inventoryInFlight;

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
    inventoryValue = null;
    inventoryAt = null;
    inventoryInFlight = null;
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
    ref.watch(paymentRepositoryProvider),
    ref.watch(refundRepositoryProvider),
    ref.watch(sellerProductRepositoryProvider),
    ref.watch(sellerInsightsFetchCacheProvider),
    () =>
        ref.read(authProvider).sellerId ?? ref.read(authProvider).user?.id,
  ),
);

/// Loads seller orders/refunds/inventory and aggregates dashboard snapshots.
class SellerInsightsRepositoryImpl implements SellerInsightsRepository {
  const SellerInsightsRepositoryImpl(
    this._payments,
    this._refunds,
    this._products,
    this._cache,
    this._sellerId,
  );

  final PaymentRepository _payments;
  final RefundRepository _refunds;
  final SellerProductRepository _products;
  final SellerInsightsFetchCache _cache;
  final String? Function() _sellerId;

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
    final inventoryResult = await _loadInventoryValue(cancelToken: cancelToken);
    final inventory = switch (inventoryResult) {
      Success(:final value) => value,
      ResultFailure() => _cache.inventoryValue ?? 0,
    };

    return switch (ordersResult) {
      Success(:final value) => Result.success(
        SellerInsightsAggregator.dashboard(
          orders: value,
          params: params,
          inventoryValue: inventory,
        ),
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

  Future<Result<double, Failure>> _loadInventoryValue({
    CancelToken? cancelToken,
  }) {
    if (_cache.inventoryValue != null && _cache.isFresh(_cache.inventoryAt)) {
      return Future.value(Result.success(_cache.inventoryValue!));
    }
    final existing = _cache.inventoryInFlight;
    if (existing != null) return existing;

    final future = _fetchInventoryValue(cancelToken: cancelToken);
    _cache.inventoryInFlight = future;
    return future.whenComplete(() {
      if (identical(_cache.inventoryInFlight, future)) {
        _cache.inventoryInFlight = null;
      }
    });
  }

  Future<Result<double, Failure>> _fetchInventoryValue({
    CancelToken? cancelToken,
  }) async {
    final sellerId = _sellerId()?.trim() ?? '';
    if (sellerId.isEmpty) {
      _cache.inventoryValue = 0;
      _cache.inventoryAt = DateTime.now();
      return Result.success(0);
    }

    final result = await _products.listProducts(
      sellerId: sellerId,
      cancelToken: cancelToken,
    );
    switch (result) {
      case Success(value: final List<SellerProduct> products):
        var total = 0.0;
        for (final product in products) {
          if (product.isDeleted || product.isExpired || product.isSold) {
            continue;
          }
          total += _productPrice(product);
        }
        _cache.inventoryValue = total;
        _cache.inventoryAt = DateTime.now();
        return Result.success(total);
      case ResultFailure(:final failure):
        return Result.failure(failure);
    }
  }

  static double _productPrice(SellerProduct product) {
    final raw =
        product.field('total_price') ?? product.field('price_per_carat') ?? '';
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
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
