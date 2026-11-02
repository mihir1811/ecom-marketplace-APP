import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/luxe_tokens.dart';
import 'luxe_feedback.dart';

/// One sortable field in [showLuxeToggleSortSheet]: either a single option
/// (e.g. "Default") or an ascending / descending pair the row flips between.
class LuxeSortField<T> {
  const LuxeSortField({
    required this.label,
    required this.options,
    this.directionLabelOf,
  });

  final String label;

  /// One option, or the two directions (first is the default direction).
  final List<T> options;

  /// Short direction text for a two-way field ("Low to High", "A–Z").
  final String Function(T option)? directionLabelOf;

  bool get toggles => options.length == 2;
}

/// Compact sort sheet: one row per field. Tapping a field sorts by it;
/// tapping the active field (or its direction pill) flips the direction.
/// Each change applies at once through [onChanged]; the sheet stays open
/// until dismissed.
Future<void> showLuxeToggleSortSheet<T>(
  BuildContext context, {
  required String title,
  required List<LuxeSortField<T>> fields,
  required T current,
  required ValueChanged<T> onChanged,
}) {
  return showLuxeSheet<void>(
    context,
    title: title,
    builder: (_) => _ToggleSortBody<T>(
      fields: fields,
      initial: current,
      onChanged: onChanged,
    ),
  );
}

class _ToggleSortBody<T> extends StatefulWidget {
  const _ToggleSortBody({
    required this.fields,
    required this.initial,
    required this.onChanged,
  });

  final List<LuxeSortField<T>> fields;
  final T initial;
  final ValueChanged<T> onChanged;

  @override
  State<_ToggleSortBody<T>> createState() => _ToggleSortBodyState<T>();
}

class _ToggleSortBodyState<T> extends State<_ToggleSortBody<T>> {
  late T _current = widget.initial;

  void _tap(LuxeSortField<T> field) {
    final active = field.options.contains(_current);
    final T next;
    if (!active) {
      next = field.options.first;
    } else if (field.toggles) {
      next = field.options.firstWhere((o) => o != _current);
    } else {
      return;
    }
    AppHaptics.selection();
    setState(() => _current = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final field in widget.fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: _row(p, field),
          ),
      ],
    );
  }

  Widget _row(LuxePalette p, LuxeSortField<T> field) {
    final active = field.options.contains(_current);
    // An idle two-way field previews the direction a tap would pick.
    final shown = active ? _current : field.options.first;
    final ascending = field.options.first == shown;
    return Material(
      color: active ? p.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
        onTap: () => _tap(field),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    field.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(
                      active ? p.ink : p.inkMuted,
                      size: 14,
                    ),
                  ),
                ),
                if (field.toggles)
                  AnimatedContainer(
                    duration: LuxeMotion.fast,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: ShapeDecoration(
                      color: active ? p.ink : Colors.transparent,
                      shape: StadiumBorder(
                        side: BorderSide(color: active ? p.ink : p.hairline),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedRotation(
                          turns: ascending ? 0 : 0.5,
                          duration: LuxeMotion.fast,
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            size: 14,
                            color: active ? p.surface : p.inkMuted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          field.directionLabelOf?.call(shown) ?? '',
                          style: LuxeType.label(
                            active ? p.surface : p.inkMuted,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  AnimatedScale(
                    scale: active ? 1 : 0,
                    duration: LuxeMotion.fast,
                    curve: Curves.easeOutBack,
                    child: Icon(Icons.check_rounded, size: 18, color: p.accent),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
