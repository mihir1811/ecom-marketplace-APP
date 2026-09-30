import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/notification_page.dart';
import '../../domain/repositories/notification_repository.dart';
import '../mappers/notification_mapper.dart';
import '../push_device_store.dart';

final pushDeviceStoreProvider = Provider<PushDeviceStore>(
  (ref) => PushDeviceStore(),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(pushDeviceStoreProvider),
  ),
);

/// `ANDROID` | `IOS` | `WEB` for `POST /notifications/devices`.
String notificationPlatform() {
  if (kIsWeb) return 'WEB';
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'IOS',
    TargetPlatform.android => 'ANDROID',
    _ => 'WEB',
  };
}

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._dio, this._devices);

  final Dio _dio;
  final PushDeviceStore _devices;

  @override
  Future<Result<NotificationPage, Failure>> list({
    required int page,
    int limit = 20,
    bool unreadOnly = false,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: {
          'page': page < 1 ? 1 : page,
          'limit': limit.clamp(1, 100),
          if (unreadOnly) 'unreadOnly': true,
        },
        cancelToken: cancelToken,
      );
      return Result.success(
        NotificationMapper.pageFromEnvelope(
          response.data,
          page: page,
          limit: limit,
        ),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<int, Failure>> unreadCount({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.notificationsUnreadCount,
        cancelToken: cancelToken,
      );
      return Result.success(
        NotificationMapper.unreadCountFromEnvelope(response.data),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<int, Failure>> markRead({
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.notificationRead(id),
        cancelToken: cancelToken,
      );
      return Result.success(
        NotificationMapper.unreadCountFromEnvelope(response.data),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<int, Failure>> markAllRead({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.notificationsReadAll,
        cancelToken: cancelToken,
      );
      return Result.success(
        NotificationMapper.unreadCountFromEnvelope(response.data),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<int, Failure>> delete({
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.notificationById(id),
        cancelToken: cancelToken,
      );
      return Result.success(
        NotificationMapper.unreadCountFromEnvelope(response.data),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> registerDevice({
    required String token,
    required String platform,
    required String deviceId,
    String? deviceName,
    String? appVersion,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.notificationsDevices,
        data: {
          'token': token,
          'tokenType': 'FCM_TOKEN',
          'platform': platform,
          'deviceId': deviceId,
          if (deviceName != null && deviceName.isNotEmpty)
            'deviceName': deviceName,
          if (appVersion != null && appVersion.isNotEmpty)
            'appVersion': appVersion,
        },
      );
      await _devices.saveToken(token);
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> unregisterDevice({
    required String token,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.notificationsDevicesUnregister,
        data: {'token': token},
        options: Options(extra: const {'skipAuth': true}),
      );
      await _devices.clearToken();
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  /// Re-sends a stored FCM token after login or app start. No-op without one.
  @override
  Future<Result<void, Failure>> registerStoredDevice() async {
    final token = await _devices.readToken();
    if (token == null || token.isEmpty) return Result.success(null);
    final deviceId = await _devices.deviceId();
    return registerDevice(
      token: token,
      platform: notificationPlatform(),
      deviceId: deviceId,
    );
  }

  /// Called before `POST /auth/logout`. No-op when this install was never registered.
  @override
  Future<void> unregisterStoredDevice() async {
    final token = await _devices.readToken();
    if (token == null || token.isEmpty) return;
    await unregisterDevice(token: token);
  }
}
