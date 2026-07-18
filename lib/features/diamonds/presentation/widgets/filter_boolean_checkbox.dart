import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class FilterBooleanCheckbox extends StatelessWidget {
  const FilterBooleanCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Checkbox(
          value: value,
          activeColor: AppColors.bronze,
          checkColor: AppColors.warmWhite,
          side: BorderSide(color: isDark ? AppColors.slateBorder : AppColors.warmBorder),
          onChanged: onChanged,
        ),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }
}
