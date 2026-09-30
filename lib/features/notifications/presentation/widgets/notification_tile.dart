import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/app_notification.dart';

/// One inbox row. Unread rows use a stronger surface and a bronze dot.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final title = notification.title.trim().isEmpty
        ? 'Notification'
        : notification.title;

    return Semantics(
      button: true,
      label: unread
          ? 'Unread. $title. ${notification.body}'
          : '$title. ${notification.body}',
      child: Material(
        color: unread ? AppColors.surface(context) : AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.r16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Leading(notification: notification, unread: unread),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label.copyWith(
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        if (notification.body.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            notification.body,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          formatNotificationTime(notification.createdAt),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.notification, required this.unread});

  final AppNotification notification;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final imageUrl = notification.imageUrl;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.r12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => _IconBubble(type: notification.type),
            ),
          )
        else
          _IconBubble(type: notification.type),
        if (unread)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.bronze,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bg(context), width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
      ),
      child: Icon(_iconFor(type), size: 22, color: AppColors.bronze),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'CHAT_MESSAGE' => Icons.chat_bubble_outline,
      'ORDER_ACCEPTED' || 'ORDER_REJECTED' => Icons.local_shipping_outlined,
      'AUCTION_OUTBID' ||
      'AUCTION_WON' ||
      'AUCTION_NEW_BID' ||
      'AUCTION_ENDED_SELLER' => Icons.gavel_outlined,
      'OFFER_RECEIVED' ||
      'OFFER_ACCEPTED' ||
      'OFFER_REJECTED' => Icons.local_offer_outlined,
      'HELP_CENTER_ANSWERED' => Icons.help_outline,
      'ADMIN_BROADCAST' => Icons.campaign_outlined,
      _ => Icons.notifications_none,
    };
  }
}

/// Short relative time for inbox rows.
String formatNotificationTime(DateTime createdAt) {
  final local = createdAt.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${local.day} ${months[local.month - 1]}';
}
