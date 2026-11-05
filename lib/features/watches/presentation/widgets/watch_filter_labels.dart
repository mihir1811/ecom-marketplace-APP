import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_toggle_sort_sheet.dart';
import '../../application/watch_filter_provider.dart';
import '../../domain/models/watch_filter_state.dart';
import '../../domain/models/watch_filter_summary.dart';

/// Display title of a watch filter section.
String watchSectionTitle(BuildContext context, WatchFilterSection s) =>
    context.tr(switch (s) {
      WatchFilterSection.brandModel => CatalogFlowL10n.sectionBrandModel,
      WatchFilterSection.style => CatalogFlowL10n.sectionStyle,
      WatchFilterSection.price => CatalogFlowL10n.sectionPrice,
      WatchFilterSection.movement => CatalogFlowL10n.sectionMovement,
      WatchFilterSection.caseBezel => CatalogFlowL10n.sectionCase,
      WatchFilterSection.dial => CatalogFlowL10n.sectionDial,
      WatchFilterSection.strap => CatalogFlowL10n.sectionStrap,
      WatchFilterSection.condition => CatalogFlowL10n.sectionCondition,
      WatchFilterSection.listing => DiamondFlowL10n.sectionListing,
    });

typedef WatchFilterProvider =
    NotifierProvider<WatchFilterNotifier, WatchFilterState>;

/// Pinned Filters / Sort / view toolbar for watch results.
class WatchListingToolbar extends ConsumerWidget {
  const WatchListingToolbar({
    required this.filters,
    required this.sort,
    required this.onFilters,
    required this.onSort,
    required this.onViewMode,
    super.key,
  });

  final WatchFilterProvider filters;
  final StateProvider<WatchSortOption> sort;
  final VoidCallback onFilters;
  final VoidCallback onSort;
  final ValueChanged<LuxeViewMode> onViewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grid = ref.watch(
      watchViewModeProvider.select((m) => m == WatchViewMode.grid),
    );
    final active = ref.watch(
      filters.select((s) => WatchFilterSummary.of(s).total),
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

/// "1,284 watches" (or "Searching…") under a top-bar title.
class WatchCountLine extends StatelessWidget {
  const WatchCountLine({required this.total, super.key});

  /// Null while the first page loads.
  final int? total;

  @override
  Widget build(BuildContext context) {
    return LuxeCountLine(
      text: total == null
          ? context.tr(DiamondFlowL10n.searching)
          : context.tr(CatalogFlowL10n.watchResults, {
              'count': formatGroupedWhole(total!.toDouble()),
            }),
    );
  }
}

/// Sort fields for [showLuxeToggleSortSheet]; [only] limits the options
/// (e.g. the brand page's shorter list).
List<LuxeSortField<WatchSortOption>> watchSortFields({
  Iterable<WatchSortOption>? only,
}) {
  final allowed = only?.toSet();
  LuxeSortField<WatchSortOption>? field(
    String label,
    List<WatchSortOption> options,
  ) {
    final kept = [
      for (final o in options)
        if (allowed == null || allowed.contains(o)) o,
    ];
    if (kept.isEmpty) return null;
    return LuxeSortField(
      label: label,
      options: kept,
      directionLabelOf: (o) => switch (o) {
        WatchSortOption.priceLowToHigh => 'Low to High',
        WatchSortOption.priceHighToLow => 'High to Low',
        WatchSortOption.newest => 'Newest',
        WatchSortOption.oldest => 'Oldest',
        WatchSortOption.brandAz => 'A–Z',
        WatchSortOption.brandZa => 'Z–A',
        WatchSortOption.featured => '',
      },
    );
  }

  return [
    ?field('Default sorting', [WatchSortOption.featured]),
    ?field('Price', [
      WatchSortOption.priceLowToHigh,
      WatchSortOption.priceHighToLow,
    ]),
    ?field('Arrivals', [WatchSortOption.newest, WatchSortOption.oldest]),
    ?field('Brand name', [WatchSortOption.brandAz, WatchSortOption.brandZa]),
  ];
}
