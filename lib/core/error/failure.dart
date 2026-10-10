import 'package:dio/dio.dart';

/// Sealed class hierarchy representing errors that are safe to present to users.
sealed class Failure {
  const Failure(this.message);

  /// A localized, designer-written user-facing error message.
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);

  /// Returned when a request was intentionally cancelled (stale pagination).
  static const cancelled = NetworkFailure._cancelled();

  const NetworkFailure._cancelled() : super('Request cancelled.');

  bool get isCancelled =>
      identical(this, cancelled) || message == 'Request cancelled.';

  factory NetworkFailure.fromDioException(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return NetworkFailure.cancelled;
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout => const NetworkFailure(
        'This is taking longer than expected. Please try again.',
      ),
      DioExceptionType.connectionError => const NetworkFailure(
        'You appear to be offline. Check your connection and try again.',
      ),
      _ => NetworkFailure(_messageForStatus(e.response?.statusCode)),
    };
  }

  static String _messageForStatus(int? statusCode) {
    if (statusCode == null) return 'Something went wrong. Please try again.';
    if (statusCode >= 500) {
      return 'The server encountered an error. Please try again shortly.';
    }
    if (statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    if (statusCode == 403) {
      return 'You do not have permission to access this resource.';
    }
    if (statusCode == 404) {
      return 'The requested resource was not found.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(this.debugDetail)
    : super('Something went wrong. Please try again.');

  /// Detailed internal debug information (never exposed to UI).
  final String debugDetail;
}
