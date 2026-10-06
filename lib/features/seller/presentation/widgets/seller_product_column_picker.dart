import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/models/seller_product_column.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_theme.dart';

/// Searchable column visibility picker (show/hide all, reset to defaults).
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
    final p = context.atelier;
    final items = _filtered;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtelierSearchField(
          controller: _searchController,
          hint: context.tr(RemainingL10n.search),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '${widget.visibleColumnIds.length} of '
              '${kSellerProductColumns.length} visible',
              style: AtelierType.caption(p.muted),
            ),
            const Spacer(),
            AtelierButton(
              label: context.tr(RemainingL10n.showHideAll),
              compact: true,
              variant: AtelierButtonVariant.ghost,
              icon: _allVisible
                  ? Icons.remove_done_rounded
                  : Icons.done_all_rounded,
              onPressed: () => widget.onShowHideAll(!_allVisible),
            ),
            AtelierButton(
              label: context.tr(RemainingL10n.reset),
              compact: true,
              variant: AtelierButtonVariant.ghost,
              icon: Icons.restart_alt_rounded,
              onPressed: widget.onReset,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < items.length; i++)
              Reveal(
                index: i < 10 ? i : 0,
                offset: 6,
                child: AtelierChoiceChip(
                  label: items[i].label,
                  selected: widget.visibleColumnIds.contains(items[i].id),
                  onTap: () => widget.onColumnToggled(
                    items[i].id,
                    !widget.visibleColumnIds.contains(items[i].id),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
