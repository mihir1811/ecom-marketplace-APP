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

final sellerInsightsRepositoryProvider = Provider<SellerInsightsRepository>(
  (ref) => SellerInsightsRepositoryImpl(
    ref.watch(paymentRepositoryProvider),
    ref.watch(refundRepositoryProvider),
  ),
);

/// Loads seller orders/refunds and aggregates dashboard + analytics snapshots.
class SellerInsightsRepositoryImpl implements SellerInsightsRepository {
  SellerInsightsRepositoryImpl(this._payments, this._refunds);

  final PaymentRepository _payments;
  final RefundRepository _refunds;

  static const _pageSize = 50;
  static const _maxPages = 6;

  @override
  Future<Result<SellerDashboardSnapshot, Failure>> getDashboard({
    required SellerDashboardParams params,
    CancelToken? cancelToken,
  }) async {
    final ordersResult = await _loadOrders(cancelToken: cancelToken);
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
    final ordersResult = await _loadOrders(cancelToken: cancelToken);
    if (ordersResult is ResultFailure<List<PaymentOrder>, Failure>) {
      return Result.failure(ordersResult.failure);
    }
    final orders =
        (ordersResult as Success<List<PaymentOrder>, Failure>).value;

    final refundsResult = await _refunds.listSeller(
      page: 1,
      limit: 100,
      cancelToken: cancelToken,
    );
    final refunds = switch (refundsResult) {
      Success(:final value) => value.items,
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

  Future<Result<List<PaymentOrder>, Failure>> _loadOrders({
    CancelToken? cancelToken,
  }) async {
    final all = <PaymentOrder>[];
    var page = 1;
    while (page <= _maxPages) {
      if (cancelToken?.isCancelled == true) {
        return Result.failure(NetworkFailure.cancelled);
      }
      final result = await _payments.listOrders(
        page: page,
        limit: _pageSize,
        cancelToken: cancelToken,
      );
      switch (result) {
        case ResultFailure(:final failure):
          return Result.failure(failure);
        case Success(:final value):
          all.addAll(value.orders);
          if (!value.hasMore) {
            return Result.success(all);
          }
          page += 1;
      }
    }
    return Result.success(all);
  }
}
