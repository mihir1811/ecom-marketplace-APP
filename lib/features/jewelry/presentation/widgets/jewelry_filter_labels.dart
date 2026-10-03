import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/models/jewelry_filter_summary.dart';

/// Display title of a jewelry filter section.
String jewelrySectionTitle(BuildContext context, JewelryFilterSection s) =>
    context.tr(switch (s) {
      JewelryFilterSection.style => JewelryFlowL10n.sectionStyle,
      JewelryFilterSection.price => JewelryFlowL10n.sectionPrice,
      JewelryFilterSection.metal => JewelryFlowL10n.sectionMetal,
      JewelryFilterSection.stone => JewelryFlowL10n.sectionStone,
      JewelryFilterSection.size => JewelryFlowL10n.sectionSize,
      JewelryFilterSection.quality => JewelryFlowL10n.sectionQuality,
      JewelryFilterSection.listing => DiamondFlowL10n.sectionListing,
    });

String jewelrySortLabel(BuildContext context, JewelrySortOption o) =>
    context.tr(switch (o) {
      JewelrySortOption.featured => JewelryFlowL10n.sortFeatured,
      JewelrySortOption.newest => JewelryFlowL10n.sortNewest,
    });

/// Title for the results page: the collection name, "Accessories" for the
/// accessories landing, or "Jewelry" when every category is shown.
String jewelryCollectionTitle(BuildContext context, String? category) =>
    switch (category) {
      null || '' => context.tr(CatalogL10n.jewelry),
      'All Accessories' => context.tr(CatalogL10n.accessories),
      final c => c,
    };

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
    final summary = ref.watch(
      jewelryFilterProvider.select(JewelryFilterSummary.of),
    );
    return LuxeActiveFilterPills(
      labels: [
        for (final s in JewelryFilterSection.values)
          if (summary.count(s) > 0)
            '${jewelrySectionTitle(context, s)} · ${summary.count(s)}',
      ],
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
    final sort = ref.watch(jewelrySortProvider);
    final active = ref.watch(
      jewelryFilterProvider.select((s) => JewelryFilterSummary.of(s).total),
    );
    return LuxeListingToolbar(
      filtersLabel: context.tr(DiamondFlowL10n.filters),
      activeFilters: active,
      onFilters: onFilters,
      sortLabel: jewelrySortLabel(context, sort),
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
