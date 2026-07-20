import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../diamonds/presentation/widgets/filter_origin_dropdown.dart';
import '../../../diamonds/presentation/widgets/filter_section_header.dart';
import '../../application/gemstone_search_provider.dart';
import '../../domain/models/gemstone_filter_state.dart';

class GemstoneFilterCategoryPreferences extends ConsumerWidget {
  const GemstoneFilterCategoryPreferences({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gemstoneSearchProvider);
    final notifier = ref.read(gemstoneSearchProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FilterSectionHeader(
                      title: "Vendor's Location",
                      infoText: 'Search for gemstones located in a specific city, state, or region.',
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              style: AppTypography.caption,
                              decoration: InputDecoration(
                                hintText: 'Search by location (City, State, Country)',
                                filled: true,
                                fillColor: isDark ? AppColors.obsidianBg : AppColors.warmWhite,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              onChanged: (val) => notifier.updateVendorLocation(val),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s4),
                        SizedBox(
                          height: 38,
                          width: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: AppColors.charcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            onPressed: () {},
                            child: const Text('Add', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),

          FilterOriginDropdown(
            title: 'Origin Country',
            hint: 'Select origin country',
            infoText: "Filter by the gemstone's origin country.",
            pickerTitle: 'Select Origin Country',
            options: GemstoneFilterState.origins,
            flags: GemstoneFilterState.originFlags,
            showFlags: true,
            selectedOrigin: state.selectedOriginCountry,
            onSelected: (val) => notifier.updateOriginCountry(val),
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.s24),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FilterSectionHeader(
                      title: 'Company Name',
                      infoText: 'Search for gemstones supplied by a specific company name.',
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              style: AppTypography.caption,
                              decoration: InputDecoration(
                                hintText: 'Search by company name',
                                filled: true,
                                fillColor: isDark ? AppColors.obsidianBg : AppColors.warmWhite,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              onChanged: (val) => notifier.updateCompanyName(val),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s4),
                        SizedBox(
                          height: 38,
                          width: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: AppColors.charcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            onPressed: () {},
                            child: const Text('Add', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
