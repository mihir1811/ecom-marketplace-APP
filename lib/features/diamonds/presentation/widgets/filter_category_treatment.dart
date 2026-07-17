import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_filter_state.dart';
import 'filter_section_header.dart';

class FilterCategoryTreatment extends ConsumerWidget {
  const FilterCategoryTreatment({super.key});

  Color _parseHex(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diamondSearchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FilterSectionHeader(
            title: 'Milky',
            infoText: 'Filter by the degree of haziness or cloudiness in the diamond.',
          ),
          const SizedBox(height: AppSpacing.s8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DiamondFilterState.milkyGrades.map((grade) {
                final isSelected = state.selectedMilkyGrades.contains(grade);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => ref.read(diamondSearchProvider.notifier).toggleMilkyGrade(grade),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.charcoal : (isDark ? AppColors.slateSurface : AppColors.warmWhite),
                        borderRadius: BorderRadius.circular(AppSpacing.r8),
                        border: Border.all(color: isSelected ? AppColors.charcoal : borderColor),
                      ),
                      child: Text(
                        grade,
                        style: AppTypography.caption.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.warmWhite : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),

          const FilterSectionHeader(
            title: 'Fluorescence Intensity',
            infoText: "Filter by the strength of the diamond's glow under UV light.",
          ),
          const SizedBox(height: AppSpacing.s8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DiamondFilterState.fluorescenceGrades.map((grade) {
                final isSelected = state.selectedFluorescence.contains(grade);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => ref.read(diamondSearchProvider.notifier).toggleFluorescence(grade),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.charcoal : (isDark ? AppColors.slateSurface : AppColors.warmWhite),
                        borderRadius: BorderRadius.circular(AppSpacing.r8),
                        border: Border.all(color: isSelected ? AppColors.charcoal : borderColor),
                      ),
                      child: Text(
                        grade,
                        style: AppTypography.caption.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.warmWhite : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),

          const FilterSectionHeader(
            title: 'Fluorescence Color',
            infoText: "Filter by the color of the diamond's UV fluorescence glow.",
          ),
          const SizedBox(height: AppSpacing.s8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(AppSpacing.r8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Select fluorescence color'),
                value: state.selectedFluorescenceColor,
                items: DiamondFilterState.fluorescenceColors.map((colorName) {
                  final hex = DiamondFilterState.fluorescenceColorsHex[colorName]!;
                  return DropdownMenuItem<String>(
                    value: colorName,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _parseHex(hex),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Text(colorName),
                        const Spacer(),
                        Text(
                          hex,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => ref.read(diamondSearchProvider.notifier).updateFluorescenceColor(val),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),

          const FilterSectionHeader(
            title: 'Enhancement',
            infoText: 'Filter by treatments applied to improve appearance.',
          ),
          const SizedBox(height: AppSpacing.s8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(AppSpacing.r8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Select enhancement'),
                value: state.selectedEnhancement,
                items: DiamondFilterState.enhancements.map((enh) {
                  return DropdownMenuItem<String>(
                    value: enh,
                    child: Text(enh),
                  );
                }).toList(),
                onChanged: (val) => ref.read(diamondSearchProvider.notifier).updateEnhancement(val),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
