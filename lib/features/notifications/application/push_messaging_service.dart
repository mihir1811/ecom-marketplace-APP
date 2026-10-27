import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/result.dart';
import '../../../core/firebase/firebase_options.dart';
import '../data/mappers/notification_mapper.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../domain/models/app_notification.dart';
import 'chat_message_alerts.dart';
import 'in_app_notification_provider.dart';
import 'notifications_provider.dart';
import 'offer_push_sync.dart';
import 'order_push_sync.dart';

final pushMessagingProvider = Provider<PushMessagingService>((ref) {
  final service = PushMessagingService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Firebase Cloud Messaging for Android and iOS.
///
/// - Background / terminated: every backend push has a `notification` block,
///   so the OS shows it on channel `gemworld_default`; a tap is routed here.
/// - Foreground: the OS stays silent and the app shows its own banner.
/// - The FCM token is sent to `POST /notifications/devices` after sign-in and
///   whenever Firebase rotates it.
class PushMessagingService {
  PushMessagingService(this._ref);

  final Ref _ref;

  static bool _firebaseReady = false;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  String? _inFlightToken;
  var _started = false;

  /// Whether FCM is available on this platform and Firebase started.
  static bool get isSupported => _firebaseReady;

  /// Call once from `main()` before `runApp`. Never throws: without Firebase
  /// the app runs normally and push stays off.
  static Future<void> initializeFirebase() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) {
      _log('push disabled on this platform');
      return;
    }
    try {
      await Firebase.initializeApp(options: options);
      _firebaseReady = true;
      _log('Firebase initialized (${options.projectId})');
    } catch (error, stack) {
      _log('Firebase init failed: $error');
      debugPrintStack(stackTrace: stack, label: '[FCM]');
    }
  }

  /// Starts foreground and tap listeners. Safe to call more than once.
  Future<void> start() async {
    if (!_firebaseReady || _started) return;
    _started = true;
    final messaging = FirebaseMessaging.instance;
    try {
      // iOS: the in-app banner replaces the system alert while open.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );
    } catch (error) {
      _log('foreground presentation options failed: $error');
    }
    _foregroundSub = FirebaseMessaging.onMessage.listen(
      _onForegroundMessage,
      onError: (Object error) => _log('onMessage error: $error'),
    );
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _onOpened(message, from: 'background'),
      onError: (Object error) => _log('onMessageOpenedApp error: $error'),
    );
    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null) _onOpened(initial, from: 'terminated');
    } catch (error) {
      _log('getInitialMessage failed: $error');
    }
  }

  /// Asks for permission, then registers this install's token with the
  /// backend. Call after sign-in and on app start with a restored session.
  Future<void> registerDevice() async {
    if (!_firebaseReady) return;
    final messaging = FirebaseMessaging.instance;
    try {
      final settings = await messaging.requestPermission();
      // Still register when denied: the OS then hides background pushes,
      // but foreground messages keep reaching onMessage and the in-app
      // banner does not need the notification permission.
      _log('permission ${settings.authorizationStatus.name}');
    } catch (error) {
      _log('permission request failed: $error');
    }

    _tokenRefreshSub ??= messaging.onTokenRefresh.listen((token) {
      _log('token refreshed');
      unawaited(_sendToken(token));
    }, onError: (Object error) => _log('onTokenRefresh error: $error'));

    try {
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        _log('no FCM token yet');
        return;
      }
      _log('token generated ${_mask(token)}');
      await _sendToken(token);
    } on FirebaseException catch (error) {
      // iOS returns `apns-token-not-set` until APNs registration finishes;
      // onTokenRefresh then delivers the token.
      _log('getToken failed: ${error.code} ${error.message}');
    } catch (error) {
      _log('getToken failed: $error');
    }
  }

  /// Stops pushes to this install. Runs before `POST /auth/logout`.
  Future<void> unregisterDevice() async {
    await stopTokenSync();
    _ref.read(inAppNotificationProvider.notifier).clear();
    await _ref.read(notificationRepositoryProvider).unregisterStoredDevice();
    _log('device unregistered');
  }

  /// Stops re-registering rotated tokens (signed out or session expired).
  Future<void> stopTokenSync() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }

  Future<void> _sendToken(String token) async {
    if (!_ref.read(authProvider).isAuthenticated) return;
    if (_inFlightToken == token) return;
    _inFlightToken = token;
    try {
      final deviceId = await _ref.read(pushDeviceStoreProvider).deviceId();
      final result = await _ref
          .read(notificationRepositoryProvider)
          .registerDevice(
            token: token,
            platform: notificationPlatform(),
            deviceId: deviceId,
          );
      switch (result) {
        case Success():
          _log('token registered ${_mask(token)}');
        case ResultFailure(:final failure):
          _log('token registration failed: ${failure.message}');
      }
    } catch (error) {
      _log('token registration failed: $error');
    } finally {
      _inFlightToken = null;
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = _toNotification(message);
    _log('message received in foreground: ${notification.type}');
    if (!_ref.read(authProvider).isAuthenticated) return;

    // Order / refund / shipment events refresh the open order screens.
    syncOrderViewsFromPush(_ref, notification);
    // Offer accepted / rejected / received refreshes the offer screens.
    syncOfferViewsFromPush(_ref, notification);

    // Keep the badge (and the inbox, when loaded) in step.
    unawaited(_ref.read(notificationUnreadCountProvider.notifier).refresh());
    if (notification.id.isNotEmpty &&
        notification.type != 'CHAT_MESSAGE' &&
        _ref.exists(notificationListProvider)) {
      _ref.read(notificationListProvider.notifier).insertFromPush(notification);
    }

    if (notification.title.isEmpty && notification.body.isEmpty) return;
    if (notification.type == 'CHAT_MESSAGE' &&
        isViewingChatWith(
          senderId: notification.data['senderId'] ?? '',
          productId: notification.data['productId'],
        )) {
      // The open conversation already shows it through the chat socket.
      return;
    }
    _ref.read(inAppNotificationProvider.notifier).show(notification);
    _log('foreground banner queued');
  }

  void _onOpened(RemoteMessage message, {required String from}) {
    final notification = _toNotification(message);
    _log('opened from $from: ${notification.type}');
    syncOrderViewsFromPush(_ref, notification);
    syncOfferViewsFromPush(_ref, notification);
    _ref.read(inAppNotificationProvider.notifier).requestOpen(notification);
  }

  static AppNotification _toNotification(RemoteMessage message) {
    final shown = message.notification;
    return NotificationMapper.fromPush(
      message.data,
      title: shown?.title,
      body: shown?.body,
      imageUrl: shown?.android?.imageUrl ?? shown?.apple?.imageUrl,
      sentTime: message.sentTime,
    );
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _openedSub?.cancel();
  }

  /// Device tokens are credentials for this install; never log them whole.
  static String _mask(String token) => token.length <= 10
      ? '***'
      : '${token.substring(0, 6)}…${token.substring(token.length - 4)}';

  static void _log(String message) {
    if (kDebugMode) debugPrint('[FCM] $message');
  }
}
