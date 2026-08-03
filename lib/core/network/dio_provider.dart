import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_token_store.dart';
import 'dio_client.dart';

/// Bumped when a protected API returns 401 so [AuthController] can clear state.
final authSessionInvalidatorProvider =
    NotifierProvider<AuthSessionInvalidator, int>(AuthSessionInvalidator.new);

/// Increments when the auth interceptor clears an expired/invalid session.
class AuthSessionInvalidator extends Notifier<int> {
  @override
  int build() => 0;

  void invalidate() => state++;
}

/// App-wide Dio client. Feature repositories depend on this provider.
final dioProvider = Provider<Dio>((ref) {
  final store = ref.watch(authTokenStoreProvider);
  return DioClient.create(
    tokenStore: store,
    onUnauthorized: () {
      Future.microtask(
        () => ref.read(authSessionInvalidatorProvider.notifier).invalidate(),
      );
    },
  );
});
