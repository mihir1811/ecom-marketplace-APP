import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Outlined selectable card showing a month with its birthstone name underneath.
class BirthstoneMonthCard extends StatelessWidget {
  const BirthstoneMonthCard({
    required this.month,
    required this.gemstone,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String month;
  final String gemstone;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.selectedFill(context)
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(
            color: isSelected ? AppColors.selectedFill(context) : AppColors.border(context),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              month,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? AppColors.onSelected(context)
                    : AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              gemstone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: isSelected
                    ? AppColors.onSelected(context).withValues(alpha: 0.75)
                    : AppColors.textMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
