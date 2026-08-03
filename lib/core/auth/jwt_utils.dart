import 'dart:async';
import 'dart:convert';

/// Lightweight JWT helpers (payload decode only — no signature verify).
abstract final class JwtUtils {
  /// Returns unix-seconds `exp` claim, or null if missing/invalid.
  static int? readExpiry(String token) {
    final payload = decodePayload(token);
    return _asInt(payload?['exp']);
  }

  /// Returns unix-seconds `iat` claim, or null if missing/invalid.
  static int? readIssuedAt(String token) {
    final payload = decodePayload(token);
    return _asInt(payload?['iat']);
  }

  static bool isExpired(String token, {DateTime? now}) {
    final exp = readExpiry(token);
    if (exp == null) return true;
    final epoch = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    return epoch >= exp;
  }

  /// Remaining validity; `Duration.zero` if expired/invalid.
  static Duration timeUntilExpiry(String token, {DateTime? now}) {
    final exp = readExpiry(token);
    if (exp == null) return Duration.zero;
    final epoch = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final seconds = exp - epoch;
    if (seconds <= 0) return Duration.zero;
    return Duration(seconds: seconds);
  }

  static Map<String, dynamic>? decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) return json;
      if (json is Map) return Map<String, dynamic>.from(json);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// User id from `sub` / `id` claims.
  static String? readUserId(Map<String, dynamic> claims) {
    final sub = claims['sub'];
    if (sub is String && sub.trim().isNotEmpty) return sub.trim();
    final id = claims['id'];
    if (id is String && id.trim().isNotEmpty) return id.trim();
    return null;
  }

  static String? readRole(Map<String, dynamic> claims) {
    final role = claims['role'];
    if (role is String && role.trim().isNotEmpty) return role.trim();
    return null;
  }

  static String? readSellerId(Map<String, dynamic> claims) {
    final nested = claims['seller'];
    if (nested is Map) {
      final id = nested['id'];
      if (id is String && id.trim().isNotEmpty) return id.trim();
    }
    final flat = claims['sellerId'];
    if (flat is String && flat.trim().isNotEmpty) return flat.trim();
    return null;
  }

  static String? readUserName(Map<String, dynamic> claims) {
    final userName = claims['userName'] ?? claims['username'];
    if (userName is String && userName.trim().isNotEmpty) {
      return userName.trim();
    }
    return null;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
