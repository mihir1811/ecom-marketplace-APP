import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth secrets across app launches.
abstract class AuthTokenStore {
  Future<void> saveSession({
    required String accessToken,
    required String userId,
    String? sellerId,
    String? userName,
    String? role,
    required bool rememberDevice,
  });

  Future<String?> readAccessToken();
  Future<String?> readUserId();
  Future<String?> readSellerId();
  Future<String?> readUserName();
  Future<String?> readRole();
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
      : _storage = storage ??
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
  static const _rememberDevice = 'gw.auth.rememberDevice';

  final FlutterSecureStorage _storage;

  String? _cachedAccessToken;
  String? _cachedUserId;
  String? _cachedSellerId;
  String? _cachedUserName;
  String? _cachedRole;
  bool? _cachedRememberDevice;
  bool _hydrated = false;

  @override
  Future<void> saveSession({
    required String accessToken,
    required String userId,
    String? sellerId,
    String? userName,
    String? role,
    required bool rememberDevice,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedUserId = userId;
    _cachedSellerId =
        sellerId != null && sellerId.isNotEmpty ? sellerId : null;
    _cachedUserName =
        userName != null && userName.isNotEmpty ? userName : null;
    _cachedRole = role != null && role.isNotEmpty ? role : null;
    _cachedRememberDevice = true;
    _hydrated = true;

    // Always persist — API rememberDevice sessions last ~30 days.
    await _writePersisted(
      accessToken: accessToken,
      userId: userId,
      sellerId: _cachedSellerId,
      userName: _cachedUserName,
      role: _cachedRole,
      rememberDevice: true,
    );
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
    _cachedRememberDevice = null;
    _hydrated = true;
    await _clearPersisted();
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
    _cachedRememberDevice = source[_rememberDevice] == 'true';
  }

  Map<String, String?> _pickSource(
    Map<String, String?> secure,
    Map<String, String?>? prefs,
  ) {
    final secureToken = secure[_accessToken];
    if (secureToken != null && secureToken.isNotEmpty) return secure;
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
    required bool rememberDevice,
  }) async {
    if (kIsWeb) {
      await _writePrefs(
        accessToken: accessToken,
        userId: userId,
        sellerId: sellerId,
        userName: userName,
        role: role,
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
      ]);
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
    } catch (e, st) {
      assert(() {
        debugPrint('AuthTokenStore.prefs write failed: $e\n$st');
        return true;
      }());
    }
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
        _storage.read(key: _rememberDevice),
      ]);
      return {
        _accessToken: values[0],
        _userId: values[1],
        _sellerId: values[2],
        _userName: values[3],
        _role: values[4],
        _rememberDevice: values[5],
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
