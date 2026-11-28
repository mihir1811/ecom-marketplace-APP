import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/catalog_search_filter_shell.dart';
import '../../../../core/widgets/filters/filter_boolean_checkbox.dart';
import '../../../../core/widgets/filters/filter_section_header.dart';
import '../../../../core/widgets/luxe/luxe_chip_group.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_finder.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_range_fields.dart';
import '../../application/rough_detail_providers.dart';
import '../../application/rough_filter_provider.dart';
import '../../domain/models/rough_facets.dart';
import '../../domain/models/rough_filter_state.dart';
import '../../domain/models/rough_parcel.dart';

/// Rough filters on the shared luxe finder layout. Chip values and their
/// counts come from GET /rough-diamond/filters for the chosen tab; a group
/// with nothing listed is hidden. Edits a draft applied on "Show results".
class RoughFiltersScreen extends ConsumerStatefulWidget {
  const RoughFiltersScreen({super.key});

  @override
  ConsumerState<RoughFiltersScreen> createState() => _RoughFiltersScreenState();
}

class _RoughFiltersScreenState extends ConsumerState<RoughFiltersScreen>
    with
        CatalogSearchScrollMixin,
        LuxeFinderMixin<RoughFiltersScreen, RoughFilterSection> {
  @override
  final ScrollController catalogScrollController = ScrollController();
  @override
  final GlobalKey catalogNavKey = GlobalKey();
  @override
  double get catalogNavHeight => 56;

  @override
  List<RoughFilterSection> get finderVisibleSections =>
      RoughFilterSection.values;

  RoughFilterDraftNotifier get _n =>
      ref.read(roughFilterDraftProvider.notifier);

  @override
  void initState() {
    super.initState();
    catalogScrollController.addListener(finderOnScroll);
  }

  @override
  void dispose() {
    catalogScrollController
      ..removeListener(finderOnScroll)
      ..dispose();
    disposeFinder();
    super.dispose();
  }

  void _reset() {
    final previous = ref.read(roughFilterDraftProvider);
    _n.reset();
    showLuxeToast(
      context,
      context.tr(DiamondFlowL10n.filtersCleared),
      actionLabel: context.tr(DiamondFlowL10n.undo),
      onAction: () => _n.replaceDraft(previous),
    );
  }

  void _showResults() {
    // Applying changes the list's filters, which reloads it.
    _n.apply();
    context.goBack();
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final draft = ref.watch(roughFilterDraftProvider);
    final facets =
        ref.watch(roughFacetsProvider(draft.diamondType)).value ??
        RoughFacets.empty;
    final summary = RoughFilterSummary.of(draft);
    return LuxeFinderScaffold<RoughFilterSection>(
      title: '',
      onBack: () => context.goBack(),
      controls: LuxeSegmented<RoughDiamondType>(
        options: RoughDiamondType.values,
        selected: draft.diamondType,
        onChanged: _n.setType,
        labelOf: (t) => context.tr(
          t == RoughDiamondType.lab ? RoughFlowL10n.lab : RoughFlowL10n.natural,
        ),
      ),
      sections: RoughFilterSection.values,
      active: finderActive,
      labelOf: (s) => _sectionTitle(context, s),
      countOf: summary.count,
      pillKeyOf: finderPillKey,
      onJump: finderJumpTo,
      navKey: catalogNavKey,
      sectionBuilder: (s) => _section(context, s, draft, facets, summary),
      scrollController: catalogScrollController,
      scrollOffset: finderOffset,
      onScrollNotification: catalogHandleScrollNotification,
      actionBar: LuxeFinderActionBar(
        activeCount: summary.total,
        onReset: summary.total == 0 ? null : _reset,
        onShow: _showResults,
        showLabel: context.tr(CatalogL10n.showResults),
        resetLabel: context.tr(DiamondFlowL10n.reset),
      ),
    );
  }

  String _sectionTitle(BuildContext context, RoughFilterSection s) =>
      context.tr(switch (s) {
        RoughFilterSection.crystal => RoughFlowL10n.sectionCrystal,
        RoughFilterSection.sizePrice => RoughFlowL10n.sectionSizePrice,
        RoughFilterSection.colorClarity => RoughFlowL10n.sectionColorClarity,
        RoughFilterSection.quality => RoughFlowL10n.sectionQuality,
        RoughFilterSection.parcel => RoughFlowL10n.sectionParcel,
        RoughFilterSection.origin => RoughFlowL10n.sectionOrigin,
        RoughFilterSection.listing => RoughFlowL10n.sectionListing,
      });

  Widget _section(
    BuildContext context,
    RoughFilterSection s,
    RoughFilterState d,
    RoughFacets f,
    RoughFilterSummary summary,
  ) {
    final lab = d.diamondType == RoughDiamondType.lab;
    final (IconData icon, List<Widget> parts) = switch (s) {
      RoughFilterSection.crystal => (
        Icons.landscape_outlined,
        [
          if (lab) _chips(context, d, f, 'growthType'),
          _chips(context, d, f, 'crystalShape'),
          _chips(context, d, f, 'crystalCondition'),
          _chips(context, d, f, 'transparency'),
          _chips(context, d, f, 'surfaceCondition'),
        ],
      ),
      RoughFilterSection.sizePrice => (
        Icons.scale_outlined,
        [
          for (final r in RoughRange.values) _range(context, d, f, r),
          _yield(context, d),
        ],
      ),
      RoughFilterSection.colorClarity => (
        Icons.palette_outlined,
        [
          _grades(
            context,
            d,
            key: 'colorGrades',
            facet: f.of('colorRange'),
            options: RoughFilterState.colorGradeOptions,
          ),
          _words(context, d, key: 'colorWords', facet: f.of('colorRange')),
          _grades(
            context,
            d,
            key: 'clarityGrades',
            facet: f.of('clarityRange'),
            options: RoughFilterState.clarityGradeOptions,
          ),
          _words(context, d, key: 'clarityWords', facet: f.of('clarityRange')),
          _chips(context, d, f, 'colorDistribution'),
          _chips(context, d, f, 'fluorescence'),
        ],
      ),
      RoughFilterSection.quality => (
        Icons.workspace_premium_outlined,
        [
          _chips(context, d, f, 'roughQuality'),
          _chips(context, d, f, 'manufacturingPotential'),
          _chips(context, d, f, 'compositionType'),
        ],
      ),
      RoughFilterSection.parcel => (
        Icons.grid_view_rounded,
        [
          _chips(context, d, f, 'parcelType'),
          _chips(context, d, f, 'sieveSizes', facetKey: 'sieveSize'),
          _flag(context, d, 'separableOnly', RoughFlowL10n.separableOnly),
        ],
      ),
      RoughFilterSection.origin => (
        Icons.public_rounded,
        [
          if (!lab) _chips(context, d, f, 'countryOfOrigin'),
          if (!lab) _chips(context, d, f, 'kpStatus'),
          _chips(context, d, f, 'deliveryTerms'),
          _flag(
            context,
            d,
            'inspectionAllowed',
            RoughFlowL10n.inspectionAllowed,
          ),
          _flag(context, d, 'labReportOnly', RoughFlowL10n.labReportOnly),
        ],
      ),
      RoughFilterSection.listing => (
        Icons.tune_rounded,
        [
          _flag(context, d, 'withImages', RoughFlowL10n.withImages),
          _flag(context, d, 'withVideo', RoughFlowL10n.withVideo),
          _flag(context, d, 'makeAnOfferOnly', RoughFlowL10n.makeAnOfferOnly),
          _flag(context, d, 'onAuctionOnly', RoughFlowL10n.onAuctionOnly),
        ],
      ),
    };
    final shown = [
      for (final w in parts)
        if (w is! SizedBox) w,
    ];
    final p = LuxePalette.of(context);

    return finderSection(
      s,
      title: _sectionTitle(context, s),
      icon: icon,
      count: summary.count(s),
      initiallyExpanded:
          s == RoughFilterSection.crystal || s == RoughFilterSection.sizePrice,
      names: switch (s) {
        RoughFilterSection.crystal => d.listOf('crystalShape').toList(),
        RoughFilterSection.quality => d.listOf('roughQuality').toList(),
        RoughFilterSection.parcel => d.listOf('parcelType').toList(),
        _ => const <String>[],
      },
      child: shown.isEmpty
          ? Text(
              context.tr(RoughFlowL10n.noValues),
              style: LuxeType.body(p.inkMuted, size: 13),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  shown[i],
                ],
              ],
            ),
    );
  }

  static String _labelKey(String key) => switch (key) {
    'crystalShape' => RoughFlowL10n.crystalShape,
    'crystalCondition' => RoughFlowL10n.crystalCondition,
    'transparency' => RoughFlowL10n.transparency,
    'surfaceCondition' => RoughFlowL10n.surfaceCondition,
    'growthType' => RoughFlowL10n.growthType,
    'colorGrades' => RoughFlowL10n.colorGrades,
    'colorWords' => RoughFlowL10n.colorWords,
    'clarityGrades' => RoughFlowL10n.clarityGrades,
    'clarityWords' => RoughFlowL10n.clarityWords,
    'colorDistribution' => RoughFlowL10n.colorDistribution,
    'fluorescence' => RoughFlowL10n.fluorescence,
    'roughQuality' => RoughFlowL10n.roughQuality,
    'manufacturingPotential' => RoughFlowL10n.manufacturingPotential,
    'compositionType' => RoughFlowL10n.compositionType,
    'parcelType' => RoughFlowL10n.parcelType,
    'sieveSizes' => RoughFlowL10n.sieveSizes,
    'countryOfOrigin' => RoughFlowL10n.countryOfOrigin,
    'kpStatus' => RoughFlowL10n.kpStatus,
    _ => RoughFlowL10n.deliveryTerms,
  };

  /// Multi-select chips from a facet, with counts. Picked values the facet
  /// no longer lists stay so they can be cleared. Empty → [SizedBox].
  Widget _chips(
    BuildContext context,
    RoughFilterState d,
    RoughFacets f,
    String key, {
    String? facetKey,
  }) {
    return _group(context, d, key: key, values: f.of(facetKey ?? key));
  }

  Widget _group(
    BuildContext context,
    RoughFilterState d, {
    required String key,
    required List<RoughFacetValue> values,
    List<String> fixed = const [],
  }) {
    final counts = {for (final v in values) v.value: v.count};
    final picked = d.listOf(key);
    final options = [
      ...fixed,
      for (final v in values)
        if (!fixed.contains(v.value)) v.value,
      for (final v in picked)
        if (!fixed.contains(v) && !counts.containsKey(v)) v,
    ];
    if (options.isEmpty) return const SizedBox.shrink();
    return LuxeChipGroup(
      title: context.tr(_labelKey(key)),
      options: options,
      selected: picked,
      onToggle: (v) => _n.toggle(key, v),
      labelOf: (v) => counts[v] == null ? v : '$v · ${counts[v]}',
      initialVisible: options.length > 10 ? 8 : null,
    );
  }

  static final _colorSpan = RegExp(r'^[D-Z](\s*-\s*[D-Z])?$');
  static final _claritySpan = RegExp(
    r'^(FL|IF|VVS[12]|VS[12]|SI[123]|I[123])(\s*-\s*(FL|IF|VVS[12]|VS[12]|SI[123]|I[123]))?$',
  );

  static bool _isSpan(String key, String value) =>
      (key == 'colorGrades' ? _colorSpan : _claritySpan).hasMatch(
        value.trim().toUpperCase(),
      );

  /// D–Z / FL–I3 grade chips, shown once a listed parcel uses a grade span.
  Widget _grades(
    BuildContext context,
    RoughFilterState d, {
    required String key,
    required List<RoughFacetValue> facet,
    required List<String> options,
  }) {
    final graded =
        facet.any((v) => _isSpan(key, v.value)) || d.listOf(key).isNotEmpty;
    if (!graded) return const SizedBox.shrink();
    return _group(context, d, key: key, values: const [], fixed: options);
  }

  /// Colour / clarity words (White, Brown, Spotted, …) from the facet.
  Widget _words(
    BuildContext context,
    RoughFilterState d, {
    required String key,
    required List<RoughFacetValue> facet,
  }) {
    final gradeKey = key == 'colorWords' ? 'colorGrades' : 'clarityGrades';
    return _group(
      context,
      d,
      key: key,
      values: [
        for (final v in facet)
          if (!_isSpan(gradeKey, v.value)) v,
      ],
    );
  }

  Widget _range(
    BuildContext context,
    RoughFilterState d,
    RoughFacets f,
    RoughRange r,
  ) {
    final (min, max) = d.rangeOf(r);
    final limits = f.ranges[r.facetKey];
    final money = r == RoughRange.price || r == RoughRange.pricePerCarat;
    String fmt(double v) => switch (r) {
      RoughRange.price ||
      RoughRange.pricePerCarat => formatGroupedWhole(v.roundToDouble()),
      RoughRange.pieces => v.round().toString(),
      _ => v.toStringAsFixed(2),
    };
    final title = context.tr(switch (r) {
      RoughRange.carat => RoughFlowL10n.totalCarat,
      RoughRange.avgCarat => RoughFlowL10n.avgCarat,
      RoughRange.pieces => RoughFlowL10n.pieces,
      RoughRange.price => RoughFlowL10n.totalPrice,
      RoughRange.pricePerCarat => RoughFlowL10n.pricePerCarat,
    });
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuxeRangeFields(
          title: title,
          min: min,
          max: max,
          // Unset handles send nothing, so parcels past the limits still show.
          minHint: limits == null ? '0' : fmt(limits.min),
          maxHint: limits == null ? null : fmt(limits.max),
          prefix: money ? '${AppCurrency.symbol} ' : null,
          suffix: switch (r) {
            RoughRange.carat || RoughRange.avgCarat => 'ct',
            RoughRange.pieces => 'pcs',
            _ => null,
          },
          minLabel: context.tr(CatalogFlowL10n.min),
          maxLabel: context.tr(CatalogFlowL10n.max),
          invalidLabel: context.tr(CatalogFlowL10n.invalidRange),
          onChanged: (lo, hi) => _n.setRange(r, lo, hi),
        ),
        if (limits != null) ...[
          const SizedBox(height: 4),
          Text(
            context.tr(RoughFlowL10n.rangeHint, {
              'min': money
                  ? AppCurrency.format(fmt(limits.min))
                  : fmt(limits.min),
              'max': money
                  ? AppCurrency.format(fmt(limits.max))
                  : fmt(limits.max),
            }),
            style: LuxeType.body(p.inkFaint, size: 11.5),
          ),
        ],
      ],
    );
  }

  static const _yieldSteps = <double>[0, 30, 40, 50, 60, 70];

  Widget _yield(BuildContext context, RoughFilterState d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterSectionHeader(title: context.tr(RoughFlowL10n.yieldMin)),
        const SizedBox(height: 6),
        LuxeQuickChips<double>(
          dense: true,
          chips: [
            for (final v in _yieldSteps)
              LuxeQuickChip(
                value: v,
                label: v == 0
                    ? context.tr(CatalogL10n.any)
                    : '${v.toStringAsFixed(0)}%+',
              ),
          ],
          isSelected: (v) => v == d.yieldMin,
          onTap: _n.setYieldMin,
        ),
      ],
    );
  }

  Widget _flag(
    BuildContext context,
    RoughFilterState d,
    String key,
    String labelKey,
  ) {
    return FilterBooleanCheckbox(
      label: context.tr(labelKey),
      value: d.flag(key),
      onChanged: (v) => _n.setFlag(key, v ?? false),
    );
  }
}
