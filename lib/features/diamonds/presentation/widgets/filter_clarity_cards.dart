import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_filter_state.dart';

class ClarityCardsSection extends ConsumerWidget {
  const ClarityCardsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Clarity',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message:
                      "Filter by clarity grades representing the presence of internal inclusions.",
                  triggerMode: TooltipTriggerMode.tap,
                  preferBelow: false,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(color: Colors.white, fontSize: 11),
                  child: const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.bronze,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => notifier.selectAllClarityGrades(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(60, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '',
                // style: AppTypography.caption.copyWith(
                //   color: AppColors.bronze,
                //   fontWeight: FontWeight.bold,
                // ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: DiamondFilterState.clarities.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 2.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final grade = DiamondFilterState.clarities[index];
            final isSelected = state.selectedClarityGrades.contains(grade);
            return GestureDetector(
              onTap: () => notifier.toggleClarityGradeGroup([grade]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.charcoal
                      : (isDark ? AppColors.obsidianBg : AppColors.warmWhite),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.charcoal : borderColor,
                  ),
                ),
                child: Text(
                  grade,
                  style: AppTypography.caption.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppColors.warmWhite
                        : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
