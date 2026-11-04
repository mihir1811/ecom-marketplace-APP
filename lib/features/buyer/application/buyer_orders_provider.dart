import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/result.dart';
import '../../payment/data/repositories/payment_repository_impl.dart';
import '../../payment/domain/models/payment_models.dart';
import '../domain/models/buyer_order.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

BuyerOrder buyerOrderFromPayment(PaymentOrder order) {
  return BuyerOrder(
    id: order.id,
    productLabel: order.primaryProductLabel,
    sellerName: order.primarySellerName,
    status: order.status,
    amountInr: order.isLiveAuction
        ? order.amount
        : order.pricing?.totalInr ?? order.amount,
    amountUsd: order.amountUsd,
    currency: order.currency,
    createdAt: order.createdAt,
    itemCount: order.items.length,
    sellerDecision: combinedSellerDecision(order.sellerDecisions),
    imageUrl: order.items
        .map((e) => e.image?.trim())
        .firstWhere((e) => e != null && e.isNotEmpty, orElse: () => null),
    liveShowTitle: order.isLiveAuction
        ? (order.liveAuction?.showTitle ?? 'Live show')
        : null,
  );
}

/// `REJECTED` only when every seller rejected; `PENDING` while any seller
/// still has to decide; otherwise `ACCEPTED`.
String? combinedSellerDecision(List<PaymentOrderSellerDecision> decisions) {
  if (decisions.isEmpty) return null;
  if (decisions.every((d) => d.isRejected)) {
    return SellerDecisionStatuses.rejected;
  }
  if (decisions.any((d) => d.isPending)) return SellerDecisionStatuses.pending;
  return SellerDecisionStatuses.accepted;
}

class BuyerOrdersListState {
  const BuyerOrdersListState({
    this.orders = const [],
    this.page = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<BuyerOrder> orders;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  BuyerOrdersListState copyWith({
    List<BuyerOrder>? orders,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BuyerOrdersListState(
      orders: orders ?? this.orders,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BuyerOrdersNotifier extends Notifier<BuyerOrdersListState>
    with DisposeTolerantNotifier<BuyerOrdersListState> {
  static const _pageSize = 20;

  @override
  BuyerOrdersListState build() {
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId == null || userId.isEmpty) {
      return const BuyerOrdersListState();
    }
    Future.microtask(loadInitial);
    return const BuyerOrdersListState(isLoading: true);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await ref
        .read(paymentRepositoryProvider)
        .listOrders(page: 1, limit: _pageSize);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = BuyerOrdersListState(
          orders: value.orders.map(buyerOrderFromPayment).toList(),
          page: value.page,
          hasMore: value.hasMore,
        );
      case ResultFailure(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.page + 1;
    final result = await ref
        .read(paymentRepositoryProvider)
        .listOrders(page: nextPage, limit: _pageSize);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = state.copyWith(
          orders: [...state.orders, ...value.orders.map(buyerOrderFromPayment)],
          page: value.page,
          hasMore: value.hasMore,
          isLoadingMore: false,
        );
      case ResultFailure(:final failure):
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        );
    }
  }
}

final buyerOrdersProvider =
    NotifierProvider<BuyerOrdersNotifier, BuyerOrdersListState>(
      BuyerOrdersNotifier.new,
    );

final buyerOrderDetailProvider = FutureProvider.autoDispose
    .family<PaymentOrder, String>((ref, orderId) async {
      final result = await ref
          .watch(paymentRepositoryProvider)
          .getOrder(orderId);
      final order = switch (result) {
        Success(:final value) => value,
        ResultFailure(:final failure) => throw failure,
      };
      // A live-auction invoice is generated a few seconds after the win;
      // fetch again a few times until it appears.
      final tries = _invoiceRetries[orderId] ?? 0;
      if (order.isLiveAuction &&
          (order.invoiceUrl?.trim().isEmpty ?? true) &&
          tries < 5) {
        _invoiceRetries[orderId] = tries + 1;
        final timer = Timer(const Duration(seconds: 4), ref.invalidateSelf);
        ref.onDispose(timer.cancel);
      } else {
        _invoiceRetries.remove(orderId);
      }
      return order;
    });

final _invoiceRetries = <String, int>{};
