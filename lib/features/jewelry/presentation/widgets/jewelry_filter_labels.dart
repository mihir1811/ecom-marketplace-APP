import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/active_filter_labels.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../application/jewellery_categories_provider.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/models/jewelry_filter_summary.dart';
import '../../domain/models/marketplace_enums.dart';
import '../../domain/models/marketplace_listing.dart';

/// Display title of a jewelry filter section.
String jewelrySectionTitle(BuildContext context, JewelryFilterSection s) =>
    context.tr(switch (s) {
      JewelryFilterSection.style => JewelryFlowL10n.sectionStyle,
      JewelryFilterSection.price => JewelryFlowL10n.sectionPrice,
      JewelryFilterSection.metal => JewelryFlowL10n.sectionMetal,
      JewelryFilterSection.stone => JewelryFlowL10n.sectionStone,
      JewelryFilterSection.listing => DiamondFlowL10n.sectionListing,
    });

String jewelrySortLabel(BuildContext context, JewelrySortOption? o) =>
    context.tr(switch (o) {
      null => JewelryMarketL10n.sortBestMatch,
      JewelrySortOption.relevance => JewelryMarketL10n.sortRelevance,
      JewelrySortOption.newest => JewelryFlowL10n.sortNewest,
      JewelrySortOption.priceAsc => JewelryMarketL10n.sortPriceAsc,
      JewelrySortOption.priceDesc => JewelryMarketL10n.sortPriceDesc,
      JewelrySortOption.popular => JewelryMarketL10n.sortPopular,
    });

String jewelryAvailabilityLabel(BuildContext context, String value) =>
    context.tr(
      value == JewelryAvailability.ready
          ? JewelryMarketL10n.readyToShip
          : JewelryMarketL10n.madeToOrder,
    );

/// Localized word for a marketplace enum value (`YELLOW_GOLD`).
String jewelryEnumLabel(BuildContext context, String value) =>
    context.trCatalogValue(MarketplaceEnums.label(value));

/// "₹1,20,000".
String jewelryRupees(double v) =>
    '${AppCurrency.inrSymbol}${formatGroupedWhole(v)}';

/// Title for the results page: the open style or collection name, or
/// "Jewelry" when every category is shown.
String jewelryCollectionTitle(
  BuildContext context,
  List<MarketplaceCategory>? categories,
  JewelryFilterState filters,
) {
  final found = categories == null
      ? null
      : MarketplaceCategory.find(categories, filters.categorySlug);
  return found?.name ?? context.tr(CatalogL10n.jewelry);
}

/// [jewelryCollectionTitle] for the applied filters.
class JewelryCollectionTitle {
  static String watch(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(jewelryFilterProvider);
    final categories = ref.watch(jewelleryCategoriesProvider).valueOrNull;
    return jewelryCollectionTitle(context, categories, filters);
  }
}

/// Pills summarising which jewelry filter sections hold filters; tapping
/// edits them, the trailing action clears everything.
class JewelryActiveFilterPills extends ConsumerWidget {
  const JewelryActiveFilterPills({
    required this.onEdit,
    required this.onReset,
    super.key,
  });

  final VoidCallback onEdit;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(jewelryFilterProvider);
    final summary = JewelryFilterSummary.of(f);
    Iterable<String> words(Set<String> values) =>
        values.map((v) => jewelryEnumLabel(context, v));
    // Applied values first (also what Gem Agent set), then counts for the rest.
    final pills = ActiveFilterLabels<JewelryFilterSection>()
      ..values(JewelryFilterSection.style, f.styles)
      ..values(JewelryFilterSection.style, f.occasions)
      ..range(
        JewelryFilterSection.price,
        min: f.priceMin,
        max: f.priceMax,
        format: _price,
      )
      ..values(JewelryFilterSection.metal, words(f.metals))
      ..values(JewelryFilterSection.stone, words(f.gemstones))
      ..values(JewelryFilterSection.stone, words(f.origins))
      ..values(JewelryFilterSection.stone, f.shapes);
    if (f.availability != null) {
      pills.add(
        JewelryFilterSection.listing,
        jewelryAvailabilityLabel(context, f.availability!),
      );
    }
    if (f.tag != null) pills.add(JewelryFilterSection.listing, '#${f.tag}');
    return LuxeActiveFilterPills(
      labels: pills.build(
        sections: JewelryFilterSection.values,
        count: summary.count,
        title: (s) => jewelrySectionTitle(context, s),
      ),
      onEdit: onEdit,
      onReset: onReset,
      resetLabel: context.tr(DiamondFlowL10n.reset),
    );
  }
}

/// Pinned Filters / Sort / view toolbar for jewelry results.
class JewelryListingToolbar extends ConsumerWidget {
  const JewelryListingToolbar({
    required this.onFilters,
    required this.onSort,
    required this.onViewMode,
    super.key,
  });

  final VoidCallback onFilters;
  final VoidCallback onSort;
  final ValueChanged<LuxeViewMode> onViewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grid = ref.watch(
      jewelryViewModeProvider.select((m) => m == JewelryViewMode.grid),
    );
    final active = ref.watch(
      jewelryFilterProvider.select((s) => JewelryFilterSummary.of(s).total),
    );
    return LuxeListingToolbar(
      filtersLabel: context.tr(DiamondFlowL10n.filters),
      activeFilters: active,
      onFilters: onFilters,
      onSort: onSort,
      viewMode: grid ? LuxeViewMode.grid : LuxeViewMode.list,
      onViewMode: onViewMode,
      gridLabel: context.tr(DiamondFlowL10n.grid),
      listLabel: context.tr(DiamondFlowL10n.list),
    );
  }
}

/// "1,284 pieces" (or "Searching…") under the results title.
class JewelryCountLine extends StatelessWidget {
  const JewelryCountLine({required this.total, super.key});

  /// Null while the first page loads.
  final int? total;

  @override
  Widget build(BuildContext context) {
    return LuxeCountLine(
      text: total == null
          ? context.tr(DiamondFlowL10n.searching)
          : context.tr(JewelryFlowL10n.results, {
              'count': formatGroupedWhole(total!.toDouble()),
            }),
    );
  }
}

String _price(double v) => jewelryRupees(v);
