import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Shared card chrome for cart address / promo / totals blocks.
///
/// Uses [Material] (not a colored [DecoratedBox]) so nested [ListTile]s can
/// paint ink/selection on this ancestor without Flutter's visibility assert.
class CartSectionCard extends StatelessWidget {
  const CartSectionCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        side: const BorderSide(color: AppColors.warmBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: child,
      ),
    );
  }
}
