import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/wallet_repository_impl.dart';
import '../domain/models/wallet.dart';
import '../domain/repositories/wallet_repository.dart';

final walletProvider = AsyncNotifierProvider<WalletNotifier, Wallet>(
  WalletNotifier.new,
);

/// Loads GET /wallet for the authenticated user.
class WalletNotifier extends AsyncNotifier<Wallet> {
  WalletRepository get _repo => ref.read(walletRepositoryProvider);

  @override
  Future<Wallet> build() {
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId == null || userId.isEmpty) {
      return Future.error(
        const AuthFailure('Sign in to view your wallet.'),
        StackTrace.current,
      );
    }
    return _fetch();
  }
  Future<Wallet> _fetch() async {
    final result = await _repo.getWallet();
    return switch (result) {
      Success(:final value) => value,
      ResultFailure(:final failure) => throw failure,
    };
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }
}

class WalletTransactionsState {
  const WalletTransactionsState({
    this.items = const [],
    this.page = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<WalletTransaction> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  WalletTransactionsState copyWith({
    List<WalletTransaction>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WalletTransactionsState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Paginated GET /wallet/transactions.
class WalletTransactionsNotifier extends Notifier<WalletTransactionsState> {
  static const pageSize = 20;

  WalletRepository get _repo => ref.read(walletRepositoryProvider);

  @override
  WalletTransactionsState build() {
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId == null || userId.isEmpty) {
      return const WalletTransactionsState();
    }
    Future.microtask(loadInitial);
    return const WalletTransactionsState(isLoading: true);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.getTransactions(page: 1, limit: pageSize);
    switch (result) {
      case Success(:final value):
        state = WalletTransactionsState(
          items: value.transactions,
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
    final result = await _repo.getTransactions(page: nextPage, limit: pageSize);
    switch (result) {
      case Success(:final value):
        state = state.copyWith(
          items: [...state.items, ...value.transactions],
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

final walletTransactionsProvider =
    NotifierProvider<WalletTransactionsNotifier, WalletTransactionsState>(
      WalletTransactionsNotifier.new,
    );
