import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/result.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/router/workspace_mode.dart';
import '../application/notifications_provider.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../domain/models/app_notification.dart';
import '../domain/notification_open_target.dart';

/// Marks [notification] read and opens its screen.
///
/// With [fallbackToInbox] a notification without a matching screen opens the
/// inbox (used for push taps); otherwise it stays put. Returns the error
/// message when marking it read failed.
Future<String?> openNotification(
  BuildContext context,
  WidgetRef ref,
  AppNotification notification, {
  bool fallbackToInbox = false,
}) async {
  final auth = ref.read(authProvider);
  String? error;
  if (notification.id.isNotEmpty && auth.isAuthenticated) {
    error = await _markRead(ref, notification.id);
  }
  if (!context.mounted) return error;

  final target = notificationOpenTarget(notification, isSeller: auth.isSeller);
  switch (target) {
    case NotificationStay():
      if (fallbackToInbox && auth.isAuthenticated) {
        // Stay on the side the user is on.
        context.switchToRoute(
          notificationsRouteFor(
            auth.isSeller ? currentWorkspace(context) : AppWorkspace.buyer,
          ),
        );
      }
    case NotificationInApp(:final route):
      context.switchToRoute(route);
    case NotificationExternal(:final url):
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }
  return error;
}

/// Uses the inbox notifier when the inbox is loaded so its row updates too;
/// otherwise patches only the badge, without loading the inbox.
Future<String?> _markRead(WidgetRef ref, String id) async {
  if (ref.exists(notificationListProvider)) {
    return ref.read(notificationListProvider.notifier).markRead(id);
  }
  final result = await ref
      .read(notificationRepositoryProvider)
      .markRead(id: id);
  switch (result) {
    case Success(:final value):
      ref.read(notificationUnreadCountProvider.notifier).setCount(value);
      return null;
    case ResultFailure(:final failure):
      return failure.message;
  }
}
