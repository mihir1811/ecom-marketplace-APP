import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/widgets/global_search_bar.dart';
import '../widgets/diamond_shape_carousel.dart';
import '../widgets/search_bottom_bar.dart';
import '../widgets/filter_category_basic.dart';
import '../widgets/filter_category_preferences.dart';
import '../widgets/filter_category_measurements.dart';
import '../widgets/filter_category_inclusions.dart';
import '../widgets/filter_category_treatment.dart';
import '../widgets/filter_category_advanced.dart';

enum FilterCategory {
  basic('BASIC', Icons.diamond_outlined),
  pref('PREFERENCES', Icons.tune),
  meas('MEASUREMENTS', Icons.straighten),
  inclusions('INCLUSIONS', Icons.all_inclusive),
  treatment('TREATMENT', Icons.healing),
  advanced('ADVANCED', Icons.add);

  final String label;
  final IconData icon;
  const FilterCategory(this.label, this.icon);
}

class DiamondSearchScreen extends ConsumerStatefulWidget {
  const DiamondSearchScreen({super.key});

  @override
  ConsumerState<DiamondSearchScreen> createState() => _DiamondSearchScreenState();
}

class _DiamondSearchScreenState extends ConsumerState<DiamondSearchScreen> {
  FilterCategory _activeCategory = FilterCategory.basic;
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppColors.slateSurface : AppColors.warmWhite;
    final containerBorderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'DIAMOND FINDER',
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          GlobalSearchBar(isDark: isDark),
          Expanded(
            child: SafeArea(
              top: false,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.s16,
                      right: AppSpacing.s16,
                      top: AppSpacing.s16,
                      bottom: 120.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DiamondShapeCarousel(),
                        const SizedBox(height: AppSpacing.s24),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: containerColor,
                            borderRadius: BorderRadius.circular(AppSpacing.r16),
                            border: Border.all(color: containerBorderColor),
                            boxShadow: AppShadows.cardLight,
                          ),
                          padding: const EdgeInsets.all(AppSpacing.s16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.search, color: AppColors.bronze, size: 24),
                                  const SizedBox(width: AppSpacing.s8),
                                  Text(
                                    'Diamond Search',
                                    style: AppTypography.headline.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.s12),
                              _buildCategoryTabs(isDark),
                              const SizedBox(height: AppSpacing.s16),
                              if (_activeCategory == FilterCategory.basic)
                                const FilterCategoryBasic()
                              else if (_activeCategory == FilterCategory.pref)
                                FilterCategoryPreferences(locationController: _locationController)
                              else if (_activeCategory == FilterCategory.meas)
                                const FilterCategoryMeasurements()
                              else if (_activeCategory == FilterCategory.inclusions)
                                const FilterCategoryInclusions()
                              else if (_activeCategory == FilterCategory.treatment)
                                const FilterCategoryTreatment()
                              else if (_activeCategory == FilterCategory.advanced)
                                FilterCategoryAdvanced(companyController: _companyController),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SearchBottomBar(
                      onClear: () {
                        _companyController.clear();
                        _locationController.clear();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FilterCategory.values.map((cat) {
          final isSelected = _activeCategory == cat;
          const activeColor = AppColors.bronze;
          final inactiveColor = isDark ? Colors.white30 : Colors.black26;
          final textColor = isSelected
              ? activeColor
              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: GestureDetector(
              onTap: () => setState(() => _activeCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? activeColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      color: isSelected ? activeColor : inactiveColor,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Tooltip(
                      message: cat.label,
                      child: Text(
                        cat.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
