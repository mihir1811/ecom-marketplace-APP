import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Rounded dropdown that follows the ambient (luxe-aware) palette.
class LuxeDropdownField<T> extends StatelessWidget {
  const LuxeDropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
    this.hint,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border.all(color: AppColors.border(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: hint == null ? null : Text(hint!),
          borderRadius: BorderRadius.circular(14),
          dropdownColor: AppColors.card(context),
          icon: Icon(
            Icons.expand_more_rounded,
            color: AppColors.textSecondary(context),
          ),
          style: AppTypography.body.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary(context),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
