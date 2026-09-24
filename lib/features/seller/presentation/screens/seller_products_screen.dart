import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../application/seller_products_provider.dart';
import '../../domain/models/seller_product.dart';
import '../widgets/seller_product_cards_view.dart';
import '../widgets/seller_product_column_picker.dart';
import '../widgets/seller_product_data_table.dart';
import 'seller_product_edit_screen.dart';

import '../../../../core/l10n/app_localizations.dart';

class SellerProductsScreen extends ConsumerStatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  ConsumerState<SellerProductsScreen> createState() =>
      _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _columnPickerAnchorKey = GlobalKey();
  OverlayEntry? _columnPickerOverlay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    Future.microtask(() {
      if (!mounted) return;
      ref.read(sellerProductsCatalogProvider.notifier).loadIfNeeded();
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    AppHaptics.selection();
    final tab = _tabController.index == 0
        ? SellerProductDiamondTab.natural
        : SellerProductDiamondTab.melee;
    ref.read(sellerProductsControllerProvider.notifier).setTab(tab);
  }

  @override
  void dispose() {
    _removeColumnPicker();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _removeColumnPicker() {
    _columnPickerOverlay?.remove();
    _columnPickerOverlay = null;
  }

  void _toggleColumnPicker() {
    if (_columnPickerOverlay != null) {
      _removeColumnPicker();
      return;
    }

    final box =
        _columnPickerAnchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final ctrl = ref.read(sellerProductsControllerProvider.notifier);
    final state = ref.read(sellerProductsControllerProvider);

    _columnPickerOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeColumnPicker,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: (offset.dx - 240).clamp(
              8.0,
              MediaQuery.sizeOf(context).width - 296,
            ),
            top: offset.dy + box.size.height + 4,
            child: SellerProductColumnPickerPanel(
              visibleColumnIds: state.visibleColumnIds,
              onColumnToggled: ctrl.toggleColumn,
              onShowHideAll: ctrl.setAllColumnsVisible,
              onReset: ctrl.resetColumnsToDefault,
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_columnPickerOverlay!);
  }

  Future<void> _editProduct(SellerProduct product) async {
    await context.push(AppRouteNames.sellerProductEditPath(product.id));
  }

  Future<void> _deleteProduct(SellerProduct product) async {
    final ok = await confirmDeleteSellerProduct(context, product);
    if (!ok || !mounted) return;
    final result = await ref
        .read(sellerProductsCatalogProvider.notifier)
        .persistDelete(product);
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(RemainingL10n.deletedProduct, {
                'stockNumber': product.stockNumber,
              }),
            ),
          ),
        );
      case ResultFailure(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.info,
          unselectedLabelColor: AppColors.textSecondary(context),
          indicatorColor: AppColors.info,
          indicatorWeight: 3,
          labelStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: context.tr(RemainingL10n.naturalDiamonds)),
            Tab(text: context.tr(RemainingL10n.meleeDiamonds)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44,
                width: double.infinity,
                child: TextField(
                  controller: _searchController,
                  onChanged: ctrl.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: context.tr(
                      RemainingL10n.searchStockCertificateShapeColorTags,
                    ),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r8),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r8),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusDropdown(
                    value: state.statusFilter,
                    onChanged: ctrl.setStatusFilter,
                  ),
                  _ViewModeToggle(
                    mode: state.viewMode,
                    onChanged: ctrl.setViewMode,
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Row(
            children: [
              Text(
                '$total total · use column picker to show all fields',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                ),
              ),
              const Spacer(),
              if (state.viewMode == SellerProductsViewMode.grid) ...[
                IconButton(
                  key: _columnPickerAnchorKey,
                  tooltip: context.tr(RemainingL10n.columns),
                  icon: const Icon(Icons.view_column_outlined),
                  onPressed: _toggleColumnPicker,
                ),
                IconButton(
                  tooltip: context.tr(RemainingL10n.export),
                  icon: const Icon(Icons.download_outlined),
                  onPressed: () {},
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Expanded(
          child: catalogState.isLoading && catalog.isEmpty
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : catalogState.errorMessage != null && catalog.isEmpty
              ? CatalogErrorState(
                  message: catalogState.errorMessage!,
                  onRetry: () => ref
                      .read(sellerProductsCatalogProvider.notifier)
                      .refresh(),
                )
              : pageItems.isEmpty
              ? Center(
                  child: Text(
                    context.tr(RemainingL10n.noProducts),
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted(context),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(sellerProductsCatalogProvider.notifier)
                      .refresh(),
                  child: state.viewMode == SellerProductsViewMode.grid
                      ? SellerProductDataTable(
                          products: pageItems,
                          columns: columns,
                          selectedIds: state.selectedProductIds,
                          onToggleSelection: ctrl.toggleProductSelection,
                          onToggleSelectAll: (selected) =>
                              ctrl.toggleSelectAllOnPage(pageItems, selected),
                          onEdit: _editProduct,
                          onDelete: _deleteProduct,
                        )
                      : SellerProductCardsView(
                          products: pageItems,
                          selectedIds: state.selectedProductIds,
                          onToggleSelection: ctrl.toggleProductSelection,
                          onEdit: _editProduct,
                          onDelete: _deleteProduct,
                        ),
                ),
        ),
        _PaginationBar(
          rowsPerPage: state.rowsPerPage,
          page: state.page,
          total: total,
          start: total == 0 ? 0 : start + 1,
          end: end,
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

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});

  final SellerProductStatusFilter value;
  final ValueChanged<SellerProductStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr(RemainingL10n.status2),
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<SellerProductStatusFilter>(
          value: value,
          underline: const SizedBox.shrink(),
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          items: [
            DropdownMenuItem(
              value: SellerProductStatusFilter.active,
              child: Text(context.tr(RemainingL10n.active)),
            ),
            DropdownMenuItem(
              value: SellerProductStatusFilter.expired,
              child: Text(context.tr(RemainingL10n.expired)),
            ),
            DropdownMenuItem(
              value: SellerProductStatusFilter.all,
              child: Text(context.tr(RemainingL10n.all)),
            ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.mode, required this.onChanged});

  final SellerProductsViewMode mode;
  final ValueChanged<SellerProductsViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: context.tr(RemainingL10n.grid),
            icon: Icons.table_rows_outlined,
            selected: mode == SellerProductsViewMode.grid,
            onTap: () => onChanged(SellerProductsViewMode.grid),
          ),
          Container(width: 1, height: 32, color: AppColors.border(context)),
          _ToggleChip(
            label: context.tr(RemainingL10n.cards),
            icon: Icons.grid_view,
            selected: mode == SellerProductsViewMode.cards,
            onTap: () => onChanged(SellerProductsViewMode.cards),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.selectedFill(context) : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!selected) AppHaptics.selection();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.onSelected(context)
                    : AppColors.textPrimary(context),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.onSelected(context)
                      : AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.rowsPerPage,
    required this.page,
    required this.total,
    required this.start,
    required this.end,
    required this.maxPage,
    required this.onRowsPerPageChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final int rowsPerPage;
  final int page;
  final int total;
  final int start;
  final int end;
  final int maxPage;
  final ValueChanged<int> onRowsPerPageChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border(context))),
        color: AppColors.card(context),
      ),
      child: Row(
        children: [
          Text(
            context.tr(RemainingL10n.rowsPerPage),
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted(context),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: rowsPerPage,
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem(
                value: 10,
                child: Text(context.tr(RemainingL10n.message10)),
              ),
              DropdownMenuItem(
                value: 25,
                child: Text(context.tr(RemainingL10n.message25)),
              ),
              DropdownMenuItem(
                value: 50,
                child: Text(context.tr(RemainingL10n.message50)),
              ),
            ],
            onChanged: (v) {
              if (v != null) onRowsPerPageChanged(v);
            },
          ),
          const Spacer(),
          Text(
            total == 0 ? '0 of 0' : '$start–$end of $total',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}
