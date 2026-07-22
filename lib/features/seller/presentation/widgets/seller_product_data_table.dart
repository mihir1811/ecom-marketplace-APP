import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/seller_product.dart';
import '../../domain/models/seller_product_column.dart';

class SellerProductDataTable extends StatelessWidget {
  const SellerProductDataTable({
    required this.products,
    required this.columns,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onToggleSelectAll,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final List<SellerProduct> products;
  final List<SellerProductColumnDef> columns;
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggleSelection;
  final void Function(bool selected) onToggleSelectAll;
  final ValueChanged<SellerProduct>? onEdit;
  final ValueChanged<SellerProduct>? onDelete;

  static const _minColWidth = 120.0;
  static const _selectionWidth = 48.0;
  static const _actionsWidth = 140.0;
  static const _imageWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) {
      return Center(
        child: Text(
          'Select columns using the column picker.',
          style: AppTypography.body.copyWith(color: AppColors.textMutedLight),
        ),
      );
    }

    final allSelected = products.isNotEmpty &&
        products.every((p) => selectedIds.contains(p.id));
    final someSelected = products.any((p) => selectedIds.contains(p.id));

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Scrollbar(
              thumbVisibility: true,
              notificationPredicate: (n) => n.depth == 1,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowHeight: 44,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 56,
                    columnSpacing: 16,
                    horizontalMargin: 12,
                    showCheckboxColumn: false,
                    headingTextStyle: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppColors.textSecondaryLight,
                      fontSize: 11,
                    ),
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
                                    onChanged: (v) =>
                                        onToggleSelectAll(v ?? false),
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
                          cells: [
                            for (final col in columns)
                              DataCell(
                                SizedBox(
                                  width: _widthFor(col.id),
                                  child: _cellFor(
                                    context,
                                    col.id,
                                    product,
                                  ),
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
      'image6' =>
        _imageWidth,
      'stock_number' => 130,
      'certificate_number' => 150,
      'updated_at' || 'created_at' => 150,
      _ => _minColWidth,
    };
  }

  Widget _cellFor(BuildContext context, String columnId, SellerProduct product) {
    if (columnId == 'selection') {
      return Checkbox(
        value: selectedIds.contains(product.id),
        onChanged: (v) => onToggleSelection(product.id, v ?? false),
      );
    }
    if (columnId == 'actions') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionIcon(
            icon: Icons.visibility_outlined,
            tooltip: 'View',
            onPressed: () {},
          ),
          _ActionIcon(
            icon: Icons.edit_outlined,
            tooltip: 'Edit',
            onPressed: onEdit == null ? null : () => onEdit!(product),
          ),
          _ActionIcon(
            icon: Icons.delete_outline,
            tooltip: 'Delete',
            color: AppColors.error,
            onPressed: onDelete == null ? null : () => onDelete!(product),
          ),
        ],
      );
    }
    if (columnId.startsWith('image') &&
        product.field(columnId) == 'placeholder') {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.sandSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.warmBorder),
        ),
        child: const Icon(Icons.image_outlined, size: 20, color: AppColors.textMutedLight),
      );
    }
    if (columnId == 'is_on_auction' || columnId == 'is_sold') {
      final yes = product.field(columnId)?.toLowerCase() == 'yes';
      return _StatusPill(
        label: yes ? 'Yes' : 'No',
        highlighted: yes,
      );
    }
    if (columnId == 'is_expired') {
      final expired = product.isExpired;
      return Wrap(
        spacing: 8,
        children: [
          TextButton(
            onPressed: expired ? null : () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: expired ? AppColors.textMutedLight : AppColors.info,
            ),
            child: const Text('Active'),
          ),
          TextButton(
            onPressed: expired ? () {} : null,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: expired ? AppColors.charcoal : AppColors.textMutedLight,
            ),
            child: const Text('Expire'),
          ),
        ],
      );
    }

    final text = product.field(columnId) ?? '—';
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption.copyWith(
        color: AppColors.charcoal,
        fontSize: 13,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.info.withValues(alpha: 0.12)
            : AppColors.sandSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted ? AppColors.info.withValues(alpha: 0.35) : AppColors.warmBorder,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: highlighted ? AppColors.info : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 18, color: color ?? AppColors.charcoal),
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: onPressed,
    );
  }
}
