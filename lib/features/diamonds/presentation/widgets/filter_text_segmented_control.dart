import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// String-based single-select segmented control (switch) — used by the
/// lab-grown Diamond Category section.
class FilterTextSegmentedControl extends StatelessWidget {
  const FilterTextSegmentedControl({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> options;
  final String selected;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: options.map((opt) {
          final isCurrent = opt == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.charcoal
                      : (isDark ? AppColors.obsidianBg : AppColors.warmWhite),
                  borderRadius: BorderRadius.circular(AppSpacing.r8 - 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  opt.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: 0.5,
                    color: isCurrent
                        ? AppColors.warmWhite
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
