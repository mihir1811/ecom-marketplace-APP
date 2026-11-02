import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/luxe_tokens.dart';
import '../filters/filter_chip.dart';
import '../filters/filter_section_header.dart';

/// Titled multi-select chip group used inside finder sections.
///
/// Long option lists collapse to [initialVisible] chips behind a
/// "show all" toggle; [searchHint] adds an inline filter field that reveals
/// every match while typing.
class LuxeChipGroup extends StatefulWidget {
  const LuxeChipGroup({
    required this.options,
    required this.selected,
    required this.onToggle,
    super.key,
    this.title,
    this.infoText,
    this.labelOf,
    this.initialVisible,
    this.searchHint,
    this.showAllLabel,
    this.showLessLabel,
    this.emptyLabel,
  });

  final String? title;
  final String? infoText;
  final List<String> options;
  final Iterable<String> selected;
  final ValueChanged<String> onToggle;
  final String Function(String)? labelOf;

  /// Chips shown before "show all"; null shows every option.
  final int? initialVisible;
  final String? searchHint;

  /// "Show all ({count})" — `{count}` is replaced with the hidden count.
  final String? showAllLabel;
  final String? showLessLabel;
  final String? emptyLabel;

  @override
  State<LuxeChipGroup> createState() => _LuxeChipGroupState();
}

class _LuxeChipGroupState extends State<LuxeChipGroup> {
  bool _expanded = false;
  String _query = '';
  late final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final q = _query.trim().toLowerCase();
    final label = widget.labelOf ?? (String v) => v;
    final matches = q.isEmpty
        ? widget.options
        : [
            for (final o in widget.options)
              if (label(o).toLowerCase().contains(q)) o,
          ];
    final limit = widget.initialVisible;
    final collapsible =
        q.isEmpty && limit != null && widget.options.length > limit;
    // Keep selected chips visible even while collapsed.
    final shown = !collapsible || _expanded
        ? matches
        : [
            for (var i = 0; i < matches.length; i++)
              if (i < limit || widget.selected.contains(matches[i])) matches[i],
          ];
    final hidden = matches.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null) ...[
          FilterSectionHeader(title: widget.title!, infoText: widget.infoText),
          const SizedBox(height: 6),
        ],
        if (widget.searchHint != null) ...[
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            scrollPadding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedSize(
          duration: LuxeMotion.medium,
          curve: LuxeMotion.settle,
          alignment: Alignment.topCenter,
          child: matches.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    widget.emptyLabel ?? '—',
                    style: LuxeType.body(p.inkMuted, size: 13),
                  ),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final o in shown)
                      FilterChipWidget(
                        label: label(o),
                        isSelected: widget.selected.contains(o),
                        onTap: () => widget.onToggle(o),
                      ),
                  ],
                ),
        ),
        if (collapsible && (hidden > 0 || _expanded))
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                AppHaptics.selection();
                setState(() => _expanded = !_expanded);
              },
              style: TextButton.styleFrom(foregroundColor: p.accent),
              icon: Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
              ),
              label: Text(
                _expanded
                    ? (widget.showLessLabel ?? '−')
                    : (widget.showAllLabel ?? '+{count}').replaceAll(
                        '{count}',
                        '$hidden',
                      ),
                style: LuxeType.label(p.accent, size: 12.5),
              ),
            ),
          ),
      ],
    );
  }
}
