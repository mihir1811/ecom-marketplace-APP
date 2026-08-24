import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:gemstone/core/widgets/filters/filter_boolean_checkbox.dart';
import 'package:gemstone/core/widgets/filters/filter_chip.dart';
import 'package:gemstone/core/widgets/filters/filter_range_slider.dart';
import 'package:gemstone/core/widgets/filters/filter_section_header.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../application/jewelry_list_provider.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../widgets/jewelry_product_card.dart';
import '../../../../core/utils/app_currency.dart';

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

    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppTopBar(
            title: 'Filters',
            extraActions: [
              TextButton(
                onPressed: n.reset,
                child: Text(
                  'Reset All',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s24),
                  children: [
                    _section(
                      'availability',
                      'AVAILABILITY',
                      _chipWrap(
                        JewelryFilterState.availabilityOptions,
                        draft.availability,
                        n.toggleAvailability,
                      ),
                    ),
                    _section(
                      'media',
                      'WITH MEDIA',
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                        ),
                        child: FilterBooleanCheckbox(
                          label: 'Show items with images/media only',
                          value: draft.withMediaOnly,
                          onChanged: (v) => n.setWithMediaOnly(v ?? false),
                        ),
                      ),
                    ),
                    _section(
                      'gender',
                      'GENDER',
                      _chipWrap(
                        JewelryFilterState.genderOptions,
                        draft.genders,
                        n.toggleGender,
                      ),
                    ),
                    _section(
                      'price',
                      'PRICE RANGE',
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                        ),
                        child: FilterRangeSlider(
                          title: 'Price',
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
                      'OCCASION',
                      _chipWrap(
                        JewelryFilterState.occasionOptions,
                        draft.occasions,
                        n.toggleOccasion,
                      ),
                    ),
                    _section(
                      'metal',
                      'METAL',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.s16,
                              0,
                              AppSpacing.s16,
                              AppSpacing.s8,
                            ),
                            child: FilterSectionHeader(title: 'Metal Type'),
                          ),
                          _chipWrap(
                            JewelryFilterState.metalTypeOptions,
                            draft.metalTypes,
                            n.toggleMetalType,
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.s16,
                              AppSpacing.s12,
                              AppSpacing.s16,
                              AppSpacing.s8,
                            ),
                            child: FilterSectionHeader(title: 'Metal Color'),
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
                                      selected: draft.metalColors.contains(
                                        color,
                                      ),
                                      onTap: () => n.toggleMetalColor(color),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.s16,
                              AppSpacing.s16,
                              AppSpacing.s16,
                              AppSpacing.s8,
                            ),
                            child: FilterSectionHeader(title: 'Metal Purity'),
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
                              title: 'Metal Weight',
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
                                  () =>
                                      _metalAdvancedOpen = !_metalAdvancedOpen,
                                ),
                                icon: Icon(
                                  _metalAdvancedOpen
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                ),
                                label: const Text('Advanced'),
                              ),
                            ),
                          ),
                          if (_metalAdvancedOpen) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.s16,
                                0,
                                AppSpacing.s16,
                                AppSpacing.s8,
                              ),
                              child: FilterSectionHeader(title: 'Metal Finish'),
                            ),
                            _chipWrap(
                              JewelryFilterState.metalFinishOptions,
                              draft.metalFinishes,
                              n.toggleMetalFinish,
                            ),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.s16,
                                0,
                                AppSpacing.s16,
                                AppSpacing.s8,
                              ),
                              child: FilterSectionHeader(title: 'Plating'),
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
                      'STONE',
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
                          const Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.s16,
                              0,
                              AppSpacing.s16,
                              AppSpacing.s8,
                            ),
                            child: FilterSectionHeader(title: 'Stone Category'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s16,
                            ),
                            child: TextField(
                              onChanged: (v) =>
                                  setState(() => _stoneSearch = v),
                              scrollPadding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                80,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search...',
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
                          const Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.s16,
                              AppSpacing.s12,
                              AppSpacing.s16,
                              AppSpacing.s8,
                            ),
                            child: FilterSectionHeader(title: 'Stone Shape'),
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
                              title: 'Stone Weight',
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
                                  () =>
                                      _stoneAdvancedOpen = !_stoneAdvancedOpen,
                                ),
                                icon: Icon(
                                  _stoneAdvancedOpen
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                ),
                                label: const Text('Advanced'),
                              ),
                            ),
                          ),
                          if (_stoneAdvancedOpen) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.s16,
                                0,
                                AppSpacing.s16,
                                AppSpacing.s8,
                              ),
                              child: FilterSectionHeader(title: 'Stone Color'),
                            ),
                            _chipWrap(
                              JewelryFilterState.stoneColorOptions,
                              draft.stoneColors,
                              n.toggleStoneColor,
                            ),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.s16,
                                0,
                                AppSpacing.s16,
                                AppSpacing.s8,
                              ),
                              child: FilterSectionHeader(
                                title: 'Stone Clarity',
                              ),
                            ),
                            _chipWrap(
                              JewelryFilterState.stoneClarityOptions,
                              draft.stoneClarities,
                              n.toggleStoneClarity,
                            ),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.s16,
                                0,
                                AppSpacing.s16,
                                AppSpacing.s8,
                              ),
                              child: FilterSectionHeader(
                                title: 'Stone Setting',
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
                      'CERTIFICATION',
                      _chipWrap(
                        JewelryFilterState.certificationOptions,
                        draft.certifications,
                        n.toggleCertification,
                      ),
                    ),
                    _section(
                      'condition',
                      'CONDITION',
                      _chipWrap(
                        JewelryFilterState.conditionOptions,
                        draft.conditions,
                        n.toggleCondition,
                      ),
                    ),
                    _section(
                      'delivery',
                      'DELIVERY TIME',
                      _chipWrap(
                        JewelryFilterState.deliveryTimeOptions,
                        {if (draft.deliveryTime != null) draft.deliveryTime!},
                        (v) => n.setDeliveryTime(
                          draft.deliveryTime == v ? null : v,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s12,
                  AppSpacing.s16,
                  AppSpacing.s16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bg(context),
                  border: Border(
                    top: BorderSide(color: AppColors.border(context)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: n.reset,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.r8,
                              ),
                            ),
                          ),
                          child: const Text('Reset Filters'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.isDark(context)
                                ? AppColors.bronze
                                : AppColors.charcoal,
                            foregroundColor: AppColors.warmWhite,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.r8,
                              ),
                            ),
                          ),
                          onPressed: () {
                            n.apply();
                            ref.read(jewelryListProvider.notifier).refresh();
                            context.pop();
                          },
                          child: Text(
                            resultCount == null
                                ? 'Show Results'
                                : 'Show Results ($resultCount)',
                            style: AppTypography.label.copyWith(
                              color: AppColors.warmWhite,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

  List<Widget> _categorySpecificSections(
    JewelryFilterState draft,
    JewelryFilterDraftNotifier n,
  ) {
    final parent = JewelryFilterState.parentCategoryOrDefault(draft.category);
    return switch (parent) {
      'Bracelets' => [
        _section(
          'braceletSize',
          'BRACELET SIZE',
          _chipWrap(
            JewelryFilterState.braceletSizeOptions,
            draft.braceletSizes,
            n.toggleBraceletSize,
          ),
        ),
        _section(
          'braceletLength',
          'BRACELET LENGTH',
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
          'CHAIN LENGTH',
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
          'NECKLACE LENGTH',
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
          'RING SIZE',
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
