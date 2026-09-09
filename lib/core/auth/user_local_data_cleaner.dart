import 'package:shared_preferences/shared_preferences.dart';

/// Clears non-auth local prefs that are still user-scoped (chat session, etc.).
///
/// Auth secrets are cleared by [AuthTokenStore.clear]. Call this on every
/// logout / session expiry so the next account never inherits local leftovers.
abstract final class UserLocalDataCleaner {
  static const aiChatSessionId = 'gw.aiChat.sessionId';
  static const aiChatGuestSessionKeys = 'gw.aiChat.guestSessionKeys';

  static const _keys = <String>[aiChatSessionId, aiChatGuestSessionKeys];

  static Future<void> clearUserScopedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([for (final key in _keys) prefs.remove(key)]);
    } catch (_) {
      // Best-effort; auth clear must still succeed.
    }
  }
}
