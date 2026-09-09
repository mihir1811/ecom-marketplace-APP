import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/refund_repository_impl.dart';
import '../domain/models/refund_list_page.dart';
import '../domain/models/refund_request.dart';
import '../domain/repositories/refund_repository.dart';

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

abstract class _RefundListNotifier extends Notifier<RefundListState> {
  CancelToken? _cancelToken;

  RefundRepository get _repo => ref.read(refundRepositoryProvider);

  Future<Result<RefundListPage, Failure>> fetchPage({
    required int page,
    CancelToken? cancelToken,
  });

  @override
  RefundListState build() {
    ref.watch(authProvider.select((s) => s.user?.id));
    ref.onDispose(() => _cancelToken?.cancel());
    Future.microtask(refresh);
    return const RefundListState(isLoading: true);
  }

  Future<void> refresh() async {
    _cancelToken?.cancel('refresh');
    _cancelToken = CancelToken();
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await fetchPage(page: 1, cancelToken: _cancelToken);
    switch (result) {
      case Success(value: final page):
        state = RefundListState(
          items: page.items,
          total: page.total,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
        );
      case ResultFailure(failure: final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
    }
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

class SellerRefundListNotifier extends _RefundListNotifier {
  @override
  Future<Result<RefundListPage, Failure>> fetchPage({
    required int page,
    CancelToken? cancelToken,
  }) {
    return _repo.listSeller(page: page, cancelToken: cancelToken);
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

class RefundMutationNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  RefundRepository get _repo => ref.read(refundRepositoryProvider);

  Future<Result<RefundRequest, Failure>> create({
    required String orderId,
    required String sellerId,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.create(
      orderId: orderId,
      sellerId: sellerId,
      reason: reason,
    );
    _apply(result);
    if (result case Success()) {
      ref.invalidate(buyerRefundListProvider);
    }
    return result;
  }

  Future<Result<RefundRequest, Failure>> accept(String id) async {
    state = const AsyncValue.loading();
    final result = await _repo.accept(id: id);
    _apply(result);
    if (result case Success()) {
      ref.invalidate(sellerRefundListProvider);
    }
    return result;
  }

  Future<Result<RefundRequest, Failure>> reject(
    String id, {
    String? sellerNote,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.reject(id: id, sellerNote: sellerNote);
    _apply(result);
    if (result case Success()) {
      ref.invalidate(sellerRefundListProvider);
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
      ResultFailure(failure: final failure) =>
        AsyncValue.error(failure, StackTrace.current),
    };
  }
}

final refundMutationProvider =
    NotifierProvider<RefundMutationNotifier, AsyncValue<void>>(
  RefundMutationNotifier.new,
);
