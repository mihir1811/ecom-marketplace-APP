import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
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
    final fill = AppColors.selectedFill(context);
    final onFill = AppColors.onSelected(context);
    final borderColor =
        isSelected ? fill : AppColors.border(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? fill : AppColors.card(context),
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
                    color: isSelected
                        ? onFill
                        : AppColors.textSecondary(context),

                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              context.trCatalogValue(name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
                color: isSelected
                    ? onFill
                    : AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
