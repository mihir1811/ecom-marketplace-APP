import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Builds an optional leading mark for an option (swatch, flag, …).
typedef LuxeOptionLeading = Widget? Function(String option);

/// Multi-select replacement for a dropdown: a field that summarises the
/// picks, opens a checklist sheet (searchable for long lists) and shows the
/// picks underneath as removable chips.
class LuxeMultiSelectField extends StatelessWidget {
  const LuxeMultiSelectField({
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.hint,
    required this.sheetTitle,
    super.key,
    this.labelOf,
    this.leadingOf,
    this.searchHint,
  });

  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final String hint;
  final String sheetTitle;
  final String Function(String option)? labelOf;
  final LuxeOptionLeading? leadingOf;

  /// Shown in the sheet's search box; long lists are searchable regardless.
  final String? searchHint;

  static const _searchThreshold = 10;

  String _label(String o) => labelOf?.call(o) ?? o;

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _MultiSelectSheet(
        title: sheetTitle,
        options: options,
        initial: selected,
        labelOf: _label,
        leadingOf: leadingOf,
        searchable: options.length > _searchThreshold,
        searchHint: searchHint,
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final has = selected.isNotEmpty;
    final summary = !has
        ? hint
        : selected.length <= 2
        ? selected.map(_label).join(', ')
        : '${selected.take(2).map(_label).join(', ')} +${selected.length - 2}';
    final fill = AppColors.selectedFill(context);
    final onFill = AppColors.onSelected(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: has ? AppColors.bronze : AppColors.border(context),
              width: has ? 1.3 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _open(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontSize: 14,
                          color: has
                              ? AppColors.textPrimary(context)
                              : AppColors.textMuted(context),
                        ),
                      ),
                    ),
                    if (has) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: ShapeDecoration(
                          color: AppColors.bronze,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          '${selected.length}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warmWhite,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textSecondary(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (has) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final o in selected)
                InputChip(
                  key: ValueKey(o),
                  avatar: leadingOf?.call(o),
                  label: Text(
                    _label(o),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  labelStyle: AppTypography.caption.copyWith(
                    color: onFill,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: fill,
                  side: BorderSide(color: fill),
                  deleteIconColor: onFill,
                  deleteIcon: const Icon(Icons.close, size: 15),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onDeleted: () {
                    AppHaptics.selection();
                    onChanged([
                      for (final s in selected)
                        if (s != o) s,
                    ]);
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MultiSelectSheet extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.initial,
    required this.labelOf,
    required this.leadingOf,
    required this.searchable,
    required this.searchHint,
  });

  final String title;
  final List<String> options;
  final List<String> initial;
  final String Function(String) labelOf;
  final LuxeOptionLeading? leadingOf;
  final bool searchable;
  final String? searchHint;

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late final Set<String> _picked = {...widget.initial};
  String _query = '';

  List<String> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return [
      for (final o in widget.options)
        if (widget.labelOf(o).toLowerCase().contains(q)) o,
    ];
  }

  void _toggle(String o) {
    AppHaptics.selection();
    setState(() => _picked.contains(o) ? _picked.remove(o) : _picked.add(o));
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final media = MediaQuery.of(context);
    // Keep the pick order stable: options order, not tap order.
    List<String> result() => [
      for (final o in widget.options)
        if (_picked.contains(o)) o,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.78),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted(context).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.headline.copyWith(fontSize: 19),
                    ),
                  ),
                  if (_picked.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(_picked.clear),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.bronze,
                      ),
                      child: Text(context.tr(CatalogL10n.clear)),
                    ),
                ],
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.field(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                ),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final o = visible[i];
                  final on = _picked.contains(o);
                  final lead = widget.leadingOf?.call(o);
                  return CheckboxListTile(
                    value: on,
                    onChanged: (_) => _toggle(o),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.trailing,
                    activeColor: AppColors.bronze,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: on
                        ? AppColors.bronze.withValues(alpha: 0.08)
                        : null,
                    secondary: lead,
                    title: Text(
                      widget.labelOf(o),
                      style: AppTypography.body.copyWith(
                        fontSize: 14.5,
                        fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(result()),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.charcoal,
                      foregroundColor: AppColors.warmWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _picked.isEmpty
                          ? context.tr(CatalogL10n.apply)
                          : '${context.tr(CatalogL10n.apply)} · ${_picked.length}',
                      style: AppTypography.label.copyWith(
                        color: AppColors.warmWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
