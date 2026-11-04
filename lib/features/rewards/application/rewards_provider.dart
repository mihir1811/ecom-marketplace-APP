import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/rewards_repository_impl.dart';
import '../domain/models/rewards.dart';
import '../domain/repositories/rewards_repository.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

final rewardsProvider = AsyncNotifierProvider<RewardsNotifier, RewardsSummary>(
  RewardsNotifier.new,
);

/// Loads GET /rewards (balance, rates, latest movements) for the buyer.
class RewardsNotifier extends AsyncNotifier<RewardsSummary>
    with DisposeTolerantAsyncNotifier<RewardsSummary> {
  RewardsRepository get _repo => ref.read(rewardsRepositoryProvider);

  @override
  Future<RewardsSummary> build() {
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId == null || userId.isEmpty) {
      return Future.error(
        const AuthFailure('Sign in to view your reward points.'),
        StackTrace.current,
      );
    }
    return _fetch();
  }

  Future<RewardsSummary> _fetch() async {
    final result = await _repo.getSummary();
    return switch (result) {
      Success(:final value) => value,
      ResultFailure(:final failure) => throw failure,
    };
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
    if (!ref.mounted) return;
  }
}

/// Paged points history state.
class RewardTransactionsState {
  const RewardTransactionsState({
    this.items = const [],
    this.page = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<RewardTransaction> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  RewardTransactionsState copyWith({
    List<RewardTransaction>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RewardTransactionsState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Paginated GET /rewards/transactions, newest first.
class RewardTransactionsNotifier extends Notifier<RewardTransactionsState>
    with DisposeTolerantNotifier<RewardTransactionsState> {
  static const pageSize = 20;

  RewardsRepository get _repo => ref.read(rewardsRepositoryProvider);

  @override
  RewardTransactionsState build() {
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId == null || userId.isEmpty) {
      return const RewardTransactionsState();
    }
    Future.microtask(loadInitial);
    return const RewardTransactionsState(isLoading: true);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.getTransactions(page: 1, limit: pageSize);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = RewardTransactionsState(
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
    final result = await _repo.getTransactions(
      page: state.page + 1,
      limit: pageSize,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        final seen = {for (final t in state.items) t.id};
        state = state.copyWith(
          items: [
            ...state.items,
            ...value.transactions.where((t) => !seen.contains(t.id)),
          ],
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

final rewardTransactionsProvider =
    NotifierProvider<RewardTransactionsNotifier, RewardTransactionsState>(
      RewardTransactionsNotifier.new,
    );

/// Re-reads balance and history after points may have moved (checkout,
/// refund). Safe to call when nothing is listening.
void refreshRewards(Ref ref) {
  ref.invalidate(rewardsProvider);
  ref.invalidate(rewardTransactionsProvider);
}
