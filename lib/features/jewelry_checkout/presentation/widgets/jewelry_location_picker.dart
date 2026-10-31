import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';

/// One entry of a location list: ISO / state code and its name. Cities use
/// the name as the code.
typedef JewelryLocation = ({String code, String name});

/// Picked from a list but not listed: the buyer types it instead.
const JewelryLocation jewelryLocationNotListed = (code: '', name: '');

/// Searchable list of [items] in a sheet. With [notListedLabel] the list
/// ends with that row, which returns [jewelryLocationNotListed].
Future<JewelryLocation?> showJewelryLocationSheet(
  BuildContext context, {
  required String title,
  required List<JewelryLocation> items,
  String? selectedCode,
  String? notListedLabel,
}) => showLuxeSheet<JewelryLocation>(
  context,
  title: title,
  scrollable: false,
  builder: (_) => _LocationList(
    items: items,
    selectedCode: selectedCode,
    notListedLabel: notListedLabel,
  ),
);

class _LocationList extends StatefulWidget {
  const _LocationList({
    required this.items,
    required this.selectedCode,
    required this.notListedLabel,
  });

  final List<JewelryLocation> items;
  final String? selectedCode;
  final String? notListedLabel;

  @override
  State<_LocationList> createState() => _LocationListState();
}

class _LocationListState extends State<_LocationList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? widget.items
        : [
            for (final l in widget.items)
              if (l.name.toLowerCase().contains(q) || l.code.toLowerCase() == q)
                l,
          ];
    final notListed = widget.notListedLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.items.length > 8) ...[
          TextField(
            autofocus: false,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: context.tr(CatalogL10n.search),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: shown.length + (notListed == null ? 0 : 1),
            itemBuilder: (context, i) {
              if (i == shown.length) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined, color: p.inkMuted),
                  title: Text(
                    notListed!,
                    style: LuxeType.label(p.inkMuted, size: 14.5),
                  ),
                  onTap: () =>
                      Navigator.of(context).pop(jewelryLocationNotListed),
                );
              }
              final l = shown[i];
              final selected = l.code == widget.selectedCode;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l.name,
                  style: LuxeType.label(
                    selected ? p.accent : p.ink,
                    size: 14.5,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check_rounded, color: p.accent)
                    : null,
                onTap: () => Navigator.of(context).pop(l),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Read-only form field that opens a picker: shows [value] (or nothing)
/// under [label] and validates like a text field.
class JewelryPickerField extends StatelessWidget {
  const JewelryPickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.validator,
    this.loading = false,
    super.key,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final String? Function(String? value)? validator;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      // Rebuilt with the new value whenever the parent picks one.
      key: ValueKey('$label|$value'),
      initialValue: value,
      validator: validator,
      builder: (field) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        child: InputDecorator(
          isEmpty: (value ?? '').isEmpty,
          decoration: InputDecoration(
            labelText: label,
            errorText: field.errorText,
            suffixIcon: loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.expand_more_rounded),
          ),
          child: Text(
            value ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
