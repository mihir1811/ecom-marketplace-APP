import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/luxe_scope.dart';

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
    // Inside luxe sections the section itself is the card: group blocks are
    // separated by whitespace instead of nested borders.
    if (LuxeScope.paletteOf(context) != null) {
      return Padding(
        padding: margin ?? const EdgeInsets.only(bottom: AppSpacing.s20),
        child: SizedBox(width: double.infinity, child: child),
      );
    }
    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.s24),
      padding: padding ?? const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
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
