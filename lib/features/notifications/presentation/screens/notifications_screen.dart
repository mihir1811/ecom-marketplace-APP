import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/notifications_provider.dart';
import '../../domain/models/app_notification.dart';
import '../open_notification.dart';
import '../widgets/notification_tile.dart'
    show formatNotificationTime, notificationTypeIcon;

AtelierTone _toneFor(String type) {
  if (type == 'CHAT_MESSAGE') return AtelierTone.sapphire;
  if (type.startsWith('ORDER_')) return AtelierTone.emerald;
  if (type.startsWith('AUCTION_')) return AtelierTone.amber;
  if (type.startsWith('OFFER_')) return AtelierTone.gold;
  if (type == 'ADMIN_BROADCAST') return AtelierTone.gold;
  return AtelierTone.neutral;
}

String _bucket(DateTime createdAt) {
  final d = createdAt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return 'This week';
  return 'Earlier';
}

enum _TileAction { open, delete }

/// Notifications inbox shared by the buyer and seller shells: unread
/// first-class, grouped by recency, swipe or menu to delete, mark all
/// read. Opening a notification stays on the side the user is on.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scroll = ScrollController();

  /// Swiped-away rows are hidden at once (the API removes them on success),
  /// so a dismissed tile never lingers in the tree.
  final _hidden = <String>{};

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
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final error = await openNotification(context, ref, notification);
    if (error != null) {
      showAtelierToastOn(messenger, palette, error, tone: AtelierTone.ruby);
    }
  }

  Future<void> _delete(AppNotification item) async {
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    setState(() => _hidden.add(item.id));
    final error = await ref
        .read(notificationListProvider.notifier)
        .delete(item.id);
    if (!mounted) return;
    setState(() => _hidden.remove(item.id));
    if (error == null) return;
    showAtelierToastOn(messenger, palette, error, tone: AtelierTone.ruby);
    ref.read(notificationListProvider.notifier).refresh();
  }

  Future<void> _markAllRead() async {
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    AppHaptics.selection();
    final error = await ref
        .read(notificationListProvider.notifier)
        .markAllRead();
    if (error != null) {
      showAtelierToastOn(messenger, palette, error, tone: AtelierTone.ruby);
    } else {
      showAtelierToastOn(
        messenger,
        palette,
        'All caught up',
        tone: AtelierTone.emerald,
      );
    }
  }

  Future<void> _actions(AppNotification item) async {
    final action = await showAtelierOptions<_TileAction>(
      context: context,
      title: item.title.trim().isEmpty ? 'Notification' : item.title,
      options: const [
        AtelierOption(
          value: _TileAction.open,
          label: 'Open',
          icon: Icons.open_in_new_rounded,
        ),
        AtelierOption(
          value: _TileAction.delete,
          label: 'Delete',
          icon: Icons.delete_outline_rounded,
          destructive: true,
        ),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case _TileAction.open:
        await _open(item);
      case _TileAction.delete:
        await _delete(item);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final state = ref.watch(notificationListProvider);
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Reveal(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: AtelierMotion.base,
                            child: Text(
                              state.unreadCount == 0
                                  ? 'You’re all caught up'
                                  : '${state.unreadCount} unread',
                              key: ValueKey(state.unreadCount),
                              style: AtelierType.display(p.ink, size: 28),
                            ),
                          ),
                        ),
                        AtelierButton(
                          label: 'Mark all read',
                          icon: Icons.done_all_rounded,
                          compact: true,
                          variant: AtelierButtonVariant.secondary,
                          onPressed: state.unreadCount == 0
                              ? null
                              : _markAllRead,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AtelierSpace.s16),
                  Reveal(
                    index: 1,
                    child: AtelierSegmented<bool>(
                      expand: true,
                      segments: [
                        const AtelierSegment(value: false, label: 'All'),
                        AtelierSegment(
                          value: true,
                          label: 'Unread',
                          count: state.unreadCount > 0
                              ? state.unreadCount
                              : null,
                        ),
                      ],
                      selected: state.unreadOnly,
                      onChanged: (unread) => ref
                          .read(notificationListProvider.notifier)
                          .refresh(unreadOnly: unread),
                    ),
                  ),
                  const SizedBox(height: AtelierSpace.s8),
                  Text(
                    'Swipe left on a notification to delete it.',
                    style: AtelierType.caption(p.muted, size: 11.5),
                  ),
                  const SizedBox(height: AtelierSpace.s8),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: AtelierMotion.base,
                child: KeyedSubtree(
                  key: ValueKey(state.unreadOnly),
                  child: _body(state, gutter),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(NotificationListState state, double gutter) {
    final p = context.atelier;
    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
        children: const [AtelierSkeletonList(count: 6, height: 84)],
      );
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return ListView(
        children: [
          AtelierErrorState(
            title: 'Couldn’t load notifications',
            message: state.errorMessage!,
            onRetry: () =>
                ref.read(notificationListProvider.notifier).refresh(),
          ),
        ],
      );
    }
    if (state.items.isEmpty) {
      return RefreshIndicator(
        color: p.gold,
        onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AtelierEmptyState(
              icon: Icons.notifications_none_rounded,
              title: state.unreadOnly
                  ? 'No unread notifications'
                  : 'You’re all caught up',
              message: state.unreadOnly
                  ? 'New orders, offers, and replies will show up here.'
                  : 'Chats, orders, auctions, offers, and help replies land here.',
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[];
    String? last;
    var i = 0;
    for (final item in state.items) {
      if (_hidden.contains(item.id)) continue;
      final bucket = _bucket(item.createdAt);
      if (bucket != last) {
        rows.add(
          Padding(
            padding: EdgeInsets.only(top: last == null ? 4 : 18, bottom: 8),
            child: Text(
              bucket.toUpperCase(),
              style: AtelierType.overline(p.muted),
            ),
          ),
        );
        last = bucket;
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Reveal(
            key: ValueKey(item.id),
            index: i < 10 ? i : 0,
            child: _DismissibleTile(
              item: item,
              onOpen: () => _open(item),
              onMore: () => _actions(item),
              onDelete: () => _delete(item),
            ),
          ),
        ),
      );
      i++;
    }
    if (state.isLoadingMore) {
      rows.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: p.gold),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: p.gold,
      backgroundColor: p.surface,
      onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 32),
        children: rows,
      ),
    );
  }
}

class _DismissibleTile extends StatelessWidget {
  const _DismissibleTile({
    required this.item,
    required this.onOpen,
    required this.onMore,
    required this.onDelete,
  });

  final AppNotification item;
  final VoidCallback onOpen;
  final VoidCallback onMore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Dismissible(
      key: ValueKey('dismiss-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: p.ruby,
          borderRadius: BorderRadius.circular(AtelierRadius.md),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white),
          ],
        ),
      ),
      onDismissed: (_) {
        AppHaptics.medium();
        onDelete();
      },
      child: _NotificationCard(item: item, onTap: onOpen, onMore: onMore),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.onMore,
  });

  final AppNotification item;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final unread = !item.isRead;
    final title = item.title.trim().isEmpty ? 'Notification' : item.title;
    final tone = _toneFor(item.type);

    return Pressable(
      onTap: onTap,
      onLongPress: onMore,
      semanticLabel: unread
          ? 'Unread. $title. ${item.body}'
          : '$title. ${item.body}',
      child: AnimatedContainer(
        duration: AtelierMotion.base,
        padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
        decoration: BoxDecoration(
          color: unread ? p.raised : p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.md),
          border: Border.all(
            color: unread ? p.gold.withValues(alpha: 0.35) : p.hairline,
          ),
          boxShadow: unread ? p.softShadow : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                if (item.imageUrl != null)
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => AtelierIconBadge(
                        icon: notificationTypeIcon(item.type),
                        tone: tone,
                      ),
                    ),
                  )
                else
                  AtelierIconBadge(
                    icon: notificationTypeIcon(item.type),
                    tone: tone,
                  ),
                if (unread)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: p.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.raised, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.label(
                            p.ink,
                            size: 14,
                            weight: unread ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatNotificationTime(item.createdAt),
                        style: AtelierType.caption(
                          unread ? p.gold : p.muted,
                          size: 11,
                        ),
                      ),
                    ],
                  ),
                  if (item.body.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.body(p.inkSoft, size: 13),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'More',
              visualDensity: VisualDensity.compact,
              onPressed: onMore,
              icon: Icon(Icons.more_vert_rounded, size: 18, color: p.muted),
            ),
          ],
        ),
      ),
    );
  }
}
