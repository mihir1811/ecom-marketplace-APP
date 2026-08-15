import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/filters/filter_accordion_section.dart';
import '../../../../core/widgets/filters/filter_boolean_checkbox.dart';
import '../../../../core/widgets/filters/filter_end_drawer_shell.dart';
import '../../application/watch_filter_provider.dart';
import '../../application/watch_list_provider.dart';
import '../../data/repositories/watch_brand_assets_data.dart';
import '../../domain/models/watch_brand_categories.dart';
import '../../domain/models/watch_filter_state.dart';
import 'watch_filter_swatch_pills.dart';

/// Side pop-up filter panel aligned to watch filter schema categories.
class WatchFilterDrawer extends ConsumerStatefulWidget {
  const WatchFilterDrawer({super.key});

  @override
  ConsumerState<WatchFilterDrawer> createState() => _WatchFilterDrawerState();
}

class _WatchFilterDrawerState extends ConsumerState<WatchFilterDrawer> {
  /// First five categories open by default; remaining collapsed.
  final Map<String, bool> _expanded = {
    'brand': true,
    'watch_style': true,
    'availability': true,
    'with_media': true,
    'gender': true,
    'price_range': false,
    'movement': false,
    'case': false,
    'bezel': false,
    'dial': false,
    'strap': false,
    'clasp': false,
    'crown': false,
    'features': false,
    'model_year': false,
    'condition': false,
    'authentication': false,
  };

  final Map<String, int> _visible = {
    'brand': 8,
    'model': 8,
    'caseShape': 8,
    'bezelType': 7,
    'year': 8,
  };

  bool _showAllBrands = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(watchFilterDraftProvider.notifier).syncFromApplied();
    });
  }

  List<String> get _allBrandsAlphabetical => watchBrandCategories
      .expand((g) => g.brands)
      .toList(growable: false);

  List<String> _modelOptions(WatchFilterState draft) {
    const byBrand = WatchCatalogBrands.modelsByBrand;
    if (draft.brands.isEmpty) {
      return byBrand.values.expand((m) => m).toSet().toList()..sort();
    }
    final models = <String>{};
    for (final brand in draft.brands) {
      models.addAll(byBrand[brand] ?? const []);
    }
    return models.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(watchFilterDraftProvider);
    final n = ref.read(watchFilterDraftProvider.notifier);
    final brandOptions = _showAllBrands
        ? _allBrandsAlphabetical
        : WatchFilterState.popularBrandOptions;
    final modelOptions = _modelOptions(draft);

    return FilterEndDrawerShell(
      resetLabel: 'Clear',
      onReset: n.reset,
      onShowResults: () {
        n.apply();
        ref.read(watchListProvider.notifier).refresh();
        Navigator.of(context).maybePop();
      },
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s24),
        children: [
          _section(
            'brand',
            'BRAND',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _subLabel('Brand'),
                _expandList(
                  'brand',
                  brandOptions,
                  draft.brands,
                  n.toggleBrand,
                  trailing: !_showAllBrands
                      ? _showMoreButton(
                          label:
                              'Show all brands (${_allBrandsAlphabetical.length})',
                          onTap: () => setState(() {
                            _showAllBrands = true;
                            _visible['brand'] =
                                _allBrandsAlphabetical.length;
                          }),
                        )
                      : null,
                ),
                _subLabel('Model'),
                _expandList(
                  'model',
                  modelOptions,
                  draft.models,
                  n.toggleModel,
                ),
              ],
            ),
          ),
          _section(
            'watch_style',
            'WATCH STYLE',
            _list(
              WatchFilterState.styleOptions,
              draft.categories,
              n.toggleStyle,
              grid: true,
            ),
          ),
          _section(
            'availability',
            'AVAILABILITY',
            _list(
              WatchFilterState.availabilityOptions,
              draft.availabilityStatuses,
              n.toggleAvailability,
              grid: true,
            ),
          ),
          _section(
            'with_media',
            'WITH MEDIA',
            _list(
              WatchFilterState.withMediaOptions,
              draft.withMedia,
              n.toggleWithMedia,
              grid: true,
            ),
          ),
          _section(
            'gender',
            'GENDER',
            _list(
              WatchFilterState.genderOptions,
              draft.genders,
              n.toggleGender,
              grid: true,
            ),
          ),
          _section(
            'price_range',
            'PRICE RANGE',
            _list(
              WatchFilterState.priceRangeOptions,
              draft.priceRanges,
              n.togglePriceRange,
              grid: true,
            ),
          ),
          _section(
            'movement',
            'MOVEMENT',
            _list(
              WatchFilterState.movementOptions,
              draft.movements,
              n.toggleMovement,
            ),
          ),
          _section(
            'case',
            'CASE',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _subLabel('Case Shape'),
                _expandList(
                  'caseShape',
                  WatchFilterState.caseShapeOptions,
                  draft.caseShapes,
                  n.toggleCaseShape,
                  grid: true,
                ),
                _subLabel('Case Size'),
                _list(
                  WatchFilterState.caseSizeRangeOptions,
                  draft.caseSizeRanges,
                  n.toggleCaseSizeRange,
                  grid: true,
                ),
                _swatchHeading('Case Material'),
                WatchFilterSwatchPillGrid(
                  options: WatchFilterState.caseMaterialOptions,
                  selected: draft.caseMaterials,
                  onToggle: n.toggleCaseMaterial,
                ),
                _subLabel('Lug Width'),
                _list(
                  WatchFilterState.lugWidthOptions,
                  draft.lugWidths,
                  n.toggleLugWidth,
                  grid: true,
                ),
              ],
            ),
          ),
          _section(
            'bezel',
            'BEZEL',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _subLabel('Bezel Type'),
                _expandList(
                  'bezelType',
                  WatchFilterState.bezelTypeOptions,
                  draft.bezelTypes,
                  n.toggleBezelType,
                ),
                _swatchHeading('Bezel Material'),
                WatchFilterSwatchPillGrid(
                  options: WatchFilterState.bezelMaterialOptions,
                  selected: draft.bezelMaterials,
                  onToggle: n.toggleBezelMaterial,
                ),
              ],
            ),
          ),
          _section(
            'dial',
            'DIAL',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _swatchHeading('Dial Color'),
                WatchFilterSwatchPillGrid(
                  options: WatchFilterState.dialColorOptions,
                  selected: draft.dialColors,
                  onToggle: n.toggleDialColor,
                ),
                _subLabel('Precious Stone Type'),
                _list(
                  WatchFilterState.preciousStoneTypeOptions,
                  draft.preciousStoneTypes,
                  n.togglePreciousStoneType,
                  grid: true,
                ),
                _subLabel('Glass'),
                _list(
                  WatchFilterState.glassMaterialOptions,
                  draft.glassMaterials,
                  n.toggleGlassMaterial,
                ),
                _subLabel('Dial Style / Indexes'),
                _list(
                  WatchFilterState.indexesOptions,
                  draft.indexes,
                  n.toggleIndexes,
                ),
              ],
            ),
          ),
          _section(
            'strap',
            'STRAP',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _swatchHeading('Strap Material'),
                WatchFilterSwatchPillGrid(
                  options: WatchFilterState.strapMaterialOptions,
                  selected: draft.strapMaterials,
                  onToggle: n.toggleStrapMaterial,
                ),
                _swatchHeading('Strap Color'),
                WatchFilterSwatchPillGrid(
                  options: WatchFilterState.strapColorOptions,
                  selected: draft.strapColors,
                  onToggle: n.toggleStrapColor,
                ),
              ],
            ),
          ),
          _section(
            'clasp',
            'CLASP',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _subLabel('Clasp Type'),
                _list(
                  WatchFilterState.claspTypeOptions,
                  draft.claspTypes,
                  n.toggleClaspType,
                ),
                _swatchHeading('Clasp Material'),
                WatchFilterSwatchPillGrid(
                  options: WatchFilterState.claspMaterialOptions,
                  selected: draft.claspMaterials,
                  onToggle: n.toggleClaspMaterial,
                ),
              ],
            ),
          ),
          _section(
            'crown',
            'CROWN',
            _list(
              WatchFilterState.crownTypeOptions,
              draft.crownTypes,
              n.toggleCrownType,
              grid: true,
            ),
          ),
          _section(
            'features',
            'FEATURES',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _subLabel('Features'),
                _list(
                  WatchFilterState.configurationOptions,
                  draft.configurations,
                  n.toggleConfiguration,
                  grid: true,
                ),
                _subLabel('Special Features'),
                _list(
                  WatchFilterState.materialOptions,
                  draft.materials,
                  n.toggleMaterial,
                ),
                _subLabel('Power Reserve'),
                _list(
                  WatchFilterState.powerReserveOptions,
                  draft.powerReserves,
                  n.togglePowerReserve,
                  grid: true,
                ),
                _subLabel('Water Resistance'),
                _list(
                  WatchFilterState.waterResistanceOptions,
                  draft.waterResistances,
                  n.toggleWaterResistance,
                  grid: true,
                ),
              ],
            ),
          ),
          _section(
            'model_year',
            'MODEL YEAR',
            _expandList(
              'year',
              WatchFilterState.modelYearOptions,
              draft.modelYears,
              n.toggleModelYear,
              grid: true,
            ),
          ),
          _section(
            'condition',
            'CONDITION',
            _list(
              WatchFilterState.conditionOptions,
              draft.conditions,
              n.toggleCondition,
              grid: true,
            ),
          ),
          _section(
            'authentication',
            'AUTHENTICATION',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s12,
                    AppSpacing.s4,
                    AppSpacing.s12,
                    AppSpacing.s8,
                  ),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 0,
                    crossAxisSpacing: AppSpacing.s4,
                    childAspectRatio: 3.2,
                    children: [
                      FilterBooleanCheckbox(
                        label: 'Box Included',
                        value: draft.boxIncluded,
                        onChanged: (v) => n.setBoxIncluded(v ?? false),
                      ),
                      FilterBooleanCheckbox(
                        label: 'Papers Included',
                        value: draft.papersIncluded,
                        onChanged: (v) => n.setPapersIncluded(v ?? false),
                      ),
                      FilterBooleanCheckbox(
                        label: 'Warranty Card',
                        value: draft.warrantyCardIncluded,
                        onChanged: (v) =>
                            n.setWarrantyCardIncluded(v ?? false),
                      ),
                      FilterBooleanCheckbox(
                        label: 'Full Set Only',
                        value: draft.fullSetIncluded,
                        onChanged: (v) => n.setFullSetIncluded(v ?? false),
                      ),
                    ],
                  ),
                ),
                _subLabel('Certification'),
                _list(
                  WatchFilterState.certificationOptions,
                  draft.certifications,
                  n.toggleCertification,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String key, String title, Widget child) {
    final open = _expanded[key] ?? false;
    return FilterAccordionSection(
      title: title,
      expanded: open,
      onToggle: () => setState(() => _expanded[key] = !open),
      titleStyle: AppTypography.label.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontSize: 12,
      ),
      child: child,
    );
  }

  Widget _subLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s12,
        AppSpacing.s20,
        AppSpacing.s4,
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textMutedLight,
        ),
      ),
    );
  }

  /// All-caps heading + divider used above material/color pill grids.
  Widget _swatchHeading(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text.toUpperCase(),
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }

  Widget _checkboxTile({
    required String item,
    required bool isSelected,
    required void Function(String) onToggle,
    bool compact = false,
  }) {
    return CheckboxListTile(
      dense: true,
      visualDensity: compact
          ? const VisualDensity(horizontal: -4, vertical: -4)
          : VisualDensity.compact,
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.s8 : AppSpacing.s20,
      ),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        item,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.label.copyWith(fontSize: 13),
      ),
      value: isSelected,
      activeColor: AppColors.charcoal,
      onChanged: (_) => onToggle(item),
    );
  }

  Widget _list(
    List<String> items,
    Set<String> selected,
    void Function(String) onToggle, {
    bool grid = false,
  }) {
    if (!grid) {
      return Column(
        children: [
          for (final item in items)
            _checkboxTile(
              item: item,
              isSelected: selected.contains(item),
              onToggle: onToggle,
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 44,
          crossAxisSpacing: AppSpacing.s4,
          mainAxisSpacing: 0,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return _checkboxTile(
            item: item,
            isSelected: selected.contains(item),
            onToggle: onToggle,
            compact: true,
          );
        },
      ),
    );
  }

  Widget _expandList(
    String key,
    List<String> values,
    Set<String> selected,
    void Function(String) onToggle, {
    Widget? trailing,
    bool grid = false,
  }) {
    final visible = _visible[key] ?? values.length;
    final showing = values.take(visible).toList();
    final remaining = values.length - showing.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _list(showing, selected, onToggle, grid: grid),
        if (remaining > 0)
          _showMoreButton(
            label: 'Show all ($remaining)',
            onTap: () => setState(() => _visible[key] = values.length),
          ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _showMoreButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.s20,
        bottom: AppSpacing.s12,
      ),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.bronze,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
