import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/push/push_logout_hook.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../domain/models/app_notification.dart';
import '../domain/repositories/notification_repository.dart';
import 'chat_message_alerts.dart';
import 'in_app_notification_provider.dart';
import 'push_messaging_service.dart';

/// Badge count for the bell. `0` when signed out.
final notificationUnreadCountProvider =
    NotifierProvider<NotificationUnreadCountNotifier, int>(
      NotificationUnreadCountNotifier.new,
    );

class NotificationUnreadCountNotifier extends Notifier<int> {
  @override
  int build() {
    final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
    if (signedIn) {
      Future.microtask(refresh);
    }
    return 0;
  }

  void setCount(int count) {
    state = count < 0 ? 0 : count;
  }

  Future<void> refresh() async {
    if (!ref.read(authProvider).isAuthenticated) {
      state = 0;
      return;
    }
    final result = await ref.read(notificationRepositoryProvider).unreadCount();
    if (result case Success(:final value)) state = value;
  }
}

class NotificationListState {
  const NotificationListState({
    this.items = const [],
    this.unreadCount = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.unreadOnly = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final int currentPage;
  final bool hasMore;
  final bool unreadOnly;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  NotificationListState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    int? currentPage,
    bool? hasMore,
    bool? unreadOnly,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final notificationListProvider =
    NotifierProvider<NotificationListNotifier, NotificationListState>(
      NotificationListNotifier.new,
    );

class NotificationListNotifier extends Notifier<NotificationListState> {
  CancelToken? _cancelToken;

  @override
  NotificationListState build() {
    ref.onDispose(() => _cancelToken?.cancel());
    final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
    if (signedIn) Future.microtask(refresh);
    return const NotificationListState(isLoading: true);
  }

  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  Future<void> refresh({bool? unreadOnly}) async {
    _cancelToken?.cancel('refresh');
    _cancelToken = CancelToken();
    final filter = unreadOnly ?? state.unreadOnly;
    final keepItems = filter == state.unreadOnly;
    state = state.copyWith(
      isLoading: true,
      unreadOnly: filter,
      items: keepItems ? state.items : const [],
      clearError: true,
    );
    final result = await _repo.list(
      page: 1,
      unreadOnly: filter,
      cancelToken: _cancelToken,
    );
    switch (result) {
      case Success(:final value):
        state = NotificationListState(
          items: value.items,
          unreadCount: value.unreadCount,
          currentPage: value.currentPage,
          hasMore: value.hasMore,
          unreadOnly: filter,
        );
        ref
            .read(notificationUnreadCountProvider.notifier)
            .setCount(value.unreadCount);
      case ResultFailure(:final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final result = await _repo.list(
      page: state.currentPage + 1,
      unreadOnly: state.unreadOnly,
    );
    switch (result) {
      case Success(:final value):
        state = state.copyWith(
          items: [...state.items, ...value.items],
          unreadCount: value.unreadCount,
          currentPage: value.currentPage,
          hasMore: value.hasMore,
          isLoadingMore: false,
        );
        ref
            .read(notificationUnreadCountProvider.notifier)
            .setCount(value.unreadCount);
      case ResultFailure(:final failure):
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        );
    }
  }

  /// Puts a foreground push at the top of a loaded inbox without refetching.
  /// No-op when that row is already listed.
  void insertFromPush(AppNotification notification) {
    if (notification.id.isEmpty || state.isLoading) return;
    if (state.items.any((item) => item.id == notification.id)) return;
    state = state.copyWith(items: [notification, ...state.items]);
  }

  Future<String?> markRead(String id) async {
    final result = await _repo.markRead(id: id);
    return switch (result) {
      Success(:final value) => () {
        state = state.copyWith(
          unreadCount: value,
          items:
              [
                    for (final item in state.items)
                      if (item.id == id)
                        item.copyWith(isRead: true, readAt: DateTime.now())
                      else
                        item,
                  ]
                  .where(
                    (item) =>
                        !state.unreadOnly || item.id != id || !item.isRead,
                  )
                  .toList(),
        );
        ref.read(notificationUnreadCountProvider.notifier).setCount(value);
        return null;
      }(),
      ResultFailure(:final failure) => failure.message,
    };
  }

  Future<String?> markAllRead() async {
    final result = await _repo.markAllRead();
    return switch (result) {
      Success(:final value) => () {
        state = state.copyWith(
          unreadCount: value,
          items: state.unreadOnly
              ? const []
              : [
                  for (final item in state.items)
                    item.copyWith(isRead: true, readAt: DateTime.now()),
                ],
          hasMore: state.unreadOnly ? false : state.hasMore,
        );
        ref.read(notificationUnreadCountProvider.notifier).setCount(value);
        return null;
      }(),
      ResultFailure(:final failure) => failure.message,
    };
  }

  Future<String?> delete(String id) async {
    final result = await _repo.delete(id: id);
    return switch (result) {
      Success(:final value) => () {
        state = state.copyWith(
          unreadCount: value,
          items: [
            for (final item in state.items)
              if (item.id != id) item,
          ],
        );
        ref.read(notificationUnreadCountProvider.notifier).setCount(value);
        return null;
      }(),
      ResultFailure(:final failure) => failure.message,
    };
  }
}

/// Starts push listeners, registers this device's FCM token after sign-in
/// and unregisters it before logout.
final notificationSessionProvider = Provider<void>((ref) {
  final push = ref.watch(pushMessagingProvider);
  unawaited(push.start());
  // Live chat messages from the socket, on every screen. `listen` keeps it
  // alive without rebuilding this session (and re-registering the device).
  ref.listen(chatMessageAlertsProvider, (_, _) {});

  PushLogoutHook.beforeLogout = push.unregisterDevice;
  ref.onDispose(() => PushLogoutHook.beforeLogout = null);

  ref.listen(authProvider.select((s) => s.isAuthenticated), (prev, next) {
    if (next) {
      unawaited(push.registerDevice());
      ref.read(notificationUnreadCountProvider.notifier).refresh();
    } else if (prev == true) {
      unawaited(push.stopTokenSync());
      ref.read(inAppNotificationProvider.notifier).clear();
      ref.read(notificationUnreadCountProvider.notifier).setCount(0);
    }
  }, fireImmediately: true);
});
