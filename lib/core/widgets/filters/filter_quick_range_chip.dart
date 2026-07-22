import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

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
    final containerBorderColor = isSelected ? AppColors.bronze : (AppColors.warmBorder);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.bronze.withOpacity(0.12)
              : (AppColors.warmWhite),
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(color: containerBorderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: isSelected ? AppColors.bronze : (AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
