import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/wishlist_item.dart';

/// Wishlist entries the server favorites can't hold: jewellery marketplace
/// pieces, which (as on jewelry.gemworld.in) are saved on the device.
class LocalWishlistStore {
  const LocalWishlistStore();

  static const _key = 'gw.wishlist.marketplace.v1';

  Future<List<WishlistItem>> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final e in decoded)
          if (e is Map && '${e['id'] ?? ''}'.isNotEmpty)
            WishlistItem(
              id: '${e['id']}',
              category: WishlistCategory.jewelry,
              productType: FavoriteProductType.marketplaceJewellery,
              title: '${e['title'] ?? ''}',
              subtitle: '${e['subtitle'] ?? ''}',
              priceLabel: '${e['priceLabel'] ?? ''}',
              imageUrl: e['imageUrl']?.toString(),
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> write(List<WishlistItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode([
          for (final i in items)
            {
              'id': i.id,
              'title': i.title,
              'subtitle': i.subtitle,
              'priceLabel': i.priceLabel,
              'imageUrl': ?i.imageUrl,
            },
        ]),
      );
    } catch (_) {}
  }
}
