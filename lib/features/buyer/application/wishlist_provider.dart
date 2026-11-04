import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/local_wishlist_store.dart';
import '../data/repositories/favorites_repository_impl.dart';
import '../domain/models/wishlist_item.dart';
import '../domain/repositories/favorites_repository.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

/// Local + remote wishlist snapshot for heart toggles and the wishlist screen.
class WishlistUiState {
  const WishlistUiState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<WishlistItem> items;
  final bool isLoading;
  final String? errorMessage;

  WishlistUiState copyWith({
    List<WishlistItem>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WishlistUiState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class WishlistNotifier extends Notifier<WishlistUiState>
    with DisposeTolerantNotifier<WishlistUiState> {
  static const _pageSize = 50;

  FavoritesRepository get _repo => ref.read(favoritesRepositoryProvider);

  static const _local = LocalWishlistStore();

  /// Marketplace jewellery lives on the device, not in `/favorites`.
  static bool _isLocal(String productType) =>
      productType == FavoriteProductType.marketplaceJewellery;

  List<WishlistItem> get _localItems => [
    for (final i in state.items)
      if (_isLocal(i.productType)) i,
  ];

  @override
  WishlistUiState build() {
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId == null || userId.isEmpty) {
      Future.microtask(_loadLocal);
      return const WishlistUiState();
    }
    Future.microtask(refresh);
    return const WishlistUiState(isLoading: true);
  }

  Future<void> _loadLocal() async {
    final local = await _local.read();
    if (!ref.mounted) return;
    if (local.isEmpty) return;
    final ids = {for (final i in state.items) i.id};
    state = state.copyWith(
      items: [
        ...state.items,
        for (final i in local)
          if (!ids.contains(i.id)) i,
      ],
    );
  }

  bool contains(String id) => state.items.any((e) => e.id == id);

  Future<void> refresh() async {
    if (!ref.read(authProvider).isAuthenticated) {
      state = WishlistUiState(items: await _local.read());
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    final local = await _local.read();
    if (!ref.mounted) return;

    final all = <WishlistItem>[];
    var page = 1;
    var hasMore = true;

    while (hasMore && page <= 20) {
      final result = await _repo.list(page: page, limit: _pageSize);
      if (!ref.mounted) return;
      switch (result) {
        case Success(:final value):
          all.addAll(value.items);
          hasMore = value.hasMore;
          page += 1;
        case ResultFailure(:final failure):
          if (failure is NetworkFailure && failure.isCancelled) return;
          state = state.copyWith(
            items: [...all, ...local],
            isLoading: false,
            errorMessage: failure.message,
          );
          return;
      }
    }

    state = WishlistUiState(items: [...all, ...local]);
  }

  /// Adds [item] if missing; removes it if already wishlisted.
  /// Returns `true` when the item is now in the wishlist.
  Future<bool> toggle(WishlistItem item) async {
    if (contains(item.id)) {
      await remove(item.id, productType: item.productType);
      return contains(item.id);
    }
    await add(item);
    return contains(item.id);
  }

  Future<void> add(WishlistItem item) async {
    if (contains(item.id)) return;
    if (_isLocal(item.productType)) {
      state = state.copyWith(items: [...state.items, item], clearError: true);
      await _local.write(_localItems);
      if (!ref.mounted) return;
      return;
    }
    if (!ref.read(authProvider).isAuthenticated) return;

    state = state.copyWith(items: [...state.items, item], clearError: true);
    final result = await _repo.add(
      productId: item.id,
      productType: item.productType,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = state.copyWith(
          items: [
            for (final existing in state.items)
              if (existing.id == item.id)
                WishlistItem(
                  id: existing.id,
                  category: existing.category,
                  productType: existing.productType,
                  title: existing.title,
                  subtitle: existing.subtitle,
                  priceLabel: existing.priceLabel,
                  imageUrl: existing.imageUrl,
                  imageAsset: existing.imageAsset,
                  favoriteId: value.favoriteId,
                )
              else
                existing,
          ],
        );
      case ResultFailure(:final failure):
        if (failure.message.toLowerCase().contains('already')) return;
        state = state.copyWith(
          items: state.items.where((e) => e.id != item.id).toList(),
          errorMessage: failure.message,
        );
    }
  }

  Future<void> remove(String id, {String? productType}) async {
    WishlistItem? previous;
    for (final item in state.items) {
      if (item.id == id) {
        previous = item;
        break;
      }
    }
    if (previous == null) return;

    state = state.copyWith(
      items: state.items.where((e) => e.id != id).toList(),
      clearError: true,
    );
    final type = productType ?? previous.productType;
    if (_isLocal(type)) {
      await _local.write(_localItems);
      if (!ref.mounted) return;
      return;
    }
    if (!ref.read(authProvider).isAuthenticated) return;

    final result = await _repo.remove(productId: id, productType: type);
    if (!ref.mounted) return;
    switch (result) {
      case Success():
        return;
      case ResultFailure(:final failure):
        final missing =
            failure.message.toLowerCase().contains('not found') ||
            failure.message.toLowerCase().contains('not in favorites');
        if (missing) return;
        state = state.copyWith(
          items: [...state.items, previous],
          errorMessage: failure.message,
        );
    }
  }

  void clear() => state = const WishlistUiState();
}

final wishlistProvider = NotifierProvider<WishlistNotifier, WishlistUiState>(
  WishlistNotifier.new,
);

final isInWishlistProvider = Provider.family<bool, String>((ref, id) {
  return ref.watch(
    wishlistProvider.select((s) => s.items.any((e) => e.id == id)),
  );
});

final wishlistCountProvider = Provider<int>((ref) {
  return ref.watch(wishlistProvider.select((s) => s.items.length));
});
