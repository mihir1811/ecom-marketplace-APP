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
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          error: true,
        ),
      );
    }

    return dio;
  }
}
