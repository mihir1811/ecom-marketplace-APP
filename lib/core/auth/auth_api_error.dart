import 'package:dio/dio.dart';

import '../error/failure.dart';

/// Maps auth/API Dio errors to user-safe [Failure]s, preferring server `message`.
abstract final class AuthApiError {
  static Failure fromDio(DioException e) {
    final status = e.response?.statusCode;
    final serverMessage = _extractMessage(e.response?.data);

    if (status == 401) {
      return AuthFailure(
        serverMessage ?? 'Your session has expired. Please sign in again.',
      );
    }
    if (status == 400 || status == 422) {
      return ValidationFailure(
        serverMessage ?? 'Please check your details and try again.',
      );
    }
    if (status == 404) {
      return const NetworkFailure(
        'Account deletion is not available on the server yet. '
        'Please try again later or contact support.',
      );
    }
    if (serverMessage != null && serverMessage.isNotEmpty) {
      if (status != null && status >= 500) {
        return NetworkFailure(serverMessage);
      }
      return AuthFailure(serverMessage);
    }
    return NetworkFailure.fromDioException(e);
  }

  static String? _extractMessage(Object? data) {
    if (data is! Map) return null;
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    if (message is List) {
      final parts = message
          .whereType<String>()
          .map((m) => m.trim())
          .where((m) => m.isNotEmpty)
          .toList();
      if (parts.isEmpty) return null;
      return parts.join('\n');
    }
    return null;
  }
}
