import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'catalog_search_add_field.dart';
import 'filter_section_header.dart';

/// Shared vendor preference filters for diamond and gemstone search.
///
/// Pass [originDropdown] from the feature layer (e.g. [FilterOriginDropdown]).
/// Optional rough-source and seller-rating sections are diamond-only.
class CatalogPreferencesFilters extends StatelessWidget {
  const CatalogPreferencesFilters({
    required this.locationField,
    required this.originDropdown,
    required this.companyField,
    this.roughSourceOptions,
    this.selectedRoughSource,
    this.onRoughSourceChanged,
    this.minSellerRating,
    this.onSellerRatingChanged,
    super.key,
  });

  final CatalogSearchAddField locationField;
  final Widget originDropdown;
  final CatalogSearchAddField companyField;

  final List<String>? roughSourceOptions;
  final String? selectedRoughSource;
  final ValueChanged<String?>? onRoughSourceChanged;

  final double? minSellerRating;
  final ValueChanged<double>? onSellerRatingChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.border(context);
    final showRough = roughSourceOptions != null && onRoughSourceChanged != null;
    final showRating =
        minSellerRating != null && onSellerRatingChanged != null;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          locationField,
          const SizedBox(height: AppSpacing.s20),
          originDropdown,
          if (showRough) ...[
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
                  value: selectedRoughSource,
                  items: roughSourceOptions!
                      .map(
                        (src) => DropdownMenuItem<String>(
                          value: src,
                          child: Text(src),
                        ),
                      )
                      .toList(),
                  onChanged: onRoughSourceChanged,
                ),
              ),
            ),
          ],
          if (showRating) ...[
            const SizedBox(height: AppSpacing.s24),
            const FilterSectionHeader(
              title: 'Minimum Seller Rating',
              infoText: 'Filter based on vendor rating stars.',
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
                      overlayColor: AppColors.bronze.withValues(alpha: 0.12),
                      valueIndicatorColor: AppColors.charcoal,
                      valueIndicatorTextStyle: const TextStyle(
                        color: AppColors.warmWhite,
                        fontSize: 12,
                      ),
                    ),
                    child: Slider(
                      value: minSellerRating!,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      label: minSellerRating == 0.0
                          ? 'Any'
                          : '${minSellerRating!.toStringAsFixed(1)}★ & up',
                      onChanged: onSellerRatingChanged,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    minSellerRating == 0.0
                        ? 'Any'
                        : '${minSellerRating!.toStringAsFixed(1)}★',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.bronze,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.s20),
          companyField,
        ],
      ),
    );
  }
}
