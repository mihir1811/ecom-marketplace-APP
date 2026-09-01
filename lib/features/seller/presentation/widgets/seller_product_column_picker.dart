import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/seller_product_column.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Scrollable column visibility picker (search, show/hide all, reset).
class SellerProductColumnPickerPanel extends StatefulWidget {
  const SellerProductColumnPickerPanel({
    required this.visibleColumnIds,
    required this.onColumnToggled,
    required this.onShowHideAll,
    required this.onReset,
    super.key,
  });

  final Set<String> visibleColumnIds;
  final void Function(String columnId, bool visible) onColumnToggled;
  final void Function(bool showAll) onShowHideAll;
  final VoidCallback onReset;

  @override
  State<SellerProductColumnPickerPanel> createState() =>
      _SellerProductColumnPickerPanelState();
}

class _SellerProductColumnPickerPanelState
    extends State<SellerProductColumnPickerPanel> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SellerProductColumnDef> get _filtered {
    if (_query.isEmpty) return kSellerProductColumns;
    final q = _query.toLowerCase();
    return kSellerProductColumns
        .where((c) => c.label.toLowerCase().contains(q))
        .toList();
  }

  bool get _allVisible =>
      widget.visibleColumnIds.length == kSellerProductColumns.length;

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppSpacing.r8),
      color: AppColors.card(context),
      child: SizedBox(
        width: 280,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: context.tr(RemainingL10n.search),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r8),
                    borderSide: const BorderSide(color: AppColors.info),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r8),
                    borderSide: const BorderSide(color: AppColors.info),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r8),
                    borderSide: const BorderSide(
                      color: AppColors.info,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final col = items[index];
                    final checked = widget.visibleColumnIds.contains(col.id);
                    return CheckboxListTile(
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        col.label,
                        style: AppTypography.caption.copyWith(fontSize: 13),
                      ),
                      value: checked,
                      activeColor: AppColors.info,
                      onChanged: (v) =>
                          widget.onColumnToggled(col.id, v ?? false),
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => widget.onShowHideAll(!_allVisible),
                    icon: Icon(
                      _allVisible
                          ? Icons.indeterminate_check_box
                          : Icons.check_box,
                      size: 18,
                      color: AppColors.info,
                    ),
                    label: Text(
                      context.tr(RemainingL10n.showHideAll),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onReset,
                    child: Text(
                      context.tr(RemainingL10n.reset),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
