import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/notification_page.dart';

/// Inbox and device registration for push notifications.
abstract class NotificationRepository {
  Future<Result<NotificationPage, Failure>> list({
    required int page,
    int limit = 20,
    bool unreadOnly = false,
    CancelToken? cancelToken,
  });

  Future<Result<int, Failure>> unreadCount({CancelToken? cancelToken});

  Future<Result<int, Failure>> markRead({
    required String id,
    CancelToken? cancelToken,
  });

  Future<Result<int, Failure>> markAllRead({CancelToken? cancelToken});

  Future<Result<int, Failure>> delete({
    required String id,
    CancelToken? cancelToken,
  });

  /// Registers or refreshes this install. Safe to call repeatedly.
  Future<Result<void, Failure>> registerDevice({
    required String token,
    required String platform,
    required String deviceId,
    String? deviceName,
    String? appVersion,
  });

  /// Stops pushes for [token]. Does not send an auth header.
  Future<Result<void, Failure>> unregisterDevice({required String token});

  /// Unregisters the saved token before logout. No-op when none is stored.
  Future<void> unregisterStoredDevice();
}
