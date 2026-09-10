import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/filters/filter_boolean_checkbox.dart';
import '../../../../core/widgets/filters/filter_chip.dart';
import '../../../../core/widgets/filters/filter_full_screen_shell.dart';
import '../../../../core/widgets/filters/filter_range_slider.dart';
import '../../../../core/widgets/filters/filter_section_header.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../application/jewelry_list_provider.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../widgets/jewelry_product_card.dart';

class JewelryFilterScreen extends ConsumerStatefulWidget {
  const JewelryFilterScreen({super.key});

  @override
  ConsumerState<JewelryFilterScreen> createState() =>
      _JewelryFilterScreenState();
}

class _JewelryFilterScreenState extends ConsumerState<JewelryFilterScreen> {
  final Map<String, bool> _expanded = {
    'availability': true,
    'media': true,
    'gender': true,
    'price': true,
    'occasion': true,
    'metal': false,
    'stone': false,
    'braceletSize': false,
    'braceletLength': false,
    'chainLength': false,
    'necklaceLength': false,
    'ringSize': false,
    'cert': false,
    'condition': false,
    'delivery': false,
  };

  bool _metalAdvancedOpen = false;
  bool _stoneAdvancedOpen = false;
  String _stoneSearch = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jewelryFilterDraftProvider.notifier).syncFromApplied();
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(jewelryFilterDraftProvider);
    final listState = ref.watch(jewelryListProvider).valueOrNull;
    final n = ref.read(jewelryFilterDraftProvider.notifier);
    final resultCount = listState?.totalCount;

    return FilterFullScreenShell(
      onReset: n.reset,
      showResultsLabel: resultCount == null
          ? context.tr(CatalogL10n.showResults)
          : '${context.tr(CatalogL10n.showResults)} ($resultCount)',
      onShowResults: () {
        n.apply();
        ref.read(jewelryListProvider.notifier).refresh();
        context.goBack();
      },
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s24),
        children: [
          _section(
            'availability',
            context.tr(CatalogL10n.availability),
            _chipWrap(
              JewelryFilterState.availabilityOptions,
              draft.availability,
              n.toggleAvailability,
            ),
          ),
          _section(
            'media',
            context.tr(CatalogL10n.withMedia),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
              ),
              child: FilterBooleanCheckbox(
                label: context.tr(CatalogL10n.mediaOnly),
                value: draft.withMediaOnly,
                onChanged: (v) => n.setWithMediaOnly(v ?? false),
              ),
            ),
          ),
          _section(
            'gender',
            context.tr(CatalogL10n.gender),
            _chipWrap(
              JewelryFilterState.genderOptions,
              draft.genders,
              n.toggleGender,
            ),
          ),
          _section(
            'price',
            context.tr(CatalogL10n.priceRange),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
              ),
              child: FilterRangeSlider(
                title: context.tr(CatalogL10n.price),
                minLimit: JewelryFilterState.priceMinLimit,
                maxLimit: JewelryFilterState.priceMaxLimit,
                currentMin: draft.priceMin,
                currentMax: draft.priceMax,
                unitPrefix: AppCurrency.symbol,
                isInteger: true,
                onChanged: n.setPriceRange,
                onClear: n.clearPriceRange,
              ),
            ),
          ),
          _section(
            'occasion',
            context.tr(CatalogL10n.occasion),
            _chipWrap(
              JewelryFilterState.occasionOptions,
              draft.occasions,
              n.toggleOccasion,
            ),
          ),
          _section(
            'metal',
            context.tr(CatalogL10n.metal),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    0,
                    AppSpacing.s16,
                    AppSpacing.s8,
                  ),
                  child: FilterSectionHeader(
                    title: context.tr(CatalogL10n.metalType),
                  ),
                ),
                _chipWrap(
                  JewelryFilterState.metalTypeOptions,
                  draft.metalTypes,
                  n.toggleMetalType,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s12,
                    AppSpacing.s16,
                    AppSpacing.s8,
                  ),
                  child: FilterSectionHeader(
                    title: context.tr(CatalogL10n.metalColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: AppSpacing.s12,
                      runSpacing: AppSpacing.s12,
                      children: [
                        for (final color
                            in JewelryFilterState.metalColorOptions)
                          _MetalColorSwatch(
                            label: color,
                            selected: draft.metalColors.contains(color),
                            onTap: () => n.toggleMetalColor(color),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s16,
                    AppSpacing.s16,
                    AppSpacing.s8,
                  ),
                  child: FilterSectionHeader(
                    title: context.tr(CatalogL10n.metalPurity),
                  ),
                ),
                _chipWrap(
                  JewelryFilterState.metalPurityOptions,
                  draft.metalPurities,
                  n.toggleMetalPurity,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s8,
                  ),
                  child: FilterRangeSlider(
                    title: context.tr(CatalogL10n.metalWeight),
                    minLimit: JewelryFilterState.metalWeightMinLimit,
                    maxLimit: JewelryFilterState.metalWeightMaxLimit,
                    currentMin: draft.metalWeightMin,
                    currentMax: draft.metalWeightMax,
                    unitSuffix: 'g',
                    isInteger: true,
                    onChanged: n.setMetalWeight,
                    onClear: n.clearMetalWeight,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(
                        () => _metalAdvancedOpen = !_metalAdvancedOpen,
                      ),
                      icon: Icon(
                        _metalAdvancedOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                      ),
                      label: Text(context.tr(CatalogL10n.advanced)),
                    ),
                  ),
                ),
                if (_metalAdvancedOpen) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      0,
                      AppSpacing.s16,
                      AppSpacing.s8,
                    ),
                    child: FilterSectionHeader(
                      title: context.tr(CatalogL10n.metalFinish),
                    ),
                  ),
                  _chipWrap(
                    JewelryFilterState.metalFinishOptions,
                    draft.metalFinishes,
                    n.toggleMetalFinish,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      0,
                      AppSpacing.s16,
                      AppSpacing.s8,
                    ),
                    child: FilterSectionHeader(
                      title: context.tr(CatalogL10n.plating),
                    ),
                  ),
                  _chipWrap(
                    JewelryFilterState.platingOptions,
                    draft.platings,
                    n.togglePlating,
                  ),
                ],
                const SizedBox(height: AppSpacing.s8),
              ],
            ),
          ),
          _section(
            'stone',
            context.tr(CatalogL10n.stone),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    0,
                    AppSpacing.s16,
                    AppSpacing.s12,
                  ),
                  child: Row(
                    children: [
                      for (final opt
                          in JewelryFilterState.stoneTypeOptions) ...[
                        if (opt !=
                            JewelryFilterState.stoneTypeOptions.first)
                          const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: FilterChipWidget(
                            label: opt,
                            isSelected:
                                (draft.stoneType ?? 'Natural') == opt,
                            onTap: () => n.setStoneType(opt),
                            centerLabel: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    0,
                    AppSpacing.s16,
                    AppSpacing.s8,
                  ),
                  child: FilterSectionHeader(
                    title: context.tr(CatalogL10n.stoneCategory),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _stoneSearch = v),
                    scrollPadding: const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      80,
                    ),
                    decoration: InputDecoration(
                      hintText: context.tr(CatalogL10n.search),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.r12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                _chipWrap(
                  JewelryFilterState.stoneCategoryOptions
                      .where(
                        (o) => o.toLowerCase().contains(
                          _stoneSearch.toLowerCase(),
                        ),
                      )
                      .toList(),
                  draft.stoneCategories,
                  n.toggleStoneCategory,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s12,
                    AppSpacing.s16,
                    AppSpacing.s8,
                  ),
                  child: FilterSectionHeader(
                    title: context.tr(CatalogL10n.stoneShape),
                  ),
                ),
                _chipWrap(
                  JewelryFilterState.stoneShapeOptions,
                  draft.stoneShapes,
                  n.toggleStoneShape,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s8,
                  ),
                  child: FilterRangeSlider(
                    title: context.tr(CatalogL10n.stoneWeight),
                    minLimit: JewelryFilterState.stoneWeightMinLimit,
                    maxLimit: JewelryFilterState.stoneWeightMaxLimit,
                    currentMin: draft.stoneWeightMin,
                    currentMax: draft.stoneWeightMax,
                    unitSuffix: 'ct',
                    onChanged: n.setStoneWeight,
                    onClear: n.clearStoneWeight,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(
                        () => _stoneAdvancedOpen = !_stoneAdvancedOpen,
                      ),
                      icon: Icon(
                        _stoneAdvancedOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                      ),
                      label: Text(context.tr(CatalogL10n.advanced)),
                    ),
                  ),
                ),
                if (_stoneAdvancedOpen) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      0,
                      AppSpacing.s16,
                      AppSpacing.s8,
                    ),
                    child: FilterSectionHeader(
                      title: context.tr(CatalogL10n.stoneColor),
                    ),
                  ),
                  _chipWrap(
                    JewelryFilterState.stoneColorOptions,
                    draft.stoneColors,
                    n.toggleStoneColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      0,
                      AppSpacing.s16,
                      AppSpacing.s8,
                    ),
                    child: FilterSectionHeader(
                      title: context.tr(CatalogL10n.stoneClarity),
                    ),
                  ),
                  _chipWrap(
                    JewelryFilterState.stoneClarityOptions,
                    draft.stoneClarities,
                    n.toggleStoneClarity,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      0,
                      AppSpacing.s16,
                      AppSpacing.s8,
                    ),
                    child: FilterSectionHeader(
                      title: context.tr(CatalogL10n.stoneSetting),
                    ),
                  ),
                  _chipWrap(
                    JewelryFilterState.stoneSettingOptions,
                    draft.stoneSettings,
                    n.toggleStoneSetting,
                  ),
                ],
                const SizedBox(height: AppSpacing.s8),
              ],
            ),
          ),
          ..._categorySpecificSections(draft, n),
          _section(
            'cert',
            context.tr(CatalogL10n.certification),
            _chipWrap(
              JewelryFilterState.certificationOptions,
              draft.certifications,
              n.toggleCertification,
            ),
          ),
          _section(
            'condition',
            context.tr(CatalogL10n.condition),
            _chipWrap(
              JewelryFilterState.conditionOptions,
              draft.conditions,
              n.toggleCondition,
            ),
          ),
          _section(
            'delivery',
            context.tr(CatalogL10n.deliveryTime),
            _chipWrap(
              JewelryFilterState.deliveryTimeOptions,
              {if (draft.deliveryTime != null) draft.deliveryTime!},
              (v) =>
                  n.setDeliveryTime(draft.deliveryTime == v ? null : v),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _categorySpecificSections(
    JewelryFilterState draft,
    JewelryFilterDraftNotifier n,
  ) {
    final parent = JewelryFilterState.parentCategoryOrDefault(draft.category);
    return switch (parent) {
      'Bracelets' => [
        _section(
          'braceletSize',
          context.tr(CatalogL10n.braceletSize),
          _chipWrap(
            JewelryFilterState.braceletSizeOptions,
            draft.braceletSizes,
            n.toggleBraceletSize,
          ),
        ),
        _section(
          'braceletLength',
          context.tr(CatalogL10n.braceletLength),
          _chipWrap(
            JewelryFilterState.braceletLengthOptions,
            draft.braceletLengths,
            n.toggleBraceletLength,
          ),
        ),
      ],
      'Chains' => [
        _section(
          'chainLength',
          context.tr(CatalogL10n.chainLength),
          _chipWrap(
            JewelryFilterState.chainLengthOptions,
            draft.chainLengths,
            n.toggleChainLength,
          ),
        ),
      ],
      'Necklaces' => [
        _section(
          'necklaceLength',
          context.tr(CatalogL10n.necklaceLength),
          _chipWrap(
            JewelryFilterState.necklaceLengthOptions,
            draft.necklaceLengths,
            n.toggleNecklaceLength,
          ),
        ),
      ],
      'Rings' => [
        _section(
          'ringSize',
          context.tr(CatalogL10n.ringSize),
          _chipWrap(
            JewelryFilterState.ringSizeOptions,
            draft.ringSizes,
            n.toggleRingSize,
          ),
        ),
      ],
      _ => const <Widget>[],
    };
  }

  Widget _section(String key, String title, Widget child) {
    final open = _expanded[key] ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded[key] = !open),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(
                  open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (open) child,
        const Divider(height: 1),
      ],
    );
  }

  Widget _chipWrap(
    List<String> options,
    Set<String> selected,
    void Function(String) onToggle,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        0,
        AppSpacing.s16,
        AppSpacing.s12,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final opt in options)
              FilterChipWidget(
                label: opt,
                isSelected: selected.contains(opt),
                onTap: () => onToggle(opt),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetalColorSwatch extends StatelessWidget {
  const _MetalColorSwatch({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.selectedFill(context)
                      : AppColors.border(context),
                  width: selected ? 2 : 1,
                ),
              ),
              child: ClipOval(child: _MetalColorCircle(label: label)),
            ),
            if (selected)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.check, size: 14, color: AppColors.bronze),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetalColorCircle extends StatelessWidget {
  const _MetalColorCircle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label == 'Two-Tone') {
      return const SizedBox.expand(
        child: CustomPaint(
          painter: _HalfCircleMetalPainter(
            colors: [AppSwatches.yellowGold, AppSwatches.whiteGold],
          ),
        ),
      );
    }
    if (label == 'Tri-Color') {
      return const SizedBox.expand(
        child: CustomPaint(
          painter: _TriSegmentMetalPainter(
            colors: [
              AppSwatches.yellowGold,
              AppSwatches.whiteGold,
              AppSwatches.roseGold,
            ],
          ),
        ),
      );
    }
    return ColoredBox(color: jewelryMetalSwatch(label));
  }
}

class _HalfCircleMetalPainter extends CustomPainter {
  const _HalfCircleMetalPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = colors[0];
    canvas.drawArc(
      rect,
      -3.141592653589793 / 2,
      3.141592653589793,
      true,
      paint,
    );

    paint.color = colors[1];
    canvas.drawArc(rect, 3.141592653589793 / 2, 3.141592653589793, true, paint);
  }

  @override
  bool shouldRepaint(covariant _HalfCircleMetalPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

class _TriSegmentMetalPainter extends CustomPainter {
  const _TriSegmentMetalPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;
    const sweep = 2 * 3.141592653589793 / 3;
    var start = -3.141592653589793 / 2;

    for (final color in colors) {
      paint.color = color;
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _TriSegmentMetalPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
