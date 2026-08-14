import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_token_store.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';

/// Builds the shared [Dio] instance used by feature repositories.
abstract final class DioClient {
  static Dio create({
    AuthTokenStore? tokenStore,
    void Function()? onUnauthorized,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    if (tokenStore != null) {
      dio.interceptors.add(
        AuthInterceptor(
          tokenStore: tokenStore,
          onUnauthorized: onUnauthorized,
        ),
      );
    }

    if (kDebugMode) {
      // One line per call (LogInterceptor prints request + response = looks 2x).
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('→ ${options.method} ${options.uri}');
            handler.next(options);
          },
          onError: (err, handler) {
            final cancelled = CancelToken.isCancel(err);
            if (!cancelled) {
              debugPrint(
                '✖ ${err.requestOptions.method} ${err.requestOptions.uri} '
                '(${err.response?.statusCode ?? err.type.name})',
              );
            }
            handler.next(err);
          },
        ),
      );
    }

    return dio;
  }
}
