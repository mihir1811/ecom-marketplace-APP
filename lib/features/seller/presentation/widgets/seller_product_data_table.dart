import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/models/seller_product.dart';
import '../../domain/models/seller_product_column.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_theme.dart';

/// Spreadsheet view of the seller inventory with configurable columns.
class SellerProductDataTable extends StatefulWidget {
  const SellerProductDataTable({
    required this.products,
    required this.columns,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onToggleSelectAll,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.gutter = 16,
    super.key,
  });

  final List<SellerProduct> products;
  final List<SellerProductColumnDef> columns;
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggleSelection;
  final void Function(bool selected) onToggleSelectAll;
  final ValueChanged<SellerProduct>? onEdit;
  final ValueChanged<SellerProduct>? onDelete;
  final ValueChanged<SellerProduct>? onView;

  /// Horizontal page gutter so the table lines up with the toolbar.
  final double gutter;

  @override
  State<SellerProductDataTable> createState() => _SellerProductDataTableState();
}

class _SellerProductDataTableState extends State<SellerProductDataTable> {
  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();

  static const _minColWidth = 120.0;
  static const _selectionWidth = 40.0;
  static const _actionsWidth = 132.0;
  static const _imageWidth = 64.0;

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    if (widget.columns.isEmpty) {
      return AtelierEmptyState(
        icon: Icons.view_column_outlined,
        title: 'No columns selected',
        message: context.tr(RemainingL10n.selectColumnsUsingTheColumnPicker),
      );
    }

    final products = widget.products;
    final columns = widget.columns;
    final selectedIds = widget.selectedIds;
    final allSelected =
        products.isNotEmpty &&
        products.every((p) => selectedIds.contains(p.id));
    final someSelected = products.any((p) => selectedIds.contains(p.id));

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: EdgeInsets.fromLTRB(widget.gutter, 4, widget.gutter, 12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AtelierRadius.lg),
            border: Border.all(color: p.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalController,
              primary: false,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                notificationPredicate: (n) => n.depth == 0,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  primary: false,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth - widget.gutter * 2 - 2,
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: p.hairline,
                        checkboxTheme: CheckboxThemeData(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          side: BorderSide(color: p.muted, width: 1.2),
                          fillColor: WidgetStateProperty.resolveWith(
                            (s) => s.contains(WidgetState.selected)
                                ? p.gold
                                : Colors.transparent,
                          ),
                          checkColor: WidgetStatePropertyAll(p.onGold),
                        ),
                      ),
                      child: DataTable(
                        headingRowHeight: 48,
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 60,
                        columnSpacing: 18,
                        horizontalMargin: 16,
                        showCheckboxColumn: false,
                        dividerThickness: 1,
                        headingRowColor: WidgetStatePropertyAll(p.sunken),
                        dataRowColor: WidgetStateProperty.resolveWith((s) {
                          if (s.contains(WidgetState.selected)) {
                            return p.goldSoft;
                          }
                          if (s.contains(WidgetState.hovered)) {
                            return p.sunken.withValues(alpha: 0.6);
                          }
                          return null;
                        }),
                        headingTextStyle: AtelierType.overline(p.muted),
                        columns: [
                          for (final col in columns)
                            DataColumn(
                              label: SizedBox(
                                width: _widthFor(col.id),
                                child: col.id == 'selection'
                                    ? Checkbox(
                                        tristate: true,
                                        value: allSelected
                                            ? true
                                            : someSelected
                                            ? null
                                            : false,
                                        onChanged: (v) => widget
                                            .onToggleSelectAll(v ?? false),
                                      )
                                    : Text(
                                        col.label.toUpperCase(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                            ),
                        ],
                        rows: [
                          for (final product in products)
                            DataRow(
                              selected: selectedIds.contains(product.id),
                              onSelectChanged: widget.onView == null
                                  ? null
                                  : (_) => widget.onView!(product),
                              cells: [
                                for (final col in columns)
                                  DataCell(
                                    SizedBox(
                                      width: _widthFor(col.id),
                                      child: _cellFor(context, col.id, product),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _widthFor(String columnId) {
    return switch (columnId) {
      'selection' => _selectionWidth,
      'actions' => _actionsWidth,
      'image1' ||
      'image2' ||
      'image3' ||
      'image4' ||
      'image5' ||
      'image6' => _imageWidth,
      'stock_number' => 130,
      'certificate_number' => 150,
      'updated_at' || 'created_at' => 150,
      _ => _minColWidth,
    };
  }

  Widget _cellFor(
    BuildContext context,
    String columnId,
    SellerProduct product,
  ) {
    final p = context.atelier;
    if (columnId == 'selection') {
      return Checkbox(
        value: widget.selectedIds.contains(product.id),
        onChanged: (v) => widget.onToggleSelection(product.id, v ?? false),
      );
    }
    if (columnId == 'actions') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AtelierIconButton(
            icon: Icons.visibility_outlined,
            tooltip: context.tr(RemainingL10n.view),
            size: 34,
            onPressed: widget.onView == null
                ? null
                : () => widget.onView!(product),
          ),
          AtelierIconButton(
            icon: Icons.edit_outlined,
            tooltip: context.tr(RemainingL10n.edit),
            size: 34,
            onPressed: widget.onEdit == null
                ? null
                : () => widget.onEdit!(product),
          ),
          Tooltip(
            message: context.tr(RemainingL10n.delete),
            child: IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 18, color: p.ruby),
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              padding: EdgeInsets.zero,
              onPressed: widget.onDelete == null
                  ? null
                  : () => widget.onDelete!(product),
            ),
          ),
        ],
      );
    }
    if (columnId.startsWith('image')) {
      final value = product.field(columnId)?.trim() ?? '';
      final isUrl = value.startsWith('http://') || value.startsWith('https://');
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: p.sunken,
          borderRadius: BorderRadius.circular(AtelierRadius.xs),
          border: Border.all(color: p.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: isUrl
            ? AppNetworkImage(
                url: value,
                fit: BoxFit.cover,
                memCacheWidth: 120,
                error: Icon(Icons.image_outlined, size: 18, color: p.muted),
              )
            : Icon(Icons.image_outlined, size: 18, color: p.muted),
      );
    }
    if (columnId == 'is_on_auction' || columnId == 'is_sold') {
      final yes = product.field(columnId)?.toLowerCase() == 'yes';
      return Align(
        alignment: Alignment.centerLeft,
        child: AtelierPill(
          label: yes
              ? context.tr(RemainingL10n.yes)
              : context.tr(RemainingL10n.no),
          tone: yes
              ? (columnId == 'is_sold'
                    ? AtelierTone.ruby
                    : AtelierTone.sapphire)
              : AtelierTone.neutral,
          dense: true,
        ),
      );
    }
    if (columnId == 'is_expired') {
      final expired = product.isExpired;
      return Align(
        alignment: Alignment.centerLeft,
        child: AtelierPill(
          label: expired
              ? context.tr(RemainingL10n.expire)
              : context.tr(RemainingL10n.active),
          tone: expired ? AtelierTone.amber : AtelierTone.emerald,
          dense: true,
        ),
      );
    }
    if (columnId == 'stock_number') {
      return Text(
        product.stockNumber,
        overflow: TextOverflow.ellipsis,
        style: AtelierType.figure(p.ink, size: 13),
      );
    }

    final text = product.field(columnId) ?? '—';
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: AtelierType.caption(p.inkSoft, size: 13),
    );
  }
}
