import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_token_store.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';
import 'retry_interceptor.dart';

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

    // Release builds talk to the API over HTTPS only. dart:io does not apply
    // Android's network security config, so enforce it here as well.
    if (kReleaseMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.uri.scheme != 'https') {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  error: 'Blocked insecure request',
                ),
              );
              return;
            }
            handler.next(options);
          },
        ),
      );
    }

    if (tokenStore != null) {
      dio.interceptors.add(
        AuthInterceptor(tokenStore: tokenStore, onUnauthorized: onUnauthorized),
      );
    }

    dio.interceptors.add(RetryInterceptor(dio));

    if (!kReleaseMode) {
      dio.interceptors.add(_RequestMetricsInterceptor());
    }

    return dio;
  }
}

/// Debug/profile only: one line per call with status, duration and size.
/// Never added to release builds.
class _RequestMetricsInterceptor extends Interceptor {
  static const _startKey = 'metricsStart';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] ??= Stopwatch()..start();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log(response.requestOptions, response.statusCode, response.headers);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!CancelToken.isCancel(err)) {
      _log(
        err.requestOptions,
        err.response?.statusCode,
        err.response?.headers,
        failure: err.type.name,
      );
    }
    handler.next(err);
  }

  void _log(
    RequestOptions options,
    int? status,
    Headers? headers, {
    String? failure,
  }) {
    final watch = options.extra[_startKey];
    final ms = watch is Stopwatch ? watch.elapsedMilliseconds : -1;
    final bytes = headers?.value(Headers.contentLengthHeader) ?? '?';
    final retry = options.extra[RetryInterceptor.attemptKey];
    debugPrint(
      '${failure == null ? '←' : '✖'} ${options.method} ${options.uri.path} '
      '${status ?? failure} ${ms}ms ${bytes}B'
      '${retry == null ? '' : ' retry#$retry'}',
    );
  }
}
