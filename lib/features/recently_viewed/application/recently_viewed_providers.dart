import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/result.dart';
import '../data/repositories/recently_viewed_repository_impl.dart';

/// Product IDs the current user has recently viewed (for listing highlights).
class RecentlyViewedIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final authenticated = ref.watch(
      authProvider.select((s) => s.isAuthenticated),
    );
    if (!authenticated) return const {};
    Future.microtask(refresh);
    return const {};
  }

  Future<void> refresh() async {
    if (!ref.read(authProvider).isAuthenticated) {
      state = const {};
      return;
    }
    final result =
        await ref.read(recentlyViewedRepositoryProvider).listIds();
    switch (result) {
      case Success(:final value):
        state = {
          for (final item in value)
            if (item.productId.isNotEmpty) item.productId,
        };
      case ResultFailure():
        break;
    }
  }

  void markViewed(String productId) {
    final id = productId.trim();
    if (id.isEmpty || state.contains(id)) return;
    state = {...state, id};
  }

  void clearLocal() => state = const {};
}

final recentlyViewedIdsProvider =
    NotifierProvider<RecentlyViewedIdsNotifier, Set<String>>(
  RecentlyViewedIdsNotifier.new,
);

final isRecentlyViewedProvider = Provider.family<bool, String>((ref, productId) {
  final id = productId.trim();
  if (id.isEmpty) return false;
  return ref.watch(recentlyViewedIdsProvider.select((ids) => ids.contains(id)));
});

/// Fire-and-forget recently viewed recording from product detail.
void recordRecentlyViewed(
  WidgetRef ref, {
  required String productId,
  required String productType,
}) {
  final id = productId.trim();
  if (id.isEmpty) return;
  ref.read(recentlyViewedIdsProvider.notifier).markViewed(id);
  ref.read(recentlyViewedRepositoryProvider).record(
        productId: id,
        productType: productType,
      );
}

/// Ensure IDs are refreshed when product lists are fetched.
void ensureRecentlyViewedIdsLoaded(Ref ref) {
  if (!ref.read(authProvider).isAuthenticated) return;
  ref.read(recentlyViewedIdsProvider.notifier).refresh();
}
