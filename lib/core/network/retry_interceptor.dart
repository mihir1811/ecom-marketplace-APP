import 'dart:async';

import 'package:dio/dio.dart';

/// Retries safe requests (GET/HEAD) after transient failures, with
/// exponential backoff.
///
/// Retried: the request never reached the server (connection error / connect
/// timeout) or a gateway said "try again" (502/503/504). Never retried: any
/// write (POST/PUT/PATCH/DELETE — payments, orders), receive timeouts (the
/// server may still be working; retrying would only stack load), 4xx, and
/// cancelled requests. Opt out per call with `extra: {'noRetry': true}`.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 500),
  });

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  static const attemptKey = 'retryAttempt';
  static const noRetryKey = 'noRetry';

  static const _safeMethods = {'GET', 'HEAD'};
  static const _retryStatus = {502, 503, 504};

  /// Whether [err] is worth another try. Visible for tests.
  static bool isRetryable(DioException err) {
    final options = err.requestOptions;
    if (options.extra[noRetryKey] == true) return false;
    if (!_safeMethods.contains(options.method.toUpperCase())) return false;
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return true;
      case DioExceptionType.badResponse:
        return _retryStatus.contains(err.response?.statusCode);
      default:
        // send/receive timeouts, bad certificate, cancel, unknown, ...
        return false;
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[attemptKey] as int?) ?? 0;
    if (attempt >= maxRetries || !isRetryable(err)) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(baseDelay * (1 << attempt));

    final cancelToken = options.cancelToken;
    if (cancelToken != null && cancelToken.isCancelled) {
      handler.next(
        DioException.requestCancelled(
          requestOptions: options,
          reason: cancelToken.cancelError?.error,
        ),
      );
      return;
    }

    options.extra[attemptKey] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
