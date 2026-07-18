import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_filter_state.dart';
import 'filter_section_header.dart';
import 'filter_origin_dropdown.dart';

class FilterCategoryPreferences extends ConsumerWidget {
  const FilterCategoryPreferences({
    required this.companyController,
    required this.locationController,
    super.key,
  });

  final TextEditingController companyController;
  final TextEditingController locationController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);
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
                      infoText: 'Search for diamonds located in a specific city, state, or region.',
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: locationController,
                              style: AppTypography.caption,
                              decoration: InputDecoration(
                                hintText: 'Search by location (City, State, Country)',
                                filled: true,
                                fillColor: isDark ? AppColors.obsidianBg : AppColors.warmWhite,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                              ),
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
                            onPressed: () {
                              ref.read(diamondSearchProvider.notifier).updateVendorLocationSearch(locationController.text);
                            },
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
            selectedOrigin: state.selectedOrigin,
            onSelected: (val) => ref.read(diamondSearchProvider.notifier).updateOriginCountry(val),
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.s24),

          const FilterSectionHeader(
            title: 'Rough Source',
            infoText: 'Filter by the mine source or rough diamond holder.',
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
                hint: const Text('Select rough source'),
                value: state.selectedRoughSource,
                items: DiamondFilterState.roughSources.map((src) {
                  return DropdownMenuItem<String>(
                    value: src,
                    child: Text(src),
                  );
                }).toList(),
                onChanged: (val) => ref.read(diamondSearchProvider.notifier).updateRoughSource(val),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),

          // === MINIMUM SELLER RATING ===
          const FilterSectionHeader(
            title: 'Minimum Seller Rating',
            infoText: 'Filter diamonds based on vendor rating stars.',
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.bronze,
                    inactiveTrackColor: borderColor,
                    thumbColor: AppColors.bronze,
                    overlayColor: AppColors.bronze.withOpacity(0.12),
                    valueIndicatorColor: AppColors.charcoal,
                    valueIndicatorTextStyle: const TextStyle(
                      color: AppColors.warmWhite,
                      fontSize: 12,
                    ),
                  ),
                  child: Slider(
                    value: state.minSellerRating,
                    min: 0.0,
                    max: 5.0,
                    divisions: 10,
                    label: state.minSellerRating == 0.0
                        ? 'Any'
                        : '${state.minSellerRating.toStringAsFixed(1)}★ & up',
                    onChanged: (val) => notifier.updateSellerRating(val),
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  state.minSellerRating == 0.0
                      ? 'Any'
                      : '${state.minSellerRating.toStringAsFixed(1)}★',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.bronze,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),

          // === COMPANY NAME ===
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FilterSectionHeader(
                      title: 'Company Name',
                      infoText: 'Search for diamonds supplied by a specific company name.',
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: companyController,
                              style: AppTypography.caption,
                              decoration: InputDecoration(
                                hintText: 'Search by company name',
                                filled: true,
                                fillColor: isDark ? AppColors.obsidianBg : AppColors.warmWhite,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                              ),
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
                            onPressed: () {
                              notifier.updateCompanyNameSearch(companyController.text);
                            },
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
