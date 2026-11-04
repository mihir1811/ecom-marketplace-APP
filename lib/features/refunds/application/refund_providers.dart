import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/refund_repository_impl.dart';
import '../domain/models/refund_list_page.dart';
import '../domain/models/refund_request.dart';
import '../domain/repositories/refund_repository.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

class RefundListState {
  const RefundListState({
    this.items = const [],
    this.total = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<RefundRequest> items;
  final int total;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  RefundListState copyWith({
    List<RefundRequest>? items,
    int? total,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RefundListState(
      items: items ?? this.items,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

abstract class _RefundListNotifier extends Notifier<RefundListState>
    with DisposeTolerantNotifier<RefundListState> {
  CancelToken? _cancelToken;

  RefundRepository get _repo => ref.read(refundRepositoryProvider);

  Future<Result<RefundListPage, Failure>> fetchPage({
    required int page,
    CancelToken? cancelToken,
  });

  /// When true, [refresh] follows every page (up to [maxPages]) so screens
  /// can count, sort and filter the whole set without further requests.
  bool get loadsAllPages => false;

  static const maxPages = 20;

  @override
  RefundListState build() {
    ref.watch(authProvider.select((s) => s.user?.id));
    ref.onDispose(() => _cancelToken?.cancel());
    Future.microtask(refresh);
    return const RefundListState(isLoading: true);
  }

  Future<void> refresh() async {
    _cancelToken?.cancel('refresh');
    final token = _cancelToken = CancelToken();
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await fetchPage(page: 1, cancelToken: token);
    switch (result) {
      case Success(value: var page):
        final items = [...page.items];
        String? partialError;
        while (loadsAllPages && page.hasMore && page.currentPage < maxPages) {
          final next = await fetchPage(
            page: page.currentPage + 1,
            cancelToken: token,
          );
          if (token.isCancelled) return;
          if (next case Success(:final value)) {
            final known = items.map((r) => r.id).toSet();
            items.addAll(value.items.where((r) => !known.contains(r.id)));
            page = value;
          } else if (next case ResultFailure(:final failure)) {
            partialError = failure.message;
            break;
          }
        }
        state = RefundListState(
          items: items,
          total: page.total,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
          errorMessage: partialError,
        );
      case ResultFailure(failure: final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  /// Applies a server-confirmed update in place, so the refund moves to its
  /// new tab before the follow-up reload lands.
  void replace(RefundRequest refund) {
    state = state.copyWith(
      items: [
        for (final r in state.items)
          r.id == refund.id ? refund.withPartiesFrom(r) : r,
      ],
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.currentPage + 1;
    final result = await fetchPage(page: nextPage);
    switch (result) {
      case Success(value: final page):
        state = state.copyWith(
          items: [...state.items, ...page.items],
          total: page.total,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
          isLoadingMore: false,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        );
    }
  }
}

class BuyerRefundListNotifier extends _RefundListNotifier {
  @override
  Future<Result<RefundListPage, Failure>> fetchPage({
    required int page,
    CancelToken? cancelToken,
  }) {
    return _repo.listMine(page: page, cancelToken: cancelToken);
  }
}

/// Every refund request for the seller's orders (the Orders screen splits
/// them into Requests / Approved / Rejected locally).
class SellerRefundListNotifier extends _RefundListNotifier {
  @override
  bool get loadsAllPages => true;

  @override
  Future<Result<RefundListPage, Failure>> fetchPage({
    required int page,
    CancelToken? cancelToken,
  }) {
    return _repo.listSeller(page: page, limit: 50, cancelToken: cancelToken);
  }
}

final buyerRefundListProvider =
    NotifierProvider<BuyerRefundListNotifier, RefundListState>(
      BuyerRefundListNotifier.new,
    );

final sellerRefundListProvider =
    NotifierProvider<SellerRefundListNotifier, RefundListState>(
      SellerRefundListNotifier.new,
    );

/// The buyer's refund requests for one order (every seller on it).
final orderRefundsProvider = FutureProvider.autoDispose
    .family<List<RefundRequest>, String>((ref, orderId) async {
      final result = await ref
          .watch(refundRepositoryProvider)
          .listMine(page: 1, limit: 50, orderId: orderId);
      return switch (result) {
        // Filter client-side too in case the server ignored `orderId`.
        Success(value: final page) =>
          page.items.where((r) => r.orderId == orderId).toList(),
        ResultFailure(failure: final failure) => throw failure,
      };
    });

class RefundMutationNotifier extends Notifier<AsyncValue<void>>
    with DisposeTolerantNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  RefundRepository get _repo => ref.read(refundRepositoryProvider);

  Future<Result<RefundRequest, Failure>> create({
    required String orderId,
    required String sellerId,
    required String reason,
  }) async {
    if (state.isLoading) {
      return Result.failure(
        const ValidationFailure('A refund request is already being sent.'),
      );
    }
    state = const AsyncValue.loading();
    final result = await _repo.create(
      orderId: orderId,
      sellerId: sellerId,
      reason: reason,
    );
    _apply(result);
    // A failure can mean "already requested"; reload server truth either way.
    ref.invalidate(orderRefundsProvider(orderId));
    if (result case Success()) {
      ref.invalidate(buyerRefundListProvider);
    }
    return result;
  }

  Future<Result<RefundRequest, Failure>> accept(String id) =>
      _sellerDecision(() => _repo.accept(id: id));

  Future<Result<RefundRequest, Failure>> reject(
    String id, {
    String? sellerNote,
  }) => _sellerDecision(() => _repo.reject(id: id, sellerNote: sellerNote));

  Future<Result<RefundRequest, Failure>> _sellerDecision(
    Future<Result<RefundRequest, Failure>> Function() call,
  ) async {
    if (state.isLoading) {
      return Result.failure(
        const ValidationFailure('A refund decision is already being sent.'),
      );
    }
    state = const AsyncValue.loading();
    final result = await call();
    _apply(result);
    if (ref.exists(sellerRefundListProvider)) {
      if (result case Success(:final value)) {
        ref.read(sellerRefundListProvider.notifier).replace(value);
      }
      // Success or "already processed": reload server truth either way.
      ref.read(sellerRefundListProvider.notifier).refresh();
    }
    return result;
  }

  Future<Result<RefundRequest, Failure>> cancel(String id) async {
    state = const AsyncValue.loading();
    final result = await _repo.cancel(id: id);
    _apply(result);
    if (result case Success()) {
      ref.invalidate(buyerRefundListProvider);
    }
    return result;
  }

  void _apply(Result<RefundRequest, Failure> result) {
    state = switch (result) {
      Success() => const AsyncValue.data(null),
      ResultFailure(failure: final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
  }
}

final refundMutationProvider =
    NotifierProvider<RefundMutationNotifier, AsyncValue<void>>(
      RefundMutationNotifier.new,
    );
