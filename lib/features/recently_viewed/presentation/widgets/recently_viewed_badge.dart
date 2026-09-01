import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/recently_viewed_providers.dart';

/// Availability status dot for listing card images.
/// Color-coded: green=Available, yellow=On Hold/Memo, red=Sold/Unavailable.
class AvailabilityStatusBadge extends StatelessWidget {
  const AvailabilityStatusBadge({
    required this.status,
    this.padding = EdgeInsets.zero,
    this.dotOnly = true,
    super.key,
  });

  final String? status;
  final EdgeInsetsGeometry padding;
  final bool dotOnly;

  static Color statusColor(BuildContext context, String? status) {
    final label = status?.toLowerCase() ?? '';
    if (label == 'available' || label == 'yes') return AppColors.success;
    if (label == 'sold' || label.contains('unavailable')) {
      return AppColors.error;
    }
    if (label.contains('hold') || label.contains('memo')) {
      return AppColors.warning;
    }
    return AppColors.textMuted(context);
  }

  Color _statusColor(BuildContext context) => statusColor(context, status);

  String _displayLabel(BuildContext context) {
    final label = status?.toLowerCase() ?? '';
    if (label == 'yes' || label == 'available') {
      return context.tr(AccountCommerceL10n.available);
    }
    if (label == 'hold' || label == 'on hold') {
      return context.tr(AccountCommerceL10n.onHold);
    }
    if (label == 'memo' || label == 'on memo') {
      return context.tr(AccountCommerceL10n.onMemo);
    }
    if (label == 'sold') return context.tr(AccountCommerceL10n.sold);
    if (label.contains('unavailable')) {
      return context.tr(AccountCommerceL10n.unavailable);
    }
    return status ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (status == null || status!.isEmpty) return const SizedBox.shrink();

    final color = _statusColor(context);
    final ring = AppColors.isDark(context)
        ? Colors.white.withValues(alpha: 0.92)
        : Colors.white;

    if (dotOnly) {
      return Padding(
        padding: padding,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ring,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 0.5,
              ),
            ),
          ),
        ),
      );
    }

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
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              _displayLabel(context),
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
