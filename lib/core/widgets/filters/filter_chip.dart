import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class FilterChipWidget extends StatelessWidget {
  const FilterChipWidget({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.unselectedBgColor,
    this.borderColor,
    this.textStyle,
    this.padding,
    this.centerLabel = false,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final Color? unselectedBgColor;
  final Color? borderColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;

  /// Centers the label — for chips stretched to full width (e.g. in a Row of
  /// Expanded children).
  final bool centerLabel;

  @override
  Widget build(BuildContext context) {
    final fill = selectedColor ?? AppColors.selectedFill(context);
    final onFill = selectedTextColor ?? AppColors.onSelected(context);
    final defaultUnselectedBg = unselectedBgColor ?? AppColors.card(context);
    final defaultBorder = borderColor ?? AppColors.border(context);
    final defaultUnselectedText =
        unselectedTextColor ?? AppColors.textPrimary(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: centerLabel ? Alignment.center : null,
        decoration: BoxDecoration(
          color: isSelected ? fill : defaultUnselectedBg,
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(
            color: isSelected ? fill : defaultBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style:
              textStyle ??
              AppTypography.caption.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? onFill : defaultUnselectedText,
              ),
        ),
      ),
    );
  }
}
