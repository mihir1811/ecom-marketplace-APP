import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/luxe_tokens.dart';

/// Min / max numeric inputs for an open-ended range (0 means "no bound").
///
/// Owns its controllers and only rewrites them when the value changes from
/// outside (reset, undo), so it never fights the user mid-typing (e.g. "1.").
class LuxeRangeFields extends StatefulWidget {
  const LuxeRangeFields({
    required this.min,
    required this.max,
    required this.onChanged,
    required this.minLabel,
    required this.maxLabel,
    super.key,
    this.title,
    this.minHint = '0',
    this.maxHint,
    this.prefix,
    this.suffix,
    this.invalidLabel,
  });

  final String? title;
  final double min;
  final double max;
  final void Function(double min, double max) onChanged;
  final String minLabel;
  final String maxLabel;
  final String minHint;
  final String? maxHint;
  final String? prefix;
  final String? suffix;

  /// Shown under the max field when max is set below min.
  final String? invalidLabel;

  @override
  State<LuxeRangeFields> createState() => _LuxeRangeFieldsState();
}

class _LuxeRangeFieldsState extends State<LuxeRangeFields> {
  late final _min = TextEditingController(text: _text(widget.min));
  late final _max = TextEditingController(text: _text(widget.max));

  static String _text(double v) {
    if (v <= 0) return '';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';
  }

  static double _parse(String s) => double.tryParse(s.trim()) ?? 0;

  @override
  void didUpdateWidget(LuxeRangeFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_parse(_min.text) != widget.min) _min.text = _text(widget.min);
    if (_parse(_max.text) != widget.max) _max.text = _text(widget.max);
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_parse(_min.text), _parse(_max.text));

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final invalid = widget.max > 0 && widget.min > widget.max;

    Widget field(
      TextEditingController c,
      String label,
      String? hint, {
      String? error,
    }) {
      return TextField(
        controller: c,
        onChanged: (_) => _emit(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        scrollPadding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
        style: LuxeType.figure(p.ink, size: 14.5),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          hintText: hint,
          prefixText: widget.prefix,
          suffixText: widget.suffix,
          errorText: error,
          errorMaxLines: 2,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null) ...[
          Text(widget.title!, style: LuxeType.label(p.inkMuted, size: 12.5)),
          const SizedBox(height: 6),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field(_min, widget.minLabel, widget.minHint)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
              child: Text('–', style: LuxeType.label(p.inkFaint)),
            ),
            Expanded(
              child: field(
                _max,
                widget.maxLabel,
                widget.maxHint,
                error: invalid ? widget.invalidLabel : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
