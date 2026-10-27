import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/bag_line.dart';
import '../domain/models/marketplace_order.dart';

/// Keeps the jewellery bag and the last delivery address on the device.
///
/// The device copy is the bag (the website does the same); signing out
/// leaves it in place. A signed-in buyer's bag is also copied to the server
/// for sellers to see, see `jewelryBagSyncProvider`.
class JewelryBagStore {
  const JewelryBagStore();

  static const _bagKey = 'gw.jewelryBag.v1';
  static const _addressKey = 'gw.jewelryBag.address.v1';

  Future<List<BagLine>> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_bagKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (BagLine.fromJson(item) case final line?) line,
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> write(List<BagLine> lines) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _bagKey,
        jsonEncode([for (final l in lines) l.toJson()]),
      );
    } catch (_) {
      // Best effort: the in-memory bag still works this session.
    }
  }

  Future<MarketplaceAddress?> readAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_addressKey);
      if (raw == null || raw.isEmpty) return null;
      final j = jsonDecode(raw);
      if (j is! Map) return null;
      String text(String key) => j[key]?.toString() ?? '';
      return MarketplaceAddress(
        fullName: text('fullName'),
        phone: text('phone'),
        line1: text('line1'),
        line2: j['line2']?.toString(),
        city: text('city'),
        state: text('state'),
        postalCode: text('postalCode'),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeAddress(MarketplaceAddress address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_addressKey, jsonEncode(address.toJson()));
    } catch (_) {}
  }
}
