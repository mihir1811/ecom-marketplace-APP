import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_local_data_cleaner.dart';

/// Persists auth secrets across app launches.
abstract class AuthTokenStore {
  Future<void> saveSession({
    required String accessToken,
    required String userId,
    String? sellerId,
    String? userName,
    String? role,
    bool? isVerified,
    required bool rememberDevice,
  });

  Future<String?> readAccessToken();
  Future<String?> readUserId();
  Future<String?> readSellerId();
  Future<String?> readUserName();
  Future<String?> readRole();
  Future<bool?> readIsVerified();
  Future<String?> readSellerAccountSnapshot();
  Future<void> saveSellerAccountSnapshot(String? json);
  Future<bool> readRememberDevice();
  Future<void> clear();
}

/// Platform-backed [AuthTokenStore] with an in-memory cache.
///
/// - **Native:** [FlutterSecureStorage] (Keychain / EncryptedSharedPreferences)
/// - **Web:** [SharedPreferences] fallback — secure storage often throws
///   `OperationError` in Chrome, which would break remember-me persistence
class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  static const _accessToken = 'gw.auth.accessToken';
  static const _userId = 'gw.auth.userId';
  static const _sellerId = 'gw.auth.sellerId';
  static const _userName = 'gw.auth.userName';
  static const _role = 'gw.auth.role';
  static const _isVerified = 'gw.auth.isVerified';
  static const _sellerSnapshot = 'gw.auth.sellerSnapshot';
  static const _rememberDevice = 'gw.auth.rememberDevice';

  final FlutterSecureStorage _storage;

  String? _cachedAccessToken;
  String? _cachedUserId;
  String? _cachedSellerId;
  String? _cachedUserName;
  String? _cachedRole;
  bool? _cachedIsVerified;
  String? _cachedSellerSnapshot;
  bool? _cachedRememberDevice;
  bool _hydrated = false;

  @override
  Future<void> saveSession({
    required String accessToken,
    required String userId,
    String? sellerId,
    String? userName,
    String? role,
    bool? isVerified,
    required bool rememberDevice,
  }) async {
    final switchingUser = _cachedUserId != null && _cachedUserId != userId;
    _cachedAccessToken = accessToken;
    _cachedUserId = userId;
    _cachedSellerId = sellerId != null && sellerId.isNotEmpty ? sellerId : null;
    _cachedUserName = userName != null && userName.isNotEmpty ? userName : null;
    _cachedRole = role != null && role.isNotEmpty ? role : null;
    if (isVerified != null) {
      _cachedIsVerified = isVerified;
    }
    if (switchingUser) {
      // Drop previous account's seller snapshot immediately on account switch.
      _cachedSellerSnapshot = null;
    }
    _cachedRememberDevice = true;
    _hydrated = true;

    // Always persist — API rememberDevice sessions last ~30 days.
    await _writePersisted(
      accessToken: accessToken,
      userId: userId,
      sellerId: _cachedSellerId,
      userName: _cachedUserName,
      role: _cachedRole,
      isVerified: _cachedIsVerified,
      rememberDevice: true,
    );
    if (switchingUser) {
      await _writeSellerSnapshot(null);
    }
  }

  @override
  Future<String?> readAccessToken() async {
    await _ensureHydrated();
    return _cachedAccessToken;
  }

  @override
  Future<String?> readUserId() async {
    await _ensureHydrated();
    return _cachedUserId;
  }

  @override
  Future<String?> readSellerId() async {
    await _ensureHydrated();
    return _cachedSellerId;
  }

  @override
  Future<String?> readUserName() async {
    await _ensureHydrated();
    return _cachedUserName;
  }

  @override
  Future<String?> readRole() async {
    await _ensureHydrated();
    return _cachedRole;
  }

  @override
  Future<bool?> readIsVerified() async {
    await _ensureHydrated();
    return _cachedIsVerified;
  }

  @override
  Future<String?> readSellerAccountSnapshot() async {
    await _ensureHydrated();
    return _cachedSellerSnapshot;
  }

  @override
  Future<void> saveSellerAccountSnapshot(String? json) async {
    await _ensureHydrated();
    final value = json != null && json.trim().isNotEmpty ? json.trim() : null;
    _cachedSellerSnapshot = value;
    await _writeSellerSnapshot(value);
  }

  @override
  Future<bool> readRememberDevice() async {
    await _ensureHydrated();
    return _cachedRememberDevice ?? false;
  }

  @override
  Future<void> clear() async {
    _cachedAccessToken = null;
    _cachedUserId = null;
    _cachedSellerId = null;
    _cachedUserName = null;
    _cachedRole = null;
    _cachedIsVerified = null;
    _cachedSellerSnapshot = null;
    _cachedRememberDevice = null;
    _hydrated = true;
    await _clearPersisted();
    await UserLocalDataCleaner.clearUserScopedPrefs();
  }

  Future<void> _ensureHydrated() async {
    if (_hydrated) return;
    _hydrated = true;

    final fromSecure = await _readSecureMap();
    final fromPrefs = await _readPrefsMap();
    final source = _pickSource(fromSecure, fromPrefs);

    _cachedAccessToken = source[_accessToken];
    _cachedUserId = source[_userId];
    _cachedSellerId = source[_sellerId];
    _cachedUserName = source[_userName];
    _cachedRole = source[_role];
    final verifiedRaw = source[_isVerified];
    _cachedIsVerified = verifiedRaw == null ? null : verifiedRaw == 'true';
    _cachedSellerSnapshot = source[_sellerSnapshot];
    _cachedRememberDevice = source[_rememberDevice] == 'true';
  }

  Map<String, String?> _pickSource(
    Map<String, String?> secure,
    Map<String, String?>? prefs,
  ) {
    final secureToken = secure[_accessToken];
    if (secureToken != null && secureToken.isNotEmpty) {
      // Never blend identity fields across stores — a prior account's sellerId
      // / userName can linger in prefs after a secure-only write and poison
      // the next login. Only allow seller-snapshot prefs fallback when userIds
      // match (large snapshots sometimes fail Keychain writes).
      final merged = Map<String, String?>.from(secure);
      final secureSnap = merged[_sellerSnapshot];
      final prefsSnap = prefs?[_sellerSnapshot];
      final sameUser =
          prefs != null &&
          (prefs[_userId] ?? '').isNotEmpty &&
          prefs[_userId] == secure[_userId];
      if ((secureSnap == null || secureSnap.isEmpty) &&
          sameUser &&
          prefsSnap != null &&
          prefsSnap.isNotEmpty) {
        merged[_sellerSnapshot] = prefsSnap;
      }
      return merged;
    }
    if (prefs != null) {
      final prefsToken = prefs[_accessToken];
      if (prefsToken != null && prefsToken.isNotEmpty) return prefs;
    }
    return secure;
  }

  Future<void> _writePersisted({
    required String accessToken,
    required String userId,
    String? sellerId,
    String? userName,
    String? role,
    bool? isVerified,
    required bool rememberDevice,
  }) async {
    if (kIsWeb) {
      await _writePrefs(
        accessToken: accessToken,
        userId: userId,
        sellerId: sellerId,
        userName: userName,
        role: role,
        isVerified: isVerified,
        rememberDevice: rememberDevice,
      );
      return;
    }

    try {
      await Future.wait([
        _storage.write(key: _accessToken, value: accessToken),
        _storage.write(key: _userId, value: userId),
        _storage.write(key: _rememberDevice, value: rememberDevice.toString()),
        if (sellerId != null)
          _storage.write(key: _sellerId, value: sellerId)
        else
          _storage.delete(key: _sellerId),
        if (userName != null)
          _storage.write(key: _userName, value: userName)
        else
          _storage.delete(key: _userName),
        if (role != null)
          _storage.write(key: _role, value: role)
        else
          _storage.delete(key: _role),
        if (isVerified != null)
          _storage.write(key: _isVerified, value: isVerified.toString())
        else
          _storage.delete(key: _isVerified),
      ]);
      // Keep SharedPreferences in lockstep so a later secure→prefs merge
      // cannot revive a previous account's sellerId / userId.
      await _writePrefs(
        accessToken: accessToken,
        userId: userId,
        sellerId: sellerId,
        userName: userName,
        role: role,
        isVerified: isVerified,
        rememberDevice: rememberDevice,
      );
    } catch (e, st) {
      assert(() {
        debugPrint('AuthTokenStore.secure write failed: $e\n$st');
        return true;
      }());
      // Native fallback so remember-me still works if Keychain fails.
      await _writePrefs(
        accessToken: accessToken,
        userId: userId,
        sellerId: sellerId,
        userName: userName,
        role: role,
        isVerified: isVerified,
        rememberDevice: rememberDevice,
      );
    }
  }

  Future<void> _writePrefs({
    required String accessToken,
    required String userId,
    String? sellerId,
    String? userName,
    String? role,
    bool? isVerified,
    required bool rememberDevice,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessToken, accessToken);
      await prefs.setString(_userId, userId);
      await prefs.setString(_rememberDevice, rememberDevice.toString());
      if (sellerId != null) {
        await prefs.setString(_sellerId, sellerId);
      } else {
        await prefs.remove(_sellerId);
      }
      if (userName != null) {
        await prefs.setString(_userName, userName);
      } else {
        await prefs.remove(_userName);
      }
      if (role != null) {
        await prefs.setString(_role, role);
      } else {
        await prefs.remove(_role);
      }
      if (isVerified != null) {
        await prefs.setString(_isVerified, isVerified.toString());
      } else {
        await prefs.remove(_isVerified);
      }
    } catch (e, st) {
      assert(() {
        debugPrint('AuthTokenStore.prefs write failed: $e\n$st');
        return true;
      }());
    }
  }

  Future<void> _writeSellerSnapshot(String? json) async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (json == null) {
          await prefs.remove(_sellerSnapshot);
        } else {
          await prefs.setString(_sellerSnapshot, json);
        }
      } catch (e, st) {
        assert(() {
          debugPrint(
            'AuthTokenStore.sellerSnapshot prefs write failed: $e\n$st',
          );
          return true;
        }());
      }
      return;
    }

    try {
      if (json == null) {
        await _storage.delete(key: _sellerSnapshot);
      } else {
        await _storage.write(key: _sellerSnapshot, value: json);
      }
    } catch (e, st) {
      assert(() {
        debugPrint(
          'AuthTokenStore.sellerSnapshot secure write failed: $e\n$st',
        );
        return true;
      }());
    }
    // Always mirror to prefs so native cold-start can recover if secure
    // storage drops or rejects the snapshot.
    try {
      final prefs = await SharedPreferences.getInstance();
      if (json == null) {
        await prefs.remove(_sellerSnapshot);
      } else {
        await prefs.setString(_sellerSnapshot, json);
      }
    } catch (_) {}
  }

  Future<Map<String, String?>> _readSecureMap() async {
    if (kIsWeb) return const {};
    try {
      final values = await Future.wait([
        _storage.read(key: _accessToken),
        _storage.read(key: _userId),
        _storage.read(key: _sellerId),
        _storage.read(key: _userName),
        _storage.read(key: _role),
        _storage.read(key: _isVerified),
        _storage.read(key: _sellerSnapshot),
        _storage.read(key: _rememberDevice),
      ]);
      return {
        _accessToken: values[0],
        _userId: values[1],
        _sellerId: values[2],
        _userName: values[3],
        _role: values[4],
        _isVerified: values[5],
        _sellerSnapshot: values[6],
        _rememberDevice: values[7],
      };
    } catch (e, st) {
      assert(() {
        debugPrint('AuthTokenStore.secure read failed: $e\n$st');
        return true;
      }());
      return const {};
    }
  }

  Future<Map<String, String?>> _readPrefsMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        _accessToken: prefs.getString(_accessToken),
        _userId: prefs.getString(_userId),
        _sellerId: prefs.getString(_sellerId),
        _userName: prefs.getString(_userName),
        _role: prefs.getString(_role),
        _isVerified: prefs.getString(_isVerified),
        _sellerSnapshot: prefs.getString(_sellerSnapshot),
        _rememberDevice: prefs.getString(_rememberDevice),
      };
    } catch (e, st) {
      assert(() {
        debugPrint('AuthTokenStore.prefs read failed: $e\n$st');
        return true;
      }());
      return const {};
    }
  }

  Future<void> _clearPersisted() async {
    if (!kIsWeb) {
      try {
        await _storage.deleteAll();
      } catch (e, st) {
        assert(() {
          debugPrint('AuthTokenStore.secure clear failed: $e\n$st');
          return true;
        }());
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_accessToken),
        prefs.remove(_userId),
        prefs.remove(_sellerId),
        prefs.remove(_userName),
        prefs.remove(_role),
        prefs.remove(_isVerified),
        prefs.remove(_sellerSnapshot),
        prefs.remove(_rememberDevice),
      ]);
    } catch (e, st) {
      assert(() {
        debugPrint('AuthTokenStore.prefs clear failed: $e\n$st');
        return true;
      }());
    }
  }
}

/// App-wide secure token store.
final authTokenStoreProvider = Provider<AuthTokenStore>(
  (ref) => SecureAuthTokenStore(),
);
