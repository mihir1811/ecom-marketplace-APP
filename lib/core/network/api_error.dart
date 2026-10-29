import 'package:dio/dio.dart';

import '../error/failure.dart';
import 'validation_message_formatter.dart';

/// Maps Dio errors to user-safe [Failure]s, preferring server `message`.
abstract final class ApiError {
  static Failure fromDio(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return NetworkFailure.cancelled;
    }

    final status = e.response?.statusCode;
    final serverMessage = extractMessage(e.response?.data);

    if (status == 401) {
      return AuthFailure(
        ValidationMessageFormatter.humanize(
          serverMessage ?? 'Your session has expired. Please sign in again.',
        ),
      );
    }
    if (status == 400 || status == 422) {
      return ValidationFailure(
        ValidationMessageFormatter.humanize(
          serverMessage ?? 'Please check your details and try again.',
        ),
        code: extractCode(e.response?.data),
      );
    }
    if (serverMessage != null && serverMessage.isNotEmpty) {
      final friendly = ValidationMessageFormatter.humanize(serverMessage);
      if (status != null && status >= 500) {
        return NetworkFailure(friendly);
      }
      if (status == 403) {
        return AuthFailure(friendly);
      }
      if (status == 404) {
        return NetworkFailure(friendly);
      }
      return ValidationFailure(friendly);
    }
    return NetworkFailure.fromDioException(e);
  }

  static String? extractCode(Object? data) {
    if (data is! Map) return null;
    final code = data['code'];
    return code is String && code.trim().isNotEmpty ? code.trim() : null;
  }

  static String? extractMessage(Object? data) {
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
