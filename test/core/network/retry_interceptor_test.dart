import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/network/retry_interceptor.dart';

/// Answers each request from [responses] in order and counts calls.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.responses);

  final List<Object> responses; // int status, or DioExceptionType to throw
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final next = responses[calls.clamp(0, responses.length - 1)];
    calls++;
    if (next is DioExceptionType) {
      throw DioException(requestOptions: options, type: next);
    }
    return ResponseBody.fromString(
      '{}',
      next as int,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_ScriptedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(RetryInterceptor(dio, baseDelay: Duration.zero));
  return dio;
}

void main() {
  test('GET retries a dropped connection, then succeeds', () async {
    final adapter = _ScriptedAdapter([
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      200,
    ]);
    final res = await _dio(adapter).get<Object?>('/diamond');
    expect(res.statusCode, 200);
    expect(adapter.calls, 3);
  });

  test('GET retries 503 at most twice', () async {
    final adapter = _ScriptedAdapter([503]);
    await expectLater(
      _dio(adapter).get<Object?>('/diamond'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.calls, 3);
  });

  test('POST is never retried (orders, payments)', () async {
    final adapter = _ScriptedAdapter([DioExceptionType.connectionError, 200]);
    await expectLater(
      _dio(adapter).post<Object?>('/orders', data: {'a': 1}),
      throwsA(isA<DioException>()),
    );
    expect(adapter.calls, 1);
  });

  test('receive timeout and 4xx are not retried', () async {
    final timeout = _ScriptedAdapter([DioExceptionType.receiveTimeout, 200]);
    await expectLater(
      _dio(timeout).get<Object?>('/slow'),
      throwsA(isA<DioException>()),
    );
    expect(timeout.calls, 1);

    final notFound = _ScriptedAdapter([404, 200]);
    await expectLater(
      _dio(notFound).get<Object?>('/missing'),
      throwsA(isA<DioException>()),
    );
    expect(notFound.calls, 1);
  });

  test('noRetry opts a GET out', () async {
    final adapter = _ScriptedAdapter([DioExceptionType.connectionError, 200]);
    await expectLater(
      _dio(adapter).get<Object?>(
        '/x',
        options: Options(extra: {RetryInterceptor.noRetryKey: true}),
      ),
      throwsA(isA<DioException>()),
    );
    expect(adapter.calls, 1);
  });

  test('a cancelled request stops retrying', () async {
    final adapter = _ScriptedAdapter([DioExceptionType.connectionError, 200]);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      RetryInterceptor(dio, baseDelay: const Duration(milliseconds: 50)),
    );
    final token = CancelToken();
    final future = dio.get<Object?>('/x', cancelToken: token);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    token.cancel('left screen');
    await expectLater(
      future,
      throwsA(
        isA<DioException>().having((e) => e.type, 'type', DioExceptionType.cancel),
      ),
    );
    expect(adapter.calls, 1);
  });
}
