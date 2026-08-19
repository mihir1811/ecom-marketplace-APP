import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

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
    return Row(
      children: [
        Checkbox(
          value: value,
          activeColor: AppColors.bronze,
          checkColor: AppColors.warmWhite,
          side: BorderSide(color: AppColors.border(context)),
          onChanged: onChanged,
        ),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
      ],
    );
  }
}
