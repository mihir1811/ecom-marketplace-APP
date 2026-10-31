import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../luxe/luxe_multi_select_field.dart';
import 'catalog_search_add_field.dart';
import 'filter_section_divider.dart';
import 'filter_section_header.dart';

/// Shared vendor preference filters for diamond and gemstone search.
///
/// Order: vendor location → company name → origin country (→ rough source,
/// seller rating).
///
/// Pass [originDropdown] from the feature layer (e.g. [FilterOriginDropdown]).
/// Optional rough-source and seller-rating sections are diamond-only.
/// Origin / rough source are omitted for lab-grown catalogs.
class CatalogPreferencesFilters extends StatelessWidget {
  const CatalogPreferencesFilters({
    required this.locationField,
    required this.companyField,
    this.originDropdown,
    this.roughSourceOptions,
    this.selectedRoughSources = const [],
    this.onRoughSourcesChanged,
    this.minSellerRating,
    this.onSellerRatingChanged,
    super.key,
  });

  final CatalogSearchAddField locationField;
  final Widget? originDropdown;
  final CatalogSearchAddField companyField;

  final List<String>? roughSourceOptions;
  final List<String> selectedRoughSources;
  final ValueChanged<List<String>>? onRoughSourcesChanged;

  final double? minSellerRating;
  final ValueChanged<double>? onSellerRatingChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.border(context);
    final showRough =
        roughSourceOptions != null && onRoughSourcesChanged != null;
    final showRating = minSellerRating != null && onSellerRatingChanged != null;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          locationField,
          const FilterSectionDivider(),
          companyField,
          if (originDropdown != null) ...[
            const FilterSectionDivider(),
            originDropdown!,
          ],
          if (showRough) ...[
            const FilterSectionDivider(),
            FilterSectionHeader(
              title: context.tr(CatalogL10n.roughSource),
              infoText: context.tr(CatalogL10n.roughSourceHelp),
            ),
            const SizedBox(height: AppSpacing.s8),
            LuxeMultiSelectField(
              options: roughSourceOptions!,
              selected: selectedRoughSources,
              onChanged: onRoughSourcesChanged!,
              hint: context.tr(CatalogL10n.selectRoughSources),
              sheetTitle: context.tr(CatalogL10n.roughSource),
              labelOf: context.trCatalogValue,
            ),
          ],
          if (showRating) ...[
            const FilterSectionDivider(),
            FilterSectionHeader(
              title: context.tr(CatalogL10n.minimumSellerRating),
              infoText: context.tr(CatalogL10n.sellerRatingHelp),
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
                      valueIndicatorTextStyle: TextStyle(
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
                          ? context.tr(CatalogL10n.any)
                          : context.tr(CatalogL10n.ratingAndUp, {
                              'rating': minSellerRating!.toStringAsFixed(1),
                            }),
                      onChanged: (value) {
                        AppHaptics.selection();
                        onSellerRatingChanged!(value);
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    minSellerRating == 0.0
                        ? context.tr(CatalogL10n.any)
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
        ],
      ),
    );
  }
}
