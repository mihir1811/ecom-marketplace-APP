import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../application/recently_viewed_providers.dart';

/// Marketplace card shell that highlights products in the user's recently viewed set.
class RecentlyViewedCardShell extends ConsumerWidget {
  const RecentlyViewedCardShell({
    required this.productId,
    required this.child,
    this.onTap,
    this.borderRadius = AppSpacing.r12,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final String productId;
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep IDs warm while listings are on screen.
    ref.watch(recentlyViewedIdsProvider);
    final viewed = ref.watch(isRecentlyViewedProvider(productId));

    return MarketplaceProductCardShell(
      onTap: onTap,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      boxShadow: boxShadow,
      clipBehavior: clipBehavior,
      isRecentlyViewed: viewed,
      child: child,
    );
  }
}
