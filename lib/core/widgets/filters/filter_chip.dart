import 'package:flutter/material.dart';
import '../../haptics/app_haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/luxe_scope.dart';
import '../../theme/luxe_tokens.dart';

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
    final luxe = LuxeScope.paletteOf(context) != null;

    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: centerLabel ? Alignment.center : null,
        decoration: BoxDecoration(
          color: isSelected ? fill : defaultUnselectedBg,
          borderRadius: BorderRadius.circular(luxe ? 100 : AppSpacing.r8),
          border: Border.all(
            color: isSelected ? fill : defaultBorder,
            width: isSelected && !luxe ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style:
              textStyle ??
              (luxe
                  ? LuxeType.label(
                      isSelected ? onFill : defaultUnselectedText,
                      size: 12.5,
                    )
                  : null) ??
              AppTypography.caption.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? onFill : defaultUnselectedText,
              ),
        ),
      ),
    );
  }
}
