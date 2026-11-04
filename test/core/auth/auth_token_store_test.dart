import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/auth/auth_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage whose writes always fail (broken Keystore).
class _BrokenSecureStorage extends FlutterSecureStorage {
  const _BrokenSecureStorage();

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('keystore unavailable');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const token = 'eyJ.token.sig';
  const tokenKey = 'gw.auth.accessToken';
  const userKey = 'gw.auth.userId';
  const snapshotKey = 'gw.auth.sellerSnapshot';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('saveSession keeps the token out of SharedPreferences', () async {
    final store = SecureAuthTokenStore();
    await store.saveSession(
      accessToken: token,
      userId: 'u1',
      rememberDevice: true,
    );
    await store.saveSellerAccountSnapshot('{"panCardNumber":"ABCDE1234F"}');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(tokenKey), isNull);
    expect(prefs.getString(snapshotKey), isNull);

    const secure = FlutterSecureStorage();
    expect(await secure.read(key: tokenKey), token);
    expect(await secure.read(key: snapshotKey), isNotNull);

    // A fresh process reads it back from secure storage.
    final reopened = SecureAuthTokenStore();
    expect(await reopened.readAccessToken(), token);
    expect(await reopened.readUserId(), 'u1');
  });

  test('legacy plain copies move to secure storage and are wiped', () async {
    SharedPreferences.setMockInitialValues({
      tokenKey: token,
      userKey: 'u1',
      snapshotKey: '{"aadhaarNumber":"1234"}',
      'gw.auth.rememberDevice': 'true',
    });
    final store = SecureAuthTokenStore();

    expect(await store.readAccessToken(), token);
    expect(await store.readUserId(), 'u1');
    expect(await store.readSellerAccountSnapshot(), isNotNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(tokenKey), isNull);
    expect(prefs.getString(snapshotKey), isNull);
    const secure = FlutterSecureStorage();
    expect(await secure.read(key: tokenKey), token);
    expect(await secure.read(key: snapshotKey), isNotNull);
  });

  test('broken keystore keeps the session in memory only', () async {
    final store = SecureAuthTokenStore(storage: const _BrokenSecureStorage());
    await store.saveSession(
      accessToken: token,
      userId: 'u1',
      rememberDevice: true,
    );

    expect(await store.readAccessToken(), token);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(tokenKey), isNull);
  });

  test('concurrent first reads all see the stored token', () async {
    FlutterSecureStorage.setMockInitialValues({tokenKey: token, userKey: 'u1'});
    final store = SecureAuthTokenStore();

    final reads = await Future.wait([
      store.readAccessToken(),
      store.readAccessToken(),
      store.readAccessToken(),
    ]);
    expect(reads, everyElement(token));
  });

  test('clear wipes both stores', () async {
    final store = SecureAuthTokenStore();
    await store.saveSession(
      accessToken: token,
      userId: 'u1',
      rememberDevice: true,
    );
    await store.clear();

    expect(await store.readAccessToken(), isNull);
    expect(await const FlutterSecureStorage().read(key: tokenKey), isNull);
  });
}
