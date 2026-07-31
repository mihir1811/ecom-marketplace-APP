import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../domain/models/diamond_filter_state.dart';
import '../../application/diamond_search_provider.dart';
import '../../../../core/utils/app_currency.dart';

class DiamondFilterChips extends ConsumerWidget {
  const DiamondFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);
    final mutedColor = AppColors.textSecondaryLight;

    final chips = <_FilterChipData>[];

    if (filters.labNatural != LabNaturalType.natural) {
      chips.add(
        _FilterChipData(
          label: filters.labNatural.label,
          onRemove: () => notifier.updateOrigin(LabNaturalType.natural),
        ),
      );
    }

    for (final shape in filters.shapes) {
      chips.add(
        _FilterChipData(
          label: shape,
          onRemove: () => notifier.toggleShape(shape),
        ),
      );
    }

    if (filters.minPrice > 0 || filters.maxPrice < 1000000) {
      final label =
          '${AppCurrency.format(formatCatalogPriceWholeK(filters.minPrice))}-${AppCurrency.format(formatCatalogPriceWholeK(filters.maxPrice))}';
      chips.add(
        _FilterChipData(
          label: label,
          onRemove: () => notifier.updatePriceRange(0, 1000000),
        ),
      );
    }

    if (filters.minCarat > 0.0 || filters.maxCarat < 100.0) {
      final label = '${filters.minCarat}-${filters.maxCarat}ct';
      chips.add(
        _FilterChipData(
          label: label,
          onRemove: () => notifier.updateCaratRange(0.0, 100.0),
        ),
      );
    }

    for (final cut in filters.selectedCuts) {
      chips.add(
        _FilterChipData(label: cut, onRemove: () => notifier.toggleCut(cut)),
      );
    }

    if (filters.minColorIndex > 0 || filters.maxColorIndex < 22) {
      final from = DiamondFilterState.colors[filters.minColorIndex];
      final to = DiamondFilterState.colors[filters.maxColorIndex];
      chips.add(
        _FilterChipData(
          label: '$from-$to',
          onRemove: () => notifier.updateColorRange(0, 22),
        ),
      );
    }

    for (final color in filters.selectedStandardColors) {
      chips.add(
        _FilterChipData(
          label: color,
          onRemove: () => notifier.toggleStandardColor(color),
        ),
      );
    }

    if (filters.minClarityIndex > 0 ||
        filters.maxClarityIndex < DiamondFilterState.clarities.length - 1) {
      final from = DiamondFilterState.clarities[filters.minClarityIndex];
      final to = DiamondFilterState.clarities[filters.maxClarityIndex];
      chips.add(
        _FilterChipData(
          label: '$from-$to',
          onRemove: () => notifier.updateClarityRange(
            0,
            DiamondFilterState.clarities.length - 1,
          ),
        ),
      );
    }

    for (final clarity in filters.selectedClarityGrades) {
      chips.add(
        _FilterChipData(
          label: clarity,
          onRemove: () => notifier.removeClarityGrade(clarity),
        ),
      );
    }

    for (final lab in filters.selectedLabs) {
      chips.add(
        _FilterChipData(label: lab, onRemove: () => notifier.toggleLab(lab)),
      );
    }

    if (filters.noBgm) {
      chips.add(
        _FilterChipData(
          label: 'No BGM',
          onRemove: () => notifier.toggleNoBgm(),
        ),
      );
    }

    if (filters.eyeClean) {
      chips.add(
        _FilterChipData(
          label: 'Eye Clean',
          onRemove: () => notifier.toggleEyeClean(),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            itemCount: chips.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Center(
                  child: Text(
                    'Filters:',
                    style: AppTypography.caption.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              final chip = chips[index - 1];
              return Chip(
                label: Text(
                  chip.label,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                deleteIcon: const Icon(Icons.close, size: 12),
                onDeleted: chip.onRemove,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.only(left: AppSpacing.s8),
                labelPadding: EdgeInsets.zero,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
      ],
    );
  }

}

class _FilterChipData {
  final String label;
  final VoidCallback onRemove;

  const _FilterChipData({required this.label, required this.onRemove});
}
