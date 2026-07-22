import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class FilterScrollableChips extends StatelessWidget {
  const FilterScrollableChips({
    required this.title,
    required this.options,
    required this.selectedItems,
    required this.onToggle,
    required this.infoText,
    super.key,
  });

  final String title;
  final List<String> options;
  final List<String> selectedItems;
  final void Function(String) onToggle;
  final String infoText;

  @override
  Widget build(BuildContext context) {
    final containerBorderColor = AppColors.warmBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: infoText,
              triggerMode: TooltipTriggerMode.tap,
              preferBelow: false,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(color: Colors.white, fontSize: 13),
              child: const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.bronze,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((opt) {
              final isSelected = selectedItems.contains(opt);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () => onToggle(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.charcoal
                          : (AppColors.warmWhite),
                      borderRadius: BorderRadius.circular(AppSpacing.r8),
                      border: Border.all(
                        color: isSelected ? AppColors.charcoal : containerBorderColor,
                      ),
                    ),
                    child: Text(
                      opt,
                      style: AppTypography.caption.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? AppColors.warmWhite
                            : (AppColors.textPrimaryLight),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
