import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_token_store.dart';
import '../auth/jwt_utils.dart';

/// Attaches Bearer token and clears session storage on HTTP 401.
///
/// Token lookup failures must never abort the request — catalog endpoints are
/// public and must keep working when secure storage is unavailable (e.g. web
/// `OperationError` from flutter_secure_storage).
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required AuthTokenStore this._tokenStore,
    void Function()? this._onUnauthorized,
  });

  final AuthTokenStore _tokenStore;
  final void Function()? _onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Allow callers (e.g. reset-password) to supply their own Bearer token.
      final existing = options.headers['Authorization'];
      if (existing == null || existing.toString().trim().isEmpty) {
        final token = await _tokenStore.readAccessToken();
        if (token != null && token.isNotEmpty) {
          if (JwtUtils.isExpired(token)) {
            await _tokenStore.clear();
            _onUnauthorized?.call();
          } else {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
      }
    } catch (e, st) {
      assert(() {
        debugPrint('AuthInterceptor.onRequest token read failed: $e\n$st');
        return true;
      }());
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final isAuthPublic = path.contains('/auth/login') ||
          path.contains('/auth/register') ||
          path.contains('/auth/verify-otp') ||
          path.contains('/auth/resend-otp') ||
          path.contains('/auth/forget-password') ||
          path.contains('/auth/reset-password') ||
          // Public share lookup — never treat as a session expiry.
          path.contains('/product-share/');
      if (!isAuthPublic) {
        try {
          await _tokenStore.clear();
        } catch (_) {
          // Ignore storage clear failures.
        }
        _onUnauthorized?.call();
      }
    }
    handler.next(err);
  }
}
