import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/recently_viewed_providers.dart';

/// Availability status shown on listing card images.
/// Color-coded: green=Available, yellow=On Hold/Memo, red=Sold/Unavailable.
class AvailabilityStatusBadge extends StatelessWidget {
  const AvailabilityStatusBadge({
    required this.status,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final String? status;
  final EdgeInsetsGeometry padding;

  Color _statusColor(BuildContext context) {
    final label = status?.toLowerCase() ?? '';
    if (label == 'available' || label == 'yes') return AppColors.success;
    if (label == 'sold' || label.contains('unavailable')) return AppColors.error;
    if (label.contains('hold') || label.contains('memo')) {
      return AppColors.warning;
    }
    return AppColors.textMuted(context);
  }

  String get _displayLabel {
    final label = status?.toLowerCase() ?? '';
    if (label == 'yes') return 'Available';
    if (label == 'available') return 'Available';
    if (label == 'hold' || label == 'on hold') return 'On Hold';
    if (label == 'memo' || label == 'on memo') return 'On Memo';
    if (label == 'sold') return 'Sold';
    if (label.contains('unavailable')) return 'Unavailable';
    return status ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (status == null || status!.isEmpty) return const SizedBox.shrink();

    final color = _statusColor(context);
    final dark = AppColors.isDark(context);

    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: dark
              ? color.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.r4),
          border: Border.all(
            color: color.withValues(alpha: dark ? 0.5 : 0.35),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _displayLabel,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small "recently viewed" indicator dot for listing cards.
class RecentlyViewedBadge extends ConsumerWidget {
  const RecentlyViewedBadge({
    required this.productId,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final String productId;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewed = ref.watch(isRecentlyViewedProvider(productId));
    if (!viewed) return const SizedBox.shrink();

    final dark = AppColors.isDark(context);
    return Padding(
      padding: padding,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.bronze,
          shape: BoxShape.circle,
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Pins [RecentlyViewedBadge] to the top-left of a listing card image stack.
class RecentlyViewedImageBadge extends StatelessWidget {
  const RecentlyViewedImageBadge({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.s12,
      left: AppSpacing.s12,
      child: RecentlyViewedBadge(productId: productId),
    );
  }
}
