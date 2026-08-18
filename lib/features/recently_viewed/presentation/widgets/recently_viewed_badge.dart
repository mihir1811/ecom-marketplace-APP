import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/recently_viewed_providers.dart';

/// "Viewed" chip shown on listing card images the user has already opened.
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

    return Padding(
      padding: padding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bronze,
          borderRadius: BorderRadius.circular(AppSpacing.r4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: 3,
          ),
          child: Text(
            'Viewed',
            style: AppTypography.caption.copyWith(
              color: AppColors.warmWhite,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pins [RecentlyViewedBadge] to the bottom-left of a listing card image stack.
class RecentlyViewedImageBadge extends StatelessWidget {
  const RecentlyViewedImageBadge({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: AppSpacing.s12,
      left: AppSpacing.s12,
      child: RecentlyViewedBadge(productId: productId),
    );
  }
}
