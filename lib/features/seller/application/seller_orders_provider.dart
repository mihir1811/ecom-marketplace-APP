import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/seller_order_repository_impl.dart';
import '../domain/models/seller_order.dart';
import 'seller_insights_provider.dart';

class SellerOrdersState {
  const SellerOrdersState({
    this.items = const [],
    this.total = 0,
    this.isLoading = false,
    this.isRefreshing = false,
    this.truncated = false,
    this.errorMessage,
  });

  /// Every loaded order, newest first.
  final List<SellerOrder> items;

  /// Server total (can exceed [items] when [truncated]).
  final int total;
  final bool isLoading;
  final bool isRefreshing;

  /// True when the seller has more orders than the screen loads at once.
  final bool truncated;
  final String? errorMessage;

  SellerOrdersState copyWith({
    List<SellerOrder>? items,
    int? total,
    bool? isLoading,
    bool? isRefreshing,
    bool? truncated,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SellerOrdersState(
      items: items ?? this.items,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      truncated: truncated ?? this.truncated,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// All of the seller's orders, loaded page by page once per refresh.
///
/// The Orders screen splits, sorts and filters this list locally, so
/// switching tabs or sort order never triggers another request. Realtime
/// pushes and decisions call [refresh].
class SellerOrdersNotifier extends Notifier<SellerOrdersState> {
  static const _pageSize = 50;
  static const _maxPages = 20;
  CancelToken? _cancelToken;

  @override
  SellerOrdersState build() {
    ref.watch(authProvider.select((s) => s.user?.id));
    ref.onDispose(() => _cancelToken?.cancel());
    Future.microtask(refresh);
    return const SellerOrdersState(isLoading: true);
  }

  Future<void> refresh() async {
    _cancelToken?.cancel('refresh');
    final token = _cancelToken = CancelToken();
    state = state.copyWith(
      isLoading: state.items.isEmpty,
      isRefreshing: state.items.isNotEmpty,
      clearError: true,
    );
    final repo = ref.read(sellerOrderRepositoryProvider);

    final orders = <SellerOrder>[];
    final seen = <String>{};
    SellerOrdersPage? last;
    String? error;
    for (var page = 1; page <= _maxPages; page++) {
      final result = await repo.list(
        page: page,
        limit: _pageSize,
        cancelToken: token,
      );
      if (token.isCancelled) return;
      switch (result) {
        case Success(:final value):
          last = value;
          for (final order in value.orders) {
            if (seen.add(order.id)) orders.add(order);
          }
        case ResultFailure(:final failure):
          if (failure is NetworkFailure && failure.isCancelled) return;
          error = failure.message;
      }
      if (error != null || !last!.hasMore || last.orders.isEmpty) break;
    }

    if (last == null) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: error,
      );
      return;
    }
    state = SellerOrdersState(
      items: orders,
      total: last.total,
      truncated: last.hasMore && error == null,
      errorMessage: error,
    );
  }

  /// Applies a decision locally so the order changes tab before the
  /// follow-up reload lands.
  void replace(SellerOrder order) {
    state = state.copyWith(
      items: [
        for (final existing in state.items)
          existing.id == order.id ? order : existing,
      ],
    );
  }
}

final sellerOrdersProvider =
    NotifierProvider<SellerOrdersNotifier, SellerOrdersState>(
      SellerOrdersNotifier.new,
    );

/// Count of orders awaiting a decision, for the dashboard summary (one row
/// is fetched; only `total` is used).
final sellerPendingOrdersProvider =
    FutureProvider.autoDispose<SellerOrdersPage>((ref) async {
      ref.watch(authProvider.select((s) => s.user?.id));
      final result = await ref
          .watch(sellerOrderRepositoryProvider)
          .list(page: 1, limit: 1, status: SellerOrderStatus.pending);
      return switch (result) {
        Success(:final value) => value,
        ResultFailure(:final failure) => throw failure,
      };
    });

/// One order by seller-order id. Refund and notification links carry the
/// marketplace order id instead, so a miss falls back to searching for it.
final sellerOrderDetailProvider = FutureProvider.autoDispose
    .family<SellerOrder, String>((ref, id) async {
      final repo = ref.watch(sellerOrderRepositoryProvider);
      final result = await repo.getById(id);
      switch (result) {
        case Success(:final value):
          return value;
        case ResultFailure(:final failure):
          if (failure is AuthFailure) throw failure;
          final search = await repo.list(page: 1, limit: 10, search: id);
          if (search case Success(:final value)) {
            for (final order in value.orders) {
              if (order.orderId == id || order.id == id) return order;
            }
          }
          throw failure;
      }
    });

/// Reloads every seller-order view (realtime pushes and after decisions).
void refreshSellerOrderViews(Ref ref, {String? orderId}) {
  if (ref.exists(sellerOrdersProvider)) {
    ref.read(sellerOrdersProvider.notifier).refresh();
  }
  ref.invalidate(sellerPendingOrdersProvider);
  if (orderId != null && orderId.isNotEmpty) {
    ref.invalidate(sellerOrderDetailProvider(orderId));
  }
  if (ref.exists(sellerDashboardProvider)) {
    ref.read(sellerDashboardProvider.notifier).refresh();
  }
}

/// Ids of orders with an accept / reject request in flight.
///
/// A second tap on the same order is ignored until the first one settles,
/// so a slow network cannot send two decisions.
class SellerOrderActionsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  bool isBusy(String id) => state.contains(id);

  Future<Result<SellerOrder?, Failure>> accept(SellerOrder order) {
    return _run(
      order,
      () => ref.read(sellerOrderRepositoryProvider).accept(order.id),
      optimistic: order.copyWith(
        status: SellerOrderStatus.accepted,
        rawStatus: SellerOrderStatus.accepted.apiValue,
        decidedAt: DateTime.now(),
      ),
    );
  }

  Future<Result<SellerOrder?, Failure>> reject(
    SellerOrder order, {
    required String reason,
    String? sellerNote,
  }) {
    return _run(
      order,
      () => ref
          .read(sellerOrderRepositoryProvider)
          .reject(order.id, reason: reason, sellerNote: sellerNote),
      optimistic: order.copyWith(
        status: SellerOrderStatus.rejected,
        rawStatus: SellerOrderStatus.rejected.apiValue,
        rejectionReason: reason,
        sellerNote: sellerNote,
        decidedAt: DateTime.now(),
      ),
    );
  }

  Future<Result<SellerOrder?, Failure>> _run(
    SellerOrder order,
    Future<Result<SellerOrder?, Failure>> Function() call, {
    required SellerOrder optimistic,
  }) async {
    if (state.contains(order.id)) {
      return Result.failure(
        const ValidationFailure('This order is already being updated.'),
      );
    }
    if (!order.status.canDecide) {
      return Result.failure(
        ValidationFailure(
          'This order is already ${order.status.label.toLowerCase()}.',
        ),
      );
    }
    state = {...state, order.id};
    try {
      final result = await call();
      if (result case Success(:final value)) {
        // The API is the authority; only trust its status when it sent one.
        final updated =
            value != null && value.status != SellerOrderStatus.unknown
            ? value
            : optimistic;
        if (ref.exists(sellerOrdersProvider)) {
          ref.read(sellerOrdersProvider.notifier).replace(updated);
        }
      }
      // Success or a conflict ("already processed"): reload server truth.
      refreshSellerOrderViews(ref, orderId: order.id);
      return result;
    } finally {
      state = {...state}..remove(order.id);
    }
  }
}

final sellerOrderActionsProvider =
    NotifierProvider<SellerOrderActionsNotifier, Set<String>>(
      SellerOrderActionsNotifier.new,
    );
