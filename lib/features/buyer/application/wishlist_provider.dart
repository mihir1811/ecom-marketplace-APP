import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/wishlist_item.dart';

class WishlistNotifier extends Notifier<List<WishlistItem>> {
  @override
  List<WishlistItem> build() => const [];

  bool contains(String id) => state.any((e) => e.id == id);

  /// Adds [item] if missing; removes it if already wishlisted.
  /// Returns `true` when the item is now in the wishlist.
  bool toggle(WishlistItem item) {
    if (contains(item.id)) {
      remove(item.id);
      return false;
    }
    add(item);
    return true;
  }

  void add(WishlistItem item) {
    if (contains(item.id)) return;
    state = [...state, item];
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void clear() => state = const [];
}

final wishlistProvider =
    NotifierProvider<WishlistNotifier, List<WishlistItem>>(WishlistNotifier.new);

final isInWishlistProvider = Provider.family<bool, String>((ref, id) {
  return ref.watch(wishlistProvider.select((items) => items.any((e) => e.id == id)));
});

final wishlistCountProvider = Provider<int>((ref) {
  return ref.watch(wishlistProvider.select((items) => items.length));
});
