import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../application/seller_products_provider.dart';
import '../../domain/models/seller_product.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_theme.dart';
import '../widgets/seller_product_cards_view.dart';
import '../widgets/seller_product_column_picker.dart';
import '../widgets/seller_product_data_table.dart';

/// Seller inventory: natural / melee tabs, search, status filter, table or
/// gallery views, column picker, selection and pagination.
class SellerProductsScreen extends ConsumerStatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  ConsumerState<SellerProductsScreen> createState() =>
      _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(sellerProductsControllerProvider).searchQuery,
    );
    Future.microtask(() {
      if (!mounted) return;
      ref.read(sellerProductsCatalogProvider.notifier).loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editProduct(SellerProduct product) async {
    await context.push(AppRouteNames.sellerProductEditPath(product.id));
  }

  Future<void> _quickView(SellerProduct product) {
    return showSellerProductQuickView(
      context,
      product: product,
      onEdit: () => _editProduct(product),
      onDelete: () => _deleteProduct(product),
    );
  }

  Future<void> _deleteProduct(SellerProduct product) async {
    final ok = await showAtelierConfirm(
      context: context,
      title: context.tr(RemainingL10n.deleteProduct2),
      message: context.tr(RemainingL10n.removeStockConfirm, {
        'stockNumber': product.stockNumber,
      }),
      confirmLabel: context.tr(RemainingL10n.delete),
      cancelLabel: context.tr(RemainingL10n.cancel),
      destructive: true,
    );
    if (!ok || !mounted) return;
    final result = await ref
        .read(sellerProductsCatalogProvider.notifier)
        .persistDelete(product);
    if (!mounted) return;
    switch (result) {
      case Success():
        showAtelierToast(
          context,
          context.tr(RemainingL10n.deletedProduct, {
            'stockNumber': product.stockNumber,
          }),
          tone: AtelierTone.emerald,
        );
      case ResultFailure(:final failure):
        showAtelierToast(context, failure.message, tone: AtelierTone.ruby);
    }
  }

  Future<void> _openColumnPicker() {
    return showAtelierSheet<void>(
      context: context,
      title: context.tr(RemainingL10n.columns),
      subtitle: 'Choose which fields the table shows.',
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(sellerProductsControllerProvider);
          final ctrl = ref.read(sellerProductsControllerProvider.notifier);
          return SellerProductColumnPickerPanel(
            visibleColumnIds: state.visibleColumnIds,
            onColumnToggled: ctrl.toggleColumn,
            onShowHideAll: ctrl.setAllColumnsVisible,
            onReset: ctrl.resetColumnsToDefault,
          );
        },
      ),
    );
  }

  void _export() => showAtelierToast(context, 'Export isn’t available yet.');

  Future<void> _openToolsMenu({
    required bool canExport,
    required bool busy,
  }) async {
    final action = await showAtelierOptions<String>(
      context: context,
      title: context.tr(RemainingL10n.actions),
      options: [
        if (canExport)
          AtelierOption(
            value: 'export',
            label: context.tr(RemainingL10n.export),
            icon: Icons.file_download_outlined,
          ),
        AtelierOption(
          value: 'refresh',
          label: context.tr(RemainingL10n.refresh),
          icon: Icons.refresh_rounded,
        ),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case 'export':
        _export();
      case 'refresh' when !busy:
        await ref.read(sellerProductsCatalogProvider.notifier).refresh();
    }
  }

  void _clearSelection(Set<String> ids) {
    final ctrl = ref.read(sellerProductsControllerProvider.notifier);
    for (final id in ids.toList()) {
      ctrl.toggleProductSelection(id, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final catalogState = ref.watch(sellerProductsCatalogProvider);
    final catalog = catalogState.products;
    final state = ref.watch(sellerProductsControllerProvider);
    final ctrl = ref.read(sellerProductsControllerProvider.notifier);
    final filtered = filteredSellerProducts(catalog, state);
    final total = filtered.length;
    final start = state.page * state.rowsPerPage;
    final end = (start + state.rowsPerPage).clamp(0, total);
    final pageItems = start < total
        ? filtered.sublist(start, end)
        : <SellerProduct>[];
    final columns = visibleColumnsInOrder(state);
    final maxPage = total == 0 ? 0 : ((total - 1) / state.rowsPerPage).floor();
    final stats = _InventoryStats.of(catalog, state.tab);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = AtelierSpace.gutter(width);
    final isTable = state.viewMode == SellerProductsViewMode.grid;
    final showSummary = width >= 600;
    final narrow = width < 480;

    Widget content;
    if (catalogState.isLoading && catalog.isEmpty) {
      content = isTable
          ? AtelierSkeletonList(
              count: 6,
              height: 64,
              padding: EdgeInsets.symmetric(horizontal: gutter),
            )
          : _GallerySkeleton(gutter: gutter);
    } else if (catalogState.errorMessage != null && catalog.isEmpty) {
      content = SingleChildScrollView(
        child: AtelierErrorState(
          title: 'Inventory unavailable',
          message: catalogState.errorMessage!,
          onRetry: () =>
              ref.read(sellerProductsCatalogProvider.notifier).refresh(),
        ),
      );
    } else if (pageItems.isEmpty) {
      final searching = state.searchQuery.isNotEmpty;
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AtelierEmptyState(
            icon: searching ? Icons.search_off_rounded : Icons.diamond_outlined,
            title: context.tr(RemainingL10n.noProducts),
            message: searching
                ? 'Nothing matches “${state.searchQuery}”. Try a stock number, '
                      'certificate, shape or colour.'
                : 'Nothing listed under this status yet. Switch status or '
                      'type to see the rest of your inventory.',
            actionLabel: searching ? 'Clear search' : null,
            onAction: searching
                ? () {
                    _searchController.clear();
                    ctrl.setSearchQuery('');
                  }
                : null,
          ),
        ],
      );
    } else {
      content = isTable
          ? SellerProductDataTable(
              products: pageItems,
              columns: columns,
              selectedIds: state.selectedProductIds,
              onToggleSelection: ctrl.toggleProductSelection,
              onToggleSelectAll: (selected) =>
                  ctrl.toggleSelectAllOnPage(pageItems, selected),
              onEdit: _editProduct,
              onDelete: _deleteProduct,
              onView: _quickView,
              gutter: gutter,
            )
          : SellerProductCardsView(
              products: pageItems,
              padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 16),
              selectedIds: state.selectedProductIds,
              onToggleSelection: ctrl.toggleProductSelection,
              onEdit: _editProduct,
              onDelete: _deleteProduct,
              onQuickView: _quickView,
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showSummary) ...[
                Reveal(child: _InventorySummary(stats: stats)),
                const SizedBox(height: AtelierSpace.s16),
              ],
              Reveal(
                index: 1,
                child: AtelierSegmented<SellerProductDiamondTab>(
                  expand: true,
                  segments: [
                    AtelierSegment(
                      value: SellerProductDiamondTab.natural,
                      label: context.tr(RemainingL10n.naturalDiamonds),
                      count: _InventoryStats.of(
                        catalog,
                        SellerProductDiamondTab.natural,
                      ).total,
                    ),
                    AtelierSegment(
                      value: SellerProductDiamondTab.melee,
                      label: context.tr(RemainingL10n.meleeDiamonds),
                      count: _InventoryStats.of(
                        catalog,
                        SellerProductDiamondTab.melee,
                      ).total,
                    ),
                  ],
                  selected: state.tab,
                  onChanged: ctrl.setTab,
                ),
              ),
              const SizedBox(height: AtelierSpace.s12),
              Reveal(
                index: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: AtelierSearchField(
                        controller: _searchController,
                        hint: context.tr(
                          RemainingL10n.searchStockCertificateShapeColorTags,
                        ),
                        onChanged: ctrl.setSearchQuery,
                      ),
                    ),
                    const SizedBox(width: AtelierSpace.s8),
                    _ViewToggle(
                      mode: state.viewMode,
                      onChanged: ctrl.setViewMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AtelierSpace.s12),
              Reveal(
                index: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: AtelierSegmented<SellerProductStatusFilter>(
                        dense: true,
                        segments: [
                          AtelierSegment(
                            value: SellerProductStatusFilter.active,
                            label: context.tr(RemainingL10n.active),
                            count: stats.active,
                          ),
                          AtelierSegment(
                            value: SellerProductStatusFilter.expired,
                            label: context.tr(RemainingL10n.expired),
                            count: stats.expired,
                          ),
                          AtelierSegment(
                            value: SellerProductStatusFilter.all,
                            label: context.tr(RemainingL10n.all),
                            count: stats.total,
                          ),
                        ],
                        selected: state.statusFilter,
                        onChanged: ctrl.setStatusFilter,
                      ),
                    ),
                    AnimatedSize(
                      duration: AtelierMotion.base,
                      curve: AtelierMotion.emphasized,
                      child: isTable
                          ? AtelierIconButton(
                              icon: Icons.view_column_outlined,
                              tooltip: context.tr(RemainingL10n.columns),
                              onPressed: _openColumnPicker,
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (narrow)
                      AtelierIconButton(
                        icon: Icons.more_horiz_rounded,
                        tooltip: context.tr(RemainingL10n.actions),
                        onPressed: () => _openToolsMenu(
                          canExport: isTable,
                          busy: catalogState.isLoading,
                        ),
                      )
                    else ...[
                      if (isTable)
                        AtelierIconButton(
                          icon: Icons.file_download_outlined,
                          tooltip: context.tr(RemainingL10n.export),
                          onPressed: _export,
                        ),
                      AtelierIconButton(
                        icon: Icons.refresh_rounded,
                        tooltip: context.tr(RemainingL10n.refresh),
                        onPressed: catalogState.isLoading
                            ? null
                            : () => ref
                                  .read(sellerProductsCatalogProvider.notifier)
                                  .refresh(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AtelierSpace.s8),
              Text(
                isTable
                    ? '$total total · use the column picker to show all fields'
                    : '$total total · long-press a card to select',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.caption(p.muted, size: 11.5),
              ),
              const SizedBox(height: AtelierSpace.s8),
            ],
          ),
        ),
        AnimatedSize(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          child: state.selectedProductIds.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 8),
                  child: _SelectionBar(
                    count: state.selectedProductIds.length,
                    onSelectPage: () =>
                        ctrl.toggleSelectAllOnPage(pageItems, true),
                    onClear: () => _clearSelection(state.selectedProductIds),
                  ),
                ),
        ),
        if (catalogState.isLoading && catalog.isNotEmpty)
          LinearProgressIndicator(
            minHeight: 1.5,
            color: p.gold,
            backgroundColor: Colors.transparent,
          ),
        Expanded(
          child: RefreshIndicator(
            color: p.gold,
            backgroundColor: p.surface,
            onRefresh: () =>
                ref.read(sellerProductsCatalogProvider.notifier).refresh(),
            child: AnimatedSwitcher(
              duration: AtelierMotion.base,
              switchInCurve: AtelierMotion.emphasized,
              child: KeyedSubtree(
                key: ValueKey('${state.viewMode}-${state.tab}'),
                child: content,
              ),
            ),
          ),
        ),
        _PaginationBar(
          rowsPerPage: state.rowsPerPage,
          total: total,
          start: total == 0 ? 0 : start + 1,
          end: end,
          page: state.page,
          maxPage: maxPage,
          onRowsPerPageChanged: ctrl.setRowsPerPage,
          onPrevious: state.page > 0
              ? () => ctrl.setPage(state.page - 1)
              : null,
          onNext: state.page < maxPage
              ? () => ctrl.setPage(state.page + 1)
              : null,
        ),
      ],
    );
  }
}

/// Counts for the current natural / melee tab (deleted items excluded).
class _InventoryStats {
  const _InventoryStats({
    required this.total,
    required this.active,
    required this.expired,
    required this.onAuction,
    required this.sold,
  });

  final int total;
  final int active;
  final int expired;
  final int onAuction;
  final int sold;

  static _InventoryStats of(
    List<SellerProduct> catalog,
    SellerProductDiamondTab tab,
  ) {
    var total = 0, active = 0, expired = 0, auction = 0, sold = 0;
    for (final p in catalog) {
      if (p.isDeleted) continue;
      final inTab = tab == SellerProductDiamondTab.natural
          ? p.isNatural
          : !p.isNatural;
      if (!inTab) continue;
      total++;
      p.isExpired ? expired++ : active++;
      if (p.isOnAuction) auction++;
      if (p.isSold) sold++;
    }
    return _InventoryStats(
      total: total,
      active: active,
      expired: expired,
      onAuction: auction,
      sold: sold,
    );
  }
}

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({required this.stats});

  final _InventoryStats stats;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final items = <(String, int, AtelierTone)>[
      (context.tr(RemainingL10n.active), stats.active, AtelierTone.emerald),
      (
        context.tr(RemainingL10n.onAuction),
        stats.onAuction,
        AtelierTone.sapphire,
      ),
      (context.tr(RemainingL10n.sold), stats.sold, AtelierTone.gold),
      (context.tr(RemainingL10n.expired), stats.expired, AtelierTone.amber),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: p.hairline,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CountUpText(
                  '${items[i].$2}',
                  style: AtelierType.display(p.ink, size: 26),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: p.tone(items[i].$3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        items[i].$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.caption(p.muted, size: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.mode, required this.onChanged});

  final SellerProductsViewMode mode;
  final ValueChanged<SellerProductsViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    Widget option(SellerProductsViewMode value, IconData icon, String label) {
      final selected = mode == value;
      return Tooltip(
        message: label,
        child: Pressable(
          onTap: () => onChanged(value),
          semanticLabel: label,
          child: AnimatedContainer(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            width: 40,
            height: 30,
            decoration: BoxDecoration(
              color: selected ? p.lifted : Colors.transparent,
              borderRadius: BorderRadius.circular(AtelierRadius.pill),
              boxShadow: selected
                  ? [BoxShadow(color: p.shadow, blurRadius: 8)]
                  : null,
            ),
            child: Icon(icon, size: 17, color: selected ? p.ink : p.muted),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.sunken,
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          option(
            SellerProductsViewMode.grid,
            Icons.table_rows_outlined,
            context.tr(RemainingL10n.grid),
          ),
          option(
            SellerProductsViewMode.cards,
            Icons.grid_view_rounded,
            context.tr(RemainingL10n.cards),
          ),
        ],
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.onSelectPage,
    required this.onClear,
  });

  final int count;
  final VoidCallback onSelectPage;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: p.isDark ? p.raised : p.onyx,
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        boxShadow: p.floatShadow,
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: p.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count selected',
              style: AtelierType.label(p.isDark ? p.ink : p.onOnyx, size: 13),
            ),
          ),
          TextButton(
            onPressed: onSelectPage,
            style: TextButton.styleFrom(foregroundColor: p.gold),
            child: Text(
              'Select page',
              style: AtelierType.label(p.gold, size: 12.5),
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: p.isDark ? p.ink : p.onOnyx,
            ),
            child: Text(
              'Clear',
              style: AtelierType.label(p.isDark ? p.ink : p.onOnyx, size: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _GallerySkeleton extends StatelessWidget {
  const _GallerySkeleton({required this.gutter});

  final double gutter;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 3 : 2;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 16),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: columns * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 284,
          ),
          itemBuilder: (_, _) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AtelierRadius.lg),
              border: Border.all(color: p.hairline),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SkeletonBox(height: double.infinity)),
                SizedBox(height: 14),
                SkeletonBox(width: 110, height: 16),
                SizedBox(height: 8),
                SkeletonBox(width: 150, height: 10),
                SizedBox(height: 12),
                SkeletonBox(width: 80, height: 14),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.rowsPerPage,
    required this.total,
    required this.start,
    required this.end,
    required this.page,
    required this.maxPage,
    required this.onRowsPerPageChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final int rowsPerPage;
  final int total;
  final int start;
  final int end;
  final int page;
  final int maxPage;
  final ValueChanged<int> onRowsPerPageChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  Future<void> _pickRows(BuildContext context) async {
    final picked = await showAtelierOptions<int>(
      context: context,
      title: context.tr(RemainingL10n.rowsPerPage),
      options: [
        for (final n in const [10, 25, 50])
          AtelierOption(value: n, label: '$n', selected: n == rowsPerPage),
      ],
    );
    if (picked != null) onRowsPerPageChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: p.canvas,
        border: Border(top: BorderSide(color: p.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Pressable(
              onTap: () => _pickRows(context),
              semanticLabel: context.tr(RemainingL10n.rowsPerPage),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: p.sunken,
                  borderRadius: BorderRadius.circular(AtelierRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$rowsPerPage / page',
                      style: AtelierType.figure(p.inkSoft, size: 12),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.expand_more_rounded, size: 16, color: p.muted),
                  ],
                ),
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: AtelierMotion.base,
              child: Text(
                total == 0 ? '0 of 0' : '$start–$end of $total',
                key: ValueKey('$start-$end-$total'),
                style: AtelierType.figure(p.inkSoft, size: 12.5),
              ),
            ),
            const SizedBox(width: 6),
            AtelierIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Previous page',
              size: 36,
              filled: true,
              onPressed: onPrevious,
            ),
            const SizedBox(width: 6),
            AtelierIconButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Next page',
              size: 36,
              filled: true,
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}
