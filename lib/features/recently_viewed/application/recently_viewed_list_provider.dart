import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/recently_viewed_repository_impl.dart';
import '../domain/models/recently_viewed.dart';

/// Paginated list of full [RecentlyViewedEntry] items for the dedicated screen.
class RecentlyViewedListNotifier extends AsyncNotifier<RecentlyViewedListPage> {
  @override
  Future<RecentlyViewedListPage> build() async {
    final authenticated = ref.watch(
      authProvider.select((s) => s.isAuthenticated),
    );
    if (!authenticated) {
      return const RecentlyViewedListPage(
        items: [],
        total: 0,
        currentPage: 1,
        hasMore: false,
      );
    }
    return _fetch(page: 1);
  }

  Future<RecentlyViewedListPage> _fetch({required int page}) async {
    final result = await ref
        .read(recentlyViewedRepositoryProvider)
        .list(page: page, limit: 20);
    return switch (result) {
      Success(:final value) => value,
      ResultFailure(:final failure) => throw failure,
    };
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    try {
      final next = await _fetch(page: current.currentPage + 1);
      state = AsyncData(
        RecentlyViewedListPage(
          items: [...current.items, ...next.items],
          total: next.total,
          currentPage: next.currentPage,
          hasMore: next.hasMore,
        ),
      );
    } on Failure {
      // Keep existing data on load-more failure; user can retry via scroll
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1));
  }

  Future<int> clearAll() async {
    final result = await ref.read(recentlyViewedRepositoryProvider).clear();
    return switch (result) {
      Success(:final value) => value,
      ResultFailure() => 0,
    };
  }
}

final recentlyViewedListProvider =
    AsyncNotifierProvider<RecentlyViewedListNotifier, RecentlyViewedListPage>(
      RecentlyViewedListNotifier.new,
    );
