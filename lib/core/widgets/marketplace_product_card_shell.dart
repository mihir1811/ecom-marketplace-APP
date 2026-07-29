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
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ?? AppShadows.cardLight,
      ),
      child: Material(
        color: backgroundColor ?? AppColors.warmWhite,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: borderColor ?? AppColors.warmBorder),
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
