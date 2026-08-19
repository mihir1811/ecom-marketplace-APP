import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// Shared chrome for marketplace product cards (surface, border, radius, shadow).
class MarketplaceProductCardShell extends StatelessWidget {
  const MarketplaceProductCardShell({
    required this.child,
    this.onTap,
    this.borderRadius = AppSpacing.r12,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
    this.isRecentlyViewed = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;
  final bool isRecentlyViewed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final resolvedBorder = borderColor ?? AppColors.border(context);
    final resolvedBg = isRecentlyViewed
        ? AppColors.card(context)
        : (backgroundColor ?? AppColors.card(context));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ?? (AppColors.isDark(context) ? AppShadows.none : AppShadows.cardLight),
      ),
      child: Material(
        color: resolvedBg,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: isRecentlyViewed ? Colors.transparent : resolvedBorder,
          ),
        ),
        clipBehavior: clipBehavior,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: child,
        ),
      ),
    );
  }
}
