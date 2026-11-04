import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/result.dart';
import '../data/repositories/recently_viewed_repository_impl.dart';
import '../../cart/domain/models/cart_product_type.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

/// Product IDs the current user has recently viewed (for listing highlights).
class RecentlyViewedIdsNotifier extends Notifier<Set<String>>
    with DisposeTolerantNotifier<Set<String>> {
  @override
  Set<String> build() {
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId == null || userId.isEmpty) return const {};
    Future.microtask(refresh);
    return const {};
  }

  Future<void> refresh() async {
    if (!ref.read(authProvider).isAuthenticated) {
      state = const {};
      return;
    }
    final result = await ref.read(recentlyViewedRepositoryProvider).listIds();
    if (!ref.mounted) return;
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

final isRecentlyViewedProvider = Provider.family<bool, String>((
  ref,
  productId,
) {
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
  // The server history only knows catalog products, not marketplace slugs.
  if (productType == CartProductType.marketplaceJewellery) return;
  ref
      .read(recentlyViewedRepositoryProvider)
      .record(productId: id, productType: productType);
}

/// Ensure IDs are refreshed when product lists are fetched.
void ensureRecentlyViewedIdsLoaded(Ref ref) {
  if (!ref.read(authProvider).isAuthenticated) return;
  ref.read(recentlyViewedIdsProvider.notifier).refresh();
}
