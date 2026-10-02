import 'package:flutter/material.dart';
import '../../haptics/app_haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/luxe_scope.dart';
import '../../theme/luxe_tokens.dart';

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
    final luxe = LuxeScope.paletteOf(context);
    if (luxe != null) {
      return MergeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            AppHaptics.selection();
            onChanged(!value);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(label, style: LuxeType.body(luxe.ink, size: 14)),
                ),
                Switch(
                  value: value,
                  activeThumbColor: luxe.canvas,
                  activeTrackColor: luxe.ink,
                  inactiveThumbColor: luxe.inkFaint,
                  inactiveTrackColor: luxe.surfaceRaised,
                  trackOutlineColor: WidgetStatePropertyAll(luxe.hairline),
                  onChanged: (v) {
                    AppHaptics.selection();
                    onChanged(v);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Row(
      children: [
        Checkbox(
          value: value,
          activeColor: AppColors.bronze,
          checkColor: AppColors.warmWhite,
          side: BorderSide(color: AppColors.border(context)),
          onChanged: (value) {
            AppHaptics.selection();
            onChanged(value);
          },
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
