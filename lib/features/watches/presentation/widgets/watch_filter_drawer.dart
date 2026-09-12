import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/filters/filter_accordion_section.dart';
import '../../../../core/widgets/filters/filter_boolean_checkbox.dart';
import '../../../../core/widgets/filters/filter_full_screen_shell.dart';
import '../../application/brand_watch_filter_provider.dart';
import '../../application/brand_watch_list_provider.dart';
import '../../application/watch_filter_provider.dart';
import '../../application/watch_list_provider.dart';
import '../../data/repositories/watch_brand_assets_data.dart';
import '../../domain/models/watch_brand_categories.dart';
import '../../domain/models/watch_filter_state.dart';
import 'watch_dial_style_index_grid.dart';
import 'watch_filter_swatch_pills.dart';

/// Full-screen watch filters (same chrome as jewelry filters).
///
/// When [lockedBrand] is set, brand multi-select is hidden and models are
/// scoped to that brand (brand catalog page).
class WatchFilterDrawer extends ConsumerStatefulWidget {
  const WatchFilterDrawer({super.key, this.lockedBrand});

  final String? lockedBrand;

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
  String _brandSearchQuery = '';
  late final TextEditingController _priceMinController;
  late final TextEditingController _priceMaxController;
  late final TextEditingController _brandSearchController;

  bool get _isBrandLocked =>
      widget.lockedBrand != null && widget.lockedBrand!.trim().isNotEmpty;

  String get _lockedBrandName => widget.lockedBrand!.trim();

  WatchFilterState get _draft => _isBrandLocked
      ? ref.watch(brandWatchFilterDraftProvider)
      : ref.watch(watchFilterDraftProvider);

  WatchFilterStateMutator get _draftNotifier => _isBrandLocked
      ? ref.read(brandWatchFilterDraftProvider.notifier)
      : ref.read(watchFilterDraftProvider.notifier);

  @override
  void initState() {
    super.initState();
    final draft = _isBrandLocked
        ? ref.read(brandWatchFilterDraftProvider)
        : ref.read(watchFilterDraftProvider);
    _priceMinController = TextEditingController(text: _priceText(draft.priceMin));
    _priceMaxController = TextEditingController(text: _priceText(draft.priceMax));
    _brandSearchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isBrandLocked) {
        ref.read(brandWatchFilterDraftProvider.notifier).syncFromApplied();
        _syncPriceControllers(ref.read(brandWatchFilterDraftProvider));
      } else {
        ref.read(watchFilterDraftProvider.notifier).syncFromApplied();
        _syncPriceControllers(ref.read(watchFilterDraftProvider));
      }
    });
  }

  @override
  void dispose() {
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _brandSearchController.dispose();
    super.dispose();
  }

  String _priceText(double value) =>
      value > 0 ? value.toStringAsFixed(0) : '';

  void _syncPriceControllers(WatchFilterState draft) {
    final minText = _priceText(draft.priceMin);
    final maxText = _priceText(draft.priceMax);
    if (_priceMinController.text != minText) {
      _priceMinController.text = minText;
    }
    if (_priceMaxController.text != maxText) {
      _priceMaxController.text = maxText;
    }
  }

  List<String> get _allBrandsAlphabetical =>
      watchBrandCategories.expand((g) => g.brands).toList(growable: false);

  List<String> _modelOptions(WatchFilterState draft) {
    const byBrand = WatchCatalogBrands.modelsByBrand;
    if (_isBrandLocked) {
      return List<String>.from(byBrand[_lockedBrandName] ?? const [])..sort();
    }
    if (draft.brands.isEmpty) {
      return byBrand.values.expand((m) => m).toSet().toList()..sort();
    }
    final models = <String>{};
    for (final brand in draft.brands) {
      models.addAll(byBrand[brand] ?? const []);
    }
    return models.toList()..sort();
  }

  List<String> _filteredBrandOptions() {
    final q = _brandSearchQuery.trim().toLowerCase();
    final source = q.isNotEmpty
        ? _allBrandsAlphabetical
        : (_showAllBrands
            ? _allBrandsAlphabetical
            : WatchFilterState.popularBrandOptions);
    if (q.isEmpty) return source;
    return source
        .where((b) => b.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    _syncPriceControllers(draft);
    final n = _draftNotifier;
    final resultCount = _isBrandLocked
        ? ref.watch(
            brandWatchListProvider.select((v) => v.valueOrNull?.totalCount),
          )
        : ref.watch(
            watchListProvider.select((v) => v.valueOrNull?.totalCount),
          );
    final brandOptions = _filteredBrandOptions();
    final modelOptions = _modelOptions(draft);
    final searchingBrands = _brandSearchQuery.trim().isNotEmpty;

    return FilterFullScreenShell(
      onReset: () {
        n.resetDraftKeepingSearch();
        _brandSearchController.clear();
        _brandSearchQuery = '';
        _syncPriceControllers(
          _isBrandLocked
              ? ref.read(brandWatchFilterDraftProvider)
              : ref.read(watchFilterDraftProvider),
        );
        setState(() {});
      },
      showResultsLabel: resultCount == null
          ? context.tr(CatalogL10n.showResults)
          : '${context.tr(CatalogL10n.showResults)} ($resultCount)',
      onShowResults: () {
        if (_isBrandLocked) {
          ref.read(brandWatchFilterDraftProvider.notifier).apply();
          ref.read(brandWatchListProvider.notifier).refresh();
        } else {
          ref.read(watchFilterDraftProvider.notifier).apply();
          ref.read(watchListProvider.notifier).refresh();
        }
        context.goBack();
      },
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s24),
        children: [
          _section(
            'brand',
            context.tr(CatalogL10n.brandLabel),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isBrandLocked) ...[
                  _subLabel('Brand'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s20,
                      0,
                      AppSpacing.s20,
                      AppSpacing.s8,
                    ),
                    child: Text(
                      _lockedBrandName,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ] else ...[
                  _subLabel('Brand'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s20,
                      0,
                      AppSpacing.s20,
                      AppSpacing.s8,
                    ),
                    child: TextField(
                      controller: _brandSearchController,
                      onChanged: (value) =>
                          setState(() => _brandSearchQuery = value),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: context.tr(CatalogL10n.searchBrands),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _brandSearchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _brandSearchController.clear();
                                  setState(() => _brandSearchQuery = '');
                                },
                              ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s12,
                          vertical: AppSpacing.s12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.r8),
                        ),
                      ),
                    ),
                  ),
                  if (brandOptions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s20,
                        0,
                        AppSpacing.s20,
                        AppSpacing.s12,
                      ),
                      child: Text(
                        'No brands found',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    )
                  else
                    _expandList(
                      'brand',
                      brandOptions,
                      draft.brands,
                      n.toggleBrand,
                      showAll: searchingBrands,
                      trailing: !searchingBrands && !_showAllBrands
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
                ],
                _subLabel('Model'),
                _expandList('model', modelOptions, draft.models, n.toggleModel),
              ],
            ),
          ),
          _section(
            'watch_style',
            context.tr(CatalogL10n.watchStyle),
            _list(
              WatchFilterState.styleOptions,
              draft.categories,
              n.toggleStyle,
              grid: true,
            ),
          ),
          _section(
            'availability',
            context.tr(CatalogL10n.availability),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s20,
                    0,
                    AppSpacing.s20,
                    AppSpacing.s8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border(context)),
                      borderRadius: BorderRadius.circular(AppSpacing.r8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: draft.selectedAvailability,
                        items: WatchFilterState.availabilityOptions
                            .map(
                              (opt) => DropdownMenuItem<String>(
                                value: opt,
                                child: Text(_availabilityLabel(context, opt)),
                              ),
                            )
                            .toList(),
                        onChanged: n.updateAvailability,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s12,
                    AppSpacing.s4,
                    AppSpacing.s12,
                    AppSpacing.s8,
                  ),
                  child: FilterBooleanCheckbox(
                    label: context.tr(CatalogL10n.makeOffer),
                    value: draft.makeAnOffer,
                    onChanged: (v) => n.setMakeAnOffer(v ?? false),
                  ),
                ),
              ],
            ),
          ),
          _section(
            'with_media',
            context.tr(CatalogL10n.withMedia),
            _list(
              WatchFilterState.withMediaOptions,
              draft.withMedia,
              n.toggleWithMedia,
              grid: true,
            ),
          ),
          _section(
            'gender',
            context.tr(CatalogL10n.gender),
            _list(
              WatchFilterState.genderOptions,
              draft.genders,
              n.toggleGender,
              grid: true,
            ),
          ),
          _section(
            'price_range',
            context.tr(CatalogL10n.priceRange),
            _priceRangeInputs(n),
          ),
          _section(
            'movement',
            context.tr(CatalogL10n.movement),
            _list(
              WatchFilterState.movementOptions,
              draft.movements,
              n.toggleMovement,
            ),
          ),
          _section(
            'case',
            context.tr(CatalogL10n.watchCase),
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
            context.tr(CatalogL10n.bezel),
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
            context.tr(CatalogL10n.dial),
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
                _swatchHeading('Dial Style / Indexes'),
                WatchDialStyleIndexGrid(
                  selected: draft.indexes,
                  onToggle: n.toggleIndexes,
                ),
              ],
            ),
          ),
          _section(
            'strap',
            context.tr(CatalogL10n.strap),
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
            context.tr(CatalogL10n.clasp),
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
            context.tr(CatalogL10n.crown),
            _list(
              WatchFilterState.crownTypeOptions,
              draft.crownTypes,
              n.toggleCrownType,
              grid: true,
            ),
          ),
          _section(
            'features',
            context.tr(CatalogL10n.features),
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
            context.tr(CatalogL10n.modelYear),
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
            context.tr(CatalogL10n.condition),
            _list(
              WatchFilterState.conditionOptions,
              draft.conditions,
              n.toggleCondition,
              grid: true,
            ),
          ),
          _section(
            'authentication',
            context.tr(CatalogL10n.authentication),
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
                        label: context.tr(CatalogL10n.boxIncluded),
                        value: draft.boxIncluded,
                        onChanged: (v) => n.setBoxIncluded(v ?? false),
                      ),
                      FilterBooleanCheckbox(
                        label: context.tr(CatalogL10n.papersIncluded),
                        value: draft.papersIncluded,
                        onChanged: (v) => n.setPapersIncluded(v ?? false),
                      ),
                      FilterBooleanCheckbox(
                        label: context.tr(CatalogL10n.warrantyCard),
                        value: draft.warrantyCardIncluded,
                        onChanged: (v) => n.setWarrantyCardIncluded(v ?? false),
                      ),
                      FilterBooleanCheckbox(
                        label: context.tr(CatalogL10n.fullSetOnly),
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

  Widget _priceRangeInputs(WatchFilterStateMutator n) {
    final muted = AppColors.textMuted(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        0,
        AppSpacing.s20,
        AppSpacing.s16,
      ),
      child: Row(
        children: [
          Expanded(
            child: _WatchPriceField(
              controller: _priceMinController,
              label: 'Min (\$)',
              muted: muted,
              onChanged: (value) => n.setPriceRange(
                min: double.tryParse(value) ?? 0,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: _WatchPriceField(
              controller: _priceMaxController,
              label: 'Max (\$)',
              muted: muted,
              onChanged: (value) => n.setPriceRange(
                max: double.tryParse(value) ?? 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _availabilityLabel(BuildContext context, String option) {
    return switch (option) {
      'All' => context.tr(RemainingL10n.all),
      'Available' => context.tr(CatalogL10n.available),
      'On Memo' => context.tr(CatalogL10n.onMemo),
      'On Hold' => context.tr(CatalogL10n.onHold),
      'Sold' => context.tr(CatalogL10n.sold),
      _ => option,
    };
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
          color: AppColors.textMuted(context),
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
    bool showAll = false,
  }) {
    final visible =
        showAll ? values.length : (_visible[key] ?? values.length);
    final showing = values.take(visible).toList();
    final remaining = values.length - showing.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _list(showing, selected, onToggle, grid: grid),
        if (remaining > 0)
          _showMoreButton(
            label: context.tr(CatalogL10n.showAllCount, {'count': remaining}),
            onTap: () => setState(() => _visible[key] = values.length),
          ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _showMoreButton({required String label, required VoidCallback onTap}) {
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

class _WatchPriceField extends StatelessWidget {
  const _WatchPriceField({
    required this.controller,
    required this.label,
    required this.muted,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final Color muted;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: muted)),
        const SizedBox(height: AppSpacing.s4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          decoration: InputDecoration(
            isDense: true,
            hintText: '0',
            hintStyle: AppTypography.caption.copyWith(color: muted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.r8),
            ),
          ),
        ),
      ],
    );
  }
}
