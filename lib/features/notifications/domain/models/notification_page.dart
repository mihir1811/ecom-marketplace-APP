import 'app_notification.dart';

/// One page of the inbox plus the badge count returned with it.
class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.hasMore,
    required this.unreadCount,
  });

  final List<AppNotification> items;
  final int total;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final bool hasMore;
  final int unreadCount;
}
