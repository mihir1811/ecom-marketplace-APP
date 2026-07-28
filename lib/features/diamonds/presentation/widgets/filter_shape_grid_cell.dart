import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'diamond_svg_data.dart';

class FilterShapeGridCell extends StatelessWidget {
  const FilterShapeGridCell({
    required this.name,
    required this.isSelected,
    required this.onTap,
    this.svgName,
    super.key,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  /// Optional SVG asset key when the display name differs from the drawing name.
  final String? svgName;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? AppColors.charcoal : AppColors.warmBorder;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.charcoal : AppColors.warmWhite,
          borderRadius: BorderRadius.circular(AppSpacing.r12),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                width: 54,
                height: 54,
                child: Center(
                  child: renderShapeSvg(
                    svgName ?? name,
                    size: 40,
                    color: isSelected ? AppColors.warmWhite : Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
                color: isSelected
                    ? AppColors.warmWhite
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
