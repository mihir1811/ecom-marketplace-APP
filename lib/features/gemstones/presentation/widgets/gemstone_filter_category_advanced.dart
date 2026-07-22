import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../diamonds/presentation/widgets/filter_chip.dart';
import '../../../diamonds/presentation/widgets/filter_origin_dropdown.dart';
import '../../../diamonds/presentation/widgets/filter_scrollable_chips.dart';
import '../../../diamonds/presentation/widgets/filter_section_header.dart';
import '../../application/gemstone_search_provider.dart';
import '../../domain/models/gemstone_filter_state.dart';

/// Advanced gemstone filters: treatments, certification, origin, and cut grade.
class GemstoneFilterCategoryAdvanced extends ConsumerWidget {
  const GemstoneFilterCategoryAdvanced({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gemstoneSearchProvider);
    final notifier = ref.read(gemstoneSearchProvider.notifier);
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === TREATMENTS ===
          const FilterSectionHeader(
            title: 'Treatments',
            infoText: 'Filter by enhancement processes applied to the gemstone.',
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: GemstoneFilterState.treatments.map((treatment) {
              return FilterChipWidget(
                label: treatment,
                isSelected: state.selectedTreatments.contains(treatment),
                onTap: () => notifier.toggleTreatment(treatment),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.s20),

          // === CERTIFICATION ===
          const FilterSectionHeader(
            title: 'Certification',
            infoText:
                'Filter by the gemological laboratory that certified the stone.',
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: GemstoneFilterState.certifications.map((cert) {
              return FilterChipWidget(
                label: cert,
                isSelected: state.selectedCertifications.contains(cert),
                onTap: () => notifier.toggleCertification(cert),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.s20),

          // === SELECT ORIGIN ===
          FilterOriginDropdown(
            title: 'Select Origin',
            hint: 'Select origin',
            infoText: "Filter by the gemstone's mined origin.",
            pickerTitle: 'Select Origin',
            options: GemstoneFilterState.origins,
            flags: GemstoneFilterState.originFlags,
            showFlags: true,
            selectedOrigin: state.selectedOrigin,
            onSelected: (val) => notifier.updateOrigin(val),
          ),
          const SizedBox(height: AppSpacing.s20),

          // === CUT GRADE ===
          FilterScrollableChips(
            title: 'Cut Grade',
            options: GemstoneFilterState.cutGrades,
            selectedItems: state.selectedCutGrades,
            onToggle: (val) => notifier.toggleCutGrade(val),
            infoText: "Filter by the quality of the gemstone's cut.",
          ),
        ],
      ),
    );
  }
}
