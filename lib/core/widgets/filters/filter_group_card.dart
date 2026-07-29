import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Rounded bordered container that visually groups related filter controls
/// into one parent filter block.
class FilterGroupCard extends StatelessWidget {
  const FilterGroupCard({
    required this.child,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderWidth = 1.4,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.s24),
      padding: padding ?? const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        border: Border.all(
          color: borderColor ?? AppColors.bronzeLight,
          width: borderWidth,
        ),
      ),
      child: child,
    );
  }
}
