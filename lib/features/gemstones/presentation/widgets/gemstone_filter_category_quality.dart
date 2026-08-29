import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:gemstone/core/widgets/filters/filter_chip.dart';
import 'package:gemstone/core/widgets/filters/filter_group_card.dart';
import '../../../diamonds/presentation/widgets/filter_color_selector.dart';
import 'package:gemstone/core/widgets/filters/filter_scrollable_chips.dart';
import 'package:gemstone/core/widgets/filters/filter_section_header.dart';
import '../../application/gemstone_search_provider.dart';
import '../../domain/models/gemstone_filter_state.dart';

/// Color and quality gemstone filters: color swatches, intensity, modifier,
/// fluorescence, clarity, and quality grade.
class GemstoneFilterCategoryQuality extends ConsumerWidget {
  const GemstoneFilterCategoryQuality({super.key, this.wrapWithCard = true});

  final bool wrapWithCard;

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
    final state = ref.watch(gemstoneSearchProvider);
    final notifier = ref.read(gemstoneSearchProvider.notifier);
    final borderColor = AppColors.border(context);
    final isMelee = state.lotType == 'Melee';
    final colors = GemstoneFilterState.colorsForDisplay(isMelee: isMelee);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === COLOR ===
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilterSectionHeader(title: context.tr(CatalogL10n.color)),
            const SizedBox(height: AppSpacing.s8),
            SizedBox(
              height: 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  final colorName = colors[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: FancyColorDiamondButton(
                      colorName: colorName,
                      isSelected: state.selectedColors.contains(colorName),
                      onTap: () => notifier.toggleColor(colorName),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.s20),

        // === COLOR INTENSITY ===
        FilterScrollableChips(
          wrapWithCard: false,
          title: context.tr(CatalogL10n.colorIntensity),
          options: GemstoneFilterState.colorIntensities,
          selectedItems: state.selectedIntensities,
          onToggle: (val) => notifier.toggleIntensity(val),
          infoText: context.tr(CatalogL10n.colorIntensityHelp),
        ),

        const SizedBox(height: AppSpacing.s20),

        // === MODIFIER ===
        FilterScrollableChips(
          wrapWithCard: false,
          title: context.tr(CatalogL10n.modifier),
          options: GemstoneFilterState.modifiers,
          selectedItems: state.selectedModifiers,
          onToggle: (val) => notifier.toggleModifier(val),
          infoText: context.tr(CatalogL10n.modifierHelp),
        ),

        const SizedBox(height: AppSpacing.s20),

        // === FLUORESCENCE INTENSITY ===
        FilterScrollableChips(
          wrapWithCard: false,
          title: context.tr(CatalogL10n.fluorescenceIntensity),
          options: GemstoneFilterState.fluorescenceGrades,
          selectedItems: state.selectedFluorescence,
          onToggle: (val) => notifier.toggleFluorescence(val),
          infoText: context.tr(CatalogL10n.fluorescenceHelp),
        ),

        const SizedBox(height: AppSpacing.s20),

        // === FLUORESCENCE COLOR ===
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilterSectionHeader(
              title: context.tr(CatalogL10n.fluorescenceColor),
            ),
            const SizedBox(height: AppSpacing.s8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: GemstoneFilterState.fluorescenceColors.map((name) {
                  final isSelected = state.selectedFluorescenceColor == name;
                  final hex = GemstoneFilterState.fluorescenceColorsHex[name]!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () => notifier.updateFluorescenceColor(name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.selectedFill(context)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppSpacing.r8),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _parseHex(hex),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.onSelected(context)
                                      : borderColor,
                                  width: isSelected ? 2.5 : 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.onSelected(context)
                                    : AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.s20),

        // === CLARITY ===
        FilterScrollableChips(
          wrapWithCard: false,
          title: context.tr(CatalogL10n.clarity),
          options: GemstoneFilterState.clarities,
          selectedItems: state.selectedClarities,
          onToggle: (val) => notifier.toggleClarity(val),
          infoText: context.tr(CatalogL10n.clarityHelp),
        ),

        const SizedBox(height: AppSpacing.s20),

        // === QUALITY GRADE (single select) ===
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilterSectionHeader(
              title: context.tr(CatalogL10n.qualityGrade),
              infoText: context.tr(CatalogL10n.qualityGradeHelp),
            ),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: GemstoneFilterState.qualityGrades.map((grade) {
                return FilterChipWidget(
                  label: grade,
                  isSelected: state.selectedQualityGrade == grade,
                  onTap: () => notifier.updateQualityGrade(grade),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );

    return RepaintBoundary(
      child: wrapWithCard ? FilterGroupCard(child: content) : content,
    );
  }
}
