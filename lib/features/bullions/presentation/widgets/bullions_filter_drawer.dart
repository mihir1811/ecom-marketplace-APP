import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/catalog_search_filter_shell.dart';
import '../../../../core/widgets/filters/catalog_availability_filter.dart';
import '../../../../core/widgets/filters/filter_boolean_checkbox.dart';
import '../../../../core/widgets/luxe/luxe_chip_group.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_finder.dart';
import '../../../../core/widgets/luxe/luxe_range_fields.dart';
import '../../application/bullions_filter_provider.dart';
import '../../application/bullions_list_provider.dart';
import '../../domain/models/bullions_filter_state.dart';
import '../../domain/models/bullions_filter_summary.dart';
import 'bullion_filter_labels.dart';

/// Bullion filters on the shared luxe finder layout: editorial intro,
/// pinned section index, collapsible sections with live counts and a sticky
/// Reset / Show results bar. Edits a draft applied on "Show results".
class BullionsFilterDrawer extends ConsumerStatefulWidget {
  const BullionsFilterDrawer({super.key});

  @override
  ConsumerState<BullionsFilterDrawer> createState() =>
      _BullionsFilterDrawerState();
}

class _BullionsFilterDrawerState extends ConsumerState<BullionsFilterDrawer>
    with
        CatalogSearchScrollMixin,
        LuxeFinderMixin<BullionsFilterDrawer, BullionsFilterSection> {
  @override
  final ScrollController catalogScrollController = ScrollController();
  @override
  final GlobalKey catalogNavKey = GlobalKey();
  @override
  double get catalogNavHeight => 56;

  @override
  List<BullionsFilterSection> get finderVisibleSections =>
      BullionsFilterSection.values;

  BullionsFilterDraftNotifier get _n =>
      ref.read(bullionsFilterDraftProvider.notifier);

  @override
  void initState() {
    super.initState();
    catalogScrollController.addListener(finderOnScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _n.syncFromApplied());
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
    final previous = ref.read(bullionsFilterDraftProvider);
    _n.reset();
    showLuxeToast(
      context,
      context.tr(DiamondFlowL10n.filtersCleared),
      actionLabel: context.tr(DiamondFlowL10n.undo),
      onAction: () => _n.replaceDraft(previous),
    );
  }

  void _showResults() {
    _n.apply();
    ref.read(bullionsListProvider.notifier).refresh();
    context.goBack();
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final draft = ref.watch(bullionsFilterDraftProvider);
    final summary = BullionsFilterSummary.of(draft);
    return LuxeFinderScaffold<BullionsFilterSection>(
      title: context.tr(CatalogL10n.bullions),
      onBack: () => context.goBack(),
      sections: BullionsFilterSection.values,
      active: finderActive,
      labelOf: (s) => bullionSectionTitle(context, s),
      countOf: summary.count,
      pillKeyOf: finderPillKey,
      onJump: finderJumpTo,
      navKey: catalogNavKey,
      sectionBuilder: (s) => _section(context, s, draft, summary),
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
    BullionsFilterSection s,
    BullionsFilterState d,
    BullionsFilterSummary summary,
  ) {
    const hints = BullionsFilterState.rangePlaceholders;
    LuxeRangeFields range({
      String? title,
      required double min,
      required double max,
      required String minKey,
      required String maxKey,
      required void Function(double min, double max) onChanged,
      String? prefix,
      String? suffix,
    }) {
      return LuxeRangeFields(
        title: title,
        min: min,
        max: max,
        minHint: hints[minKey] ?? '0',
        maxHint: hints[maxKey],
        prefix: prefix,
        suffix: suffix,
        minLabel: context.tr(CatalogFlowL10n.min),
        maxLabel: context.tr(CatalogFlowL10n.max),
        invalidLabel: context.tr(CatalogFlowL10n.invalidRange),
        onChanged: onChanged,
      );
    }

    final (icon, child) = switch (s) {
      BullionsFilterSection.formWeight => (
        Icons.view_in_ar_outlined,
        _stack([
          _chips(
            context,
            context.tr(CatalogL10n.shape),
            BullionsFilterState.shapeOptions,
            d.shapes,
            _n.toggleShape,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.weight),
            BullionsFilterState.weightChipOptions,
            d.weightChips,
            _n.toggleWeightChip,
          ),
          range(
            title: context.tr(CatalogL10n.currentRange),
            min: d.weightMin,
            max: d.weightMax,
            minKey: 'weightMin',
            maxKey: 'weightMax',
            onChanged: (min, max) => _n.setWeightRange(min: min, max: max),
          ),
        ]),
      ),
      BullionsFilterSection.price => (
        Icons.payments_outlined,
        range(
          min: d.priceMin,
          max: d.priceMax,
          minKey: 'priceMin',
          maxKey: 'priceMax',
          prefix: '${AppCurrency.symbol} ',
          onChanged: (min, max) => _n.setPriceRange(min: min, max: max),
        ),
      ),
      BullionsFilterSection.quantity => (
        Icons.inventory_2_outlined,
        range(
          min: d.quantityMin,
          max: d.quantityMax,
          minKey: 'quantityMin',
          maxKey: 'quantityMax',
          onChanged: (min, max) => _n.setQuantityRange(min: min, max: max),
        ),
      ),
      BullionsFilterSection.provenance => (
        Icons.verified_outlined,
        _stack([
          _chips(
            context,
            context.tr(CatalogL10n.condition),
            BullionsFilterState.conditionOptions,
            d.conditions,
            _n.toggleCondition,
          ),
          _chips(
            context,
            'Certification',
            BullionsFilterState.certificationOptions,
            d.certifications,
            _n.toggleCertification,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.mintMark),
            BullionsFilterState.mintMarkOptions,
            d.mintMarks,
            _n.toggleMintMark,
          ),
        ]),
      ),
      BullionsFilterSection.listing => (
        Icons.tune_rounded,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CatalogAvailabilityFilter(
              value: d.selectedAvailability,
              options: BullionsFilterState.availabilityOptions,
              onChanged: _n.updateAvailability,
            ),
            const SizedBox(height: 4),
            FilterBooleanCheckbox(
              label: context.tr(CatalogL10n.makeOffer),
              value: d.makeAnOffer,
              onChanged: (v) => _n.setMakeAnOffer(v ?? false),
            ),
          ],
        ),
      ),
      BullionsFilterSection.dimensions => (
        Icons.straighten_rounded,
        _stack([
          range(
            title: context.tr(CatalogL10n.length),
            min: d.lengthMin,
            max: d.lengthMax,
            minKey: 'lengthMin',
            maxKey: 'lengthMax',
            suffix: 'mm',
            onChanged: (min, max) => _n.setLengthRange(min: min, max: max),
          ),
          range(
            title: context.tr(CatalogL10n.width),
            min: d.widthMin,
            max: d.widthMax,
            minKey: 'widthMin',
            maxKey: 'widthMax',
            suffix: 'mm',
            onChanged: (min, max) => _n.setWidthRange(min: min, max: max),
          ),
          range(
            title: context.tr(CatalogL10n.height),
            min: d.heightMin,
            max: d.heightMax,
            minKey: 'heightMin',
            maxKey: 'heightMax',
            suffix: 'mm',
            onChanged: (min, max) => _n.setHeightRange(min: min, max: max),
          ),
        ]),
      ),
    };

    return finderSection(
      s,
      title: bullionSectionTitle(context, s),
      icon: icon,
      count: summary.count(s),
      initiallyExpanded:
          s == BullionsFilterSection.formWeight ||
          s == BullionsFilterSection.price,
      names: s == BullionsFilterSection.provenance
          ? [...d.conditions, ...d.certifications, ...d.mintMarks]
          : const [],
      child: child,
    );
  }

  Widget _stack(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 22),
        children[i],
      ],
    ],
  );

  Widget _chips(
    BuildContext context,
    String title,
    List<String> options,
    Set<String> selected,
    void Function(String) onToggle,
  ) {
    return LuxeChipGroup(
      title: title,
      options: options,
      selected: selected,
      onToggle: onToggle,
    );
  }
}
