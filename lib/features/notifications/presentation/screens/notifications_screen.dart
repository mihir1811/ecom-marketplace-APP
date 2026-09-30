import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../application/notifications_provider.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/notification_open_target.dart';
import '../widgets/notification_tile.dart';

/// Paginated notifications inbox for buyer and seller shells.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(notificationListProvider.notifier).loadMore();
    }
  }

  Future<void> _open(AppNotification notification) async {
    final error = await ref
        .read(notificationListProvider.notifier)
        .markRead(notification.id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
    final isSeller = ref.read(authProvider).isSeller;
    final target = notificationOpenTarget(notification, isSeller: isSeller);
    if (!mounted) return;
    switch (target) {
      case NotificationStay():
        break;
      case NotificationInApp(:final route):
        context.switchToRoute(route);
      case NotificationExternal(:final url):
        await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Notifications',
                  style: AppTypography.title.copyWith(
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              TextButton(
                onPressed: state.unreadCount == 0
                    ? null
                    : () async {
                        final error = await ref
                            .read(notificationListProvider.notifier)
                            .markAllRead();
                        if (!context.mounted || error == null) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
                      },
                child: const Text('Mark all read'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Wrap(
            spacing: AppSpacing.s8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: !state.unreadOnly,
                onSelected: (_) => ref
                    .read(notificationListProvider.notifier)
                    .refresh(unreadOnly: false),
              ),
              ChoiceChip(
                label: Text(
                  state.unreadCount > 0
                      ? 'Unread (${state.unreadCount})'
                      : 'Unread',
                ),
                selected: state.unreadOnly,
                onSelected: (_) => ref
                    .read(notificationListProvider.notifier)
                    .refresh(unreadOnly: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Expanded(child: _body(state)),
      ],
    );
  }

  Widget _body(NotificationListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return CatalogEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Couldn’t load notifications',
        message: state.errorMessage!,
        actionLabel: 'Try again',
        onAction: () => ref.read(notificationListProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return CatalogEmptyState(
        title: state.unreadOnly
            ? 'No unread notifications'
            : 'You’re all caught up',
        message: state.unreadOnly
            ? 'New orders, offers, and replies will show up here.'
            : 'Chats, orders, auctions, offers, and help replies land here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s8),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = state.items[index];
          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.s16),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppSpacing.r16),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) async {
              final error = await ref
                  .read(notificationListProvider.notifier)
                  .delete(item.id);
              if (!context.mounted || error == null) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error)));
              ref.read(notificationListProvider.notifier).refresh();
            },
            child: NotificationTile(
              notification: item,
              onTap: () => _open(item),
            ),
          );
        },
      ),
    );
  }
}
