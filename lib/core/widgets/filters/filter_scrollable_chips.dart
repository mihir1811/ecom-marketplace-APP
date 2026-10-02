import 'package:flutter/material.dart';
import '../../haptics/app_haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'filter_group_card.dart';
import 'filter_info_tooltip.dart';
import 'filter_proportion_diagram.dart';
import '../../theme/luxe_scope.dart';
import '../../theme/luxe_tokens.dart';

class FilterScrollableChips extends StatelessWidget {
  const FilterScrollableChips({
    required this.title,
    required this.options,
    required this.selectedItems,
    required this.onToggle,
    required this.infoText,
    this.infoDiagram,
    this.wrapWithCard = true,
    this.margin,
    super.key,
  });

  final String title;
  final List<String> options;
  final List<String> selectedItems;
  final void Function(String) onToggle;
  final String infoText;
  final FilterProportionDiagramKind? infoDiagram;
  final bool wrapWithCard;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final containerBorderColor = AppColors.border(context);
    final luxe = LuxeScope.paletteOf(context) != null;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: luxe
                  ? LuxeType.label(
                      AppColors.textPrimary(context),
                      size: 13.5,
                    ).copyWith(fontWeight: FontWeight.w600)
                  : AppTypography.label.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
            ),
            const SizedBox(width: 6),
            FilterInfoTooltip(message: infoText, diagram: infoDiagram),
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
                  onTap: () {
                    AppHaptics.selection();
                    onToggle(opt);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.selectedFill(context)
                          : (AppColors.card(context)),
                      borderRadius: BorderRadius.circular(
                        luxe ? 100 : AppSpacing.r8,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.selectedFill(context)
                            : containerBorderColor,
                      ),
                    ),
                    child: Text(
                      opt,
                      style: luxe
                          ? LuxeType.label(
                              isSelected
                                  ? AppColors.onSelected(context)
                                  : AppColors.textPrimary(context),
                              size: 12.5,
                            )
                          : AppTypography.caption.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.onSelected(context)
                                  : (AppColors.textPrimary(context)),
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

    if (!wrapWithCard) {
      return content;
    }

    return FilterGroupCard(margin: margin, child: content);
  }
}
