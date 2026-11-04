import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/user_local_data_cleaner.dart';

/// The buyer's latest catalogue searches, newest first, kept on device only.
class RecentSearches extends StateNotifier<List<String>> {
  RecentSearches() : super(const []) {
    _load();
  }

  static const prefsKey = UserLocalDataCleaner.recentSearches;
  static const _max = 8;

  bool _touched = false;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(prefsKey) ?? const <String>[];
      if (!mounted) return;
      if (!_touched) {
        state = stored.take(_max).toList();
        return;
      }
      // Searches made before the load finished go on top of the stored list.
      final seen = state.map((q) => q.toLowerCase()).toSet();
      state = [
        ...state,
        ...stored.where((q) => !seen.contains(q.toLowerCase())),
      ].take(_max).toList();
      await _save();
    } catch (_) {
      // No storage: start empty.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(prefsKey, state);
    } catch (_) {
      // Best-effort; the list still works for this session.
    }
  }

  /// Moves [raw] to the top, dropping any earlier copy (case-insensitive).
  void add(String raw) {
    final query = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (query.length < 2) return;
    _touched = true;
    final key = query.toLowerCase();
    state = [
      query,
      ...state.where((q) => q.toLowerCase() != key),
    ].take(_max).toList();
    _save();
  }

  void remove(String query) {
    _touched = true;
    state = [...state]..remove(query);
    _save();
  }

  void clear() {
    _touched = true;
    state = const [];
    _save();
  }
}

/// Reloaded from storage each time search opens.
final recentSearchesProvider =
    StateNotifierProvider.autoDispose<RecentSearches, List<String>>(
      (ref) => RecentSearches(),
    );
