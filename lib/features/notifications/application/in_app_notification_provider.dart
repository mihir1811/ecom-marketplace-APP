import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/app_notification.dart';

/// Foreground push banner queue plus a tap waiting for the app to be ready.
class InAppNotificationState {
  const InAppNotificationState({
    this.current,
    this.queue = const [],
    this.pendingOpen,
  });

  /// Banner on screen, or `null` when none is shown.
  final AppNotification? current;

  /// Banners waiting for [current] to close, oldest first.
  final List<AppNotification> queue;

  /// A tapped push that still has to be routed (e.g. cold start before the
  /// session is restored).
  final AppNotification? pendingOpen;
}

final inAppNotificationProvider =
    NotifierProvider<InAppNotificationController, InAppNotificationState>(
      InAppNotificationController.new,
    );

/// Shows one banner at a time. Duplicate deliveries are dropped and pushes
/// for the same thread (one chat, one auction) collapse to the newest.
///
/// One event can reach the app twice (a chat message arrives on the socket
/// and as an FCM push), possibly after the first banner was closed, so the
/// ids of recently shown events are remembered.
class InAppNotificationController extends Notifier<InAppNotificationState> {
  static const maxQueued = 3;
  static const _recentLimit = 64;

  final _recent = <String>{};

  @override
  InAppNotificationState build() => const InAppNotificationState();

  void show(AppNotification notification) {
    final keys = _deliveryKeys(notification);
    if (keys.any(_recent.contains)) return;
    _recent.addAll(keys);
    while (_recent.length > _recentLimit) {
      _recent.remove(_recent.first);
    }

    final current = state.current;
    if (current == null) {
      _set(current: notification, queue: state.queue);
      return;
    }
    if (_sameNotification(current, notification)) return;
    if (_sameThread(current, notification)) {
      // Replace in place; the host restarts the dismiss timer.
      _set(current: notification, queue: state.queue);
      return;
    }
    if (state.queue.any((queued) => _sameNotification(queued, notification))) {
      return;
    }
    var queue = [
      for (final queued in state.queue)
        if (!_sameThread(queued, notification)) queued,
      notification,
    ];
    if (queue.length > maxQueued) {
      queue = queue.sublist(queue.length - maxQueued);
    }
    _set(current: current, queue: queue);
  }

  /// Closes the banner on screen and moves to the next one, if any.
  void dismiss() {
    final queue = state.queue;
    if (queue.isEmpty) {
      _set(current: null, queue: const []);
      return;
    }
    _set(current: queue.first, queue: queue.sublist(1));
  }

  /// Drops every banner, e.g. after sign-out.
  void clear() {
    _recent.clear();
    state = const InAppNotificationState();
  }

  void requestOpen(AppNotification notification) {
    state = InAppNotificationState(
      current: state.current,
      queue: state.queue,
      pendingOpen: notification,
    );
  }

  /// Returns and clears the pending tap.
  AppNotification? takePendingOpen() {
    final pending = state.pendingOpen;
    if (pending == null) return null;
    state = InAppNotificationState(current: state.current, queue: state.queue);
    return pending;
  }

  void _set({
    required AppNotification? current,
    required List<AppNotification> queue,
  }) {
    state = InAppNotificationState(
      current: current,
      queue: queue,
      pendingOpen: state.pendingOpen,
    );
  }

  static bool _sameNotification(AppNotification a, AppNotification b) {
    if (identical(a, b)) return true;
    final keys = _deliveryKeys(a);
    return _deliveryKeys(b).any(keys.contains);
  }

  /// Inbox row id and, for chats, the message id (the socket copy of a
  /// message has no inbox row).
  static Set<String> _deliveryKeys(AppNotification n) {
    final messageId = n.data['messageId'] ?? '';
    return {
      if (n.id.isNotEmpty) 'id:${n.id}',
      if (messageId.isNotEmpty) 'message:$messageId',
    };
  }

  static bool _sameThread(AppNotification a, AppNotification b) {
    final thread = b.data['threadId'] ?? '';
    return thread.isNotEmpty && a.data['threadId'] == thread;
  }
}
