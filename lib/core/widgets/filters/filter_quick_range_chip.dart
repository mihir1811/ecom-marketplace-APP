import 'package:flutter/material.dart';
import '../../haptics/app_haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/luxe_scope.dart';
import '../../theme/luxe_tokens.dart';

class FilterQuickRangeChip extends StatelessWidget {
  const FilterQuickRangeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = AppColors.selectedFill(context);
    final onFill = AppColors.onSelected(context);
    final containerBorderColor = isSelected ? fill : AppColors.border(context);
    final luxe = LuxeScope.paletteOf(context) != null;

    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? fill : AppColors.card(context),
          borderRadius: BorderRadius.circular(luxe ? 100 : AppSpacing.r8),
          border: Border.all(
            color: containerBorderColor,
            width: isSelected && !luxe ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: luxe
              ? LuxeType.label(
                  isSelected ? onFill : AppColors.textSecondary(context),
                  size: 12,
                )
              : AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isSelected ? onFill : AppColors.textSecondary(context),
                ),
        ),
      ),
    );
  }
}
