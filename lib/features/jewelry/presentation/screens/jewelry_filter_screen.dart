import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/catalog_search_filter_shell.dart';
import '../../../../core/widgets/filters/filter_range_slider.dart';
import '../../../../core/widgets/filters/filter_section_header.dart';
import '../../../../core/widgets/luxe/luxe_chip_group.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_finder.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_metal_swatch.dart';
import '../../application/jewelry_catalogue_providers.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../application/jewelry_list_provider.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/models/jewelry_filter_summary.dart';
import '../../domain/models/marketplace_enums.dart';
import '../../domain/models/marketplace_listing.dart';
import '../widgets/jewelry_filter_labels.dart';

/// Jewelry filters on the shared luxe finder layout: pinned section index,
/// collapsible sections with live counts and a sticky Reset / Show results
/// bar.
///
/// Options and counts come from `GET /marketplace/listings/facets` for the
/// open collection, search and shop, so every value shown has pieces behind
/// it. Edits a draft that is applied on "Show results".
///
/// With a [scope] (a house's collection page) the draft starts from the
/// scope's filters and "Show results" pops with the draft instead of
/// changing the shared results page.
class JewelryFilterScreen extends ConsumerStatefulWidget {
  const JewelryFilterScreen({super.key, this.scope});

  final JewelryFilterScope? scope;

  @override
  ConsumerState<JewelryFilterScreen> createState() =>
      _JewelryFilterScreenState();
}

class _JewelryFilterScreenState extends ConsumerState<JewelryFilterScreen>
    with
        CatalogSearchScrollMixin,
        LuxeFinderMixin<JewelryFilterScreen, JewelryFilterSection> {
  @override
  final ScrollController catalogScrollController = ScrollController();
  @override
  final GlobalKey catalogNavKey = GlobalKey();
  @override
  double get catalogNavHeight => 56;

  @override
  List<JewelryFilterSection> get finderVisibleSections =>
      JewelryFilterSection.values;

  JewelryFilterDraftNotifier get _n =>
      ref.read(jewelryFilterDraftProvider.notifier);

  @override
  void initState() {
    super.initState();
    catalogScrollController.addListener(finderOnScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scope = widget.scope;
      scope == null ? _n.syncFromApplied() : _n.replaceDraft(scope.filters);
    });
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
    final previous = ref.read(jewelryFilterDraftProvider);
    _n.reset();
    showLuxeToast(
      context,
      context.tr(DiamondFlowL10n.filtersCleared),
      actionLabel: context.tr(DiamondFlowL10n.undo),
      onAction: () => _n.replaceDraft(previous),
    );
  }

  void _showResults() {
    if (widget.scope != null) {
      Navigator.of(context).pop(ref.read(jewelryFilterDraftProvider));
      return;
    }
    _n.apply();
    ref.read(jewelryListProvider.notifier).refresh();
    context.goBack();
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final draft = ref.watch(jewelryFilterDraftProvider);
    final summary = JewelryFilterSummary.of(draft);
    final facets = ref.watch(jewelryFacetsProvider(jewelryFacetKeyOf(draft)));
    return LuxeFinderScaffold<JewelryFilterSection>(
      title: widget.scope?.title ?? JewelryCollectionTitle.watch(context, ref),
      onBack: () => context.goBack(),
      sections: finderVisibleSections,
      active: finderActive,
      labelOf: (s) => jewelrySectionTitle(context, s),
      countOf: summary.count,
      pillKeyOf: finderPillKey,
      onJump: finderJumpTo,
      navKey: catalogNavKey,
      sectionBuilder: (s) => _section(context, s, draft, summary, facets),
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

  Widget _section(
    BuildContext context,
    JewelryFilterSection s,
    JewelryFilterState d,
    JewelryFilterSummary summary,
    AsyncValue<MarketplaceFacets> facetsAsync,
  ) {
    final facets = facetsAsync.valueOrNull;
    final Widget child;
    if (facets == null) {
      child = facetsAsync.hasError
          ? Text(
              context.tr(JewelryMarketL10n.filtersUnavailable),
              style: LuxeType.body(LuxePalette.of(context).inkMuted, size: 13),
            )
          : const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LuxeSkeleton(width: 140, height: 14),
                SizedBox(height: 12),
                LuxeSkeleton(height: 40, radius: 20),
              ],
            );
    } else {
      child = switch (s) {
        JewelryFilterSection.style => _stack([
          _chips(
            context,
            context.tr(JewelryFlowL10n.style),
            facets.styles,
            d.styles,
            _n.toggleStyle,
            initialVisible: 10,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.occasion),
            facets.occasions,
            d.occasions,
            _n.toggleOccasion,
            initialVisible: 8,
          ),
        ]),
        JewelryFilterSection.price => _price(context, d, facets),
        JewelryFilterSection.metal => _metals(context, d, facets),
        JewelryFilterSection.stone => _stack([
          _chips(
            context,
            context.tr(CatalogL10n.stoneCategory),
            facets.gemstones,
            d.gemstones,
            _n.toggleGemstone,
            initialVisible: 8,
            words: true,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.stoneType),
            facets.origins,
            d.origins,
            _n.toggleOrigin,
            words: true,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.stoneShape),
            facets.shapes,
            d.shapes,
            _n.toggleShape,
            initialVisible: 8,
          ),
        ]),
        JewelryFilterSection.listing => _listing(context, d, facets),
      };
    }

    final icon = switch (s) {
      JewelryFilterSection.style => Icons.auto_awesome_outlined,
      JewelryFilterSection.price => Icons.payments_outlined,
      JewelryFilterSection.metal => Icons.blur_circular_rounded,
      JewelryFilterSection.stone => Icons.diamond_outlined,
      JewelryFilterSection.listing => Icons.local_shipping_outlined,
    };
    return finderSection(
      s,
      title: jewelrySectionTitle(context, s),
      icon: icon,
      count: summary.count(s),
      initiallyExpanded: s != JewelryFilterSection.listing,
      names: switch (s) {
        JewelryFilterSection.style => [...d.styles, ...d.occasions],
        JewelryFilterSection.metal => [
          for (final m in d.metals) jewelryEnumLabel(context, m),
        ],
        _ => const [],
      },
      child: child,
    );
  }

  Widget _price(
    BuildContext context,
    JewelryFilterState d,
    MarketplaceFacets facets,
  ) {
    final lo = facets.priceMin.floorToDouble();
    final hi = facets.priceMax.ceilToDouble();
    if (hi <= lo) {
      return Text(
        context.tr(JewelryMarketL10n.priceSingle, {'price': jewelryRupees(hi)}),
        style: LuxeType.body(LuxePalette.of(context).inkMuted, size: 13),
      );
    }
    return FilterRangeSlider(
      title: context.tr(CatalogL10n.price),
      minLimit: lo,
      maxLimit: hi,
      currentMin: (d.priceMin ?? lo).clamp(lo, hi),
      currentMax: (d.priceMax ?? hi).clamp(lo, hi),
      unitPrefix: AppCurrency.inrSymbol,
      isInteger: true,
      onChanged: (min, max) =>
          _n.setPriceRange(min <= lo ? null : min, max >= hi ? null : max),
      onClear: _n.clearPriceRange,
    );
  }

  Widget _metals(
    BuildContext context,
    JewelryFilterState d,
    MarketplaceFacets facets,
  ) {
    final options = _withSelected(facets.metals, d.metals);
    if (options.isEmpty) return _none(context);
    final counts = {for (final b in facets.metals) b.value: b.count};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterSectionHeader(title: context.tr(CatalogL10n.metal)),
        const SizedBox(height: 12),
        LuxeMetalSwatchPicker(
          options: [for (final m in options) MarketplaceEnums.swatchLabel(m)],
          selected: {for (final m in d.metals) MarketplaceEnums.swatchLabel(m)},
          onToggle: (label) {
            final metal = options.firstWhere(
              (m) => MarketplaceEnums.swatchLabel(m) == label,
            );
            _n.toggleMetal(metal);
          },
          labelOf: (label) {
            final metal = options.firstWhere(
              (m) => MarketplaceEnums.swatchLabel(m) == label,
            );
            final n = counts[metal];
            final word = context.trCatalogValue(MarketplaceEnums.label(metal));
            return n == null ? word : '$word ($n)';
          },
        ),
      ],
    );
  }

  Widget _listing(
    BuildContext context,
    JewelryFilterState d,
    MarketplaceFacets facets,
  ) {
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterSectionHeader(title: context.tr(JewelryMarketL10n.availability)),
        const SizedBox(height: 10),
        LuxeSegmented<String?>(
          options: const [
            null,
            JewelryAvailability.ready,
            JewelryAvailability.madeToOrder,
          ],
          selected: d.availability,
          labelOf: (o) => switch (o) {
            null => context.tr(DiamondFlowL10n.any),
            JewelryAvailability.ready =>
              '${jewelryAvailabilityLabel(context, o)} (${facets.readyToShip})',
            final v =>
              '${jewelryAvailabilityLabel(context, v)} (${facets.madeToOrder})',
          },
          onChanged: _n.setAvailability,
        ),
        if (d.tag != null) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              label: Text('#${d.tag}', style: LuxeType.label(p.ink, size: 13)),
              onDeleted: _n.clearTag,
              color: WidgetStatePropertyAll(p.surface),
              side: BorderSide(color: p.hairline),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ],
    );
  }

  /// Facet values (highest count first), plus any selection the current
  /// facets no longer list so it can still be cleared.
  static List<String> _withSelected(
    List<MarketplaceFacetBucket> buckets,
    Set<String> selected,
  ) => [
    for (final b in buckets) b.value,
    for (final s in selected)
      if (!buckets.any((b) => b.value == s)) s,
  ];

  Widget _none(BuildContext context) => Text(
    context.tr(JewelryMarketL10n.noOptions),
    style: LuxeType.body(LuxePalette.of(context).inkMuted, size: 13),
  );

  Widget _stack(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 22),
        children[i],
      ],
    ],
  );

  /// [words] shows enum values (`LAB_GROWN`) as catalog words.
  Widget _chips(
    BuildContext context,
    String title,
    List<MarketplaceFacetBucket> buckets,
    Set<String> selected,
    void Function(String) onToggle, {
    int? initialVisible,
    bool words = false,
  }) {
    final options = _withSelected(buckets, selected);
    final counts = {for (final b in buckets) b.value: b.count};
    return LuxeChipGroup(
      title: title,
      options: options,
      selected: selected,
      onToggle: onToggle,
      labelOf: (v) {
        final word = words
            ? jewelryEnumLabel(context, v)
            : context.trCatalogValue(v);
        final n = counts[v];
        return n == null ? word : '$word ($n)';
      },
      initialVisible: initialVisible,
      emptyLabel: context.tr(JewelryMarketL10n.noOptions),
      showAllLabel: context.tr(CatalogFlowL10n.showAll),
      showLessLabel: context.tr(CatalogFlowL10n.showLess),
    );
  }
}

/// Filters owned by another screen: [filters] to start from, [title] to
/// show. The filter screen pops with the edited [JewelryFilterState].
class JewelryFilterScope {
  const JewelryFilterScope({required this.filters, required this.title});

  final JewelryFilterState filters;
  final String title;
}
