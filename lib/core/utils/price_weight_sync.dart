import 'package:flutter/widgets.dart';

/// Keeps a unit-price field (per carat / per piece) and a total-price field
/// consistent with a weight: editing the unit price recomputes the total,
/// editing the total recomputes the unit price, and a weight change
/// recomputes the total (or the unit price when only a total is entered).
///
/// Listeners react to real text changes only (not cursor moves), and
/// programmatic writes don't fire `onChanged`.
class PriceWeightSync {
  PriceWeightSync({
    required this.unitPrice,
    required this.total,
    required this.weight,
    this.weightSources = const [],
  }) {
    for (final c in [unitPrice, total, ...weightSources]) {
      _last[c] = c.text;
    }
    unitPrice.addListener(_onUnitPrice);
    total.addListener(_onTotal);
    for (final source in weightSources) {
      source.addListener(_onWeight);
    }
  }

  final TextEditingController unitPrice;
  final TextEditingController total;

  /// Current weight (carats or pieces); null or <= 0 disables syncing.
  final double? Function() weight;

  /// Controllers whose edits change [weight].
  final List<TextEditingController> weightSources;

  final _last = <TextEditingController, String>{};
  bool _writing = false;

  void dispose() {
    unitPrice.removeListener(_onUnitPrice);
    total.removeListener(_onTotal);
    for (final source in weightSources) {
      source.removeListener(_onWeight);
    }
  }

  bool _changed(TextEditingController c) {
    if (_writing || _last[c] == c.text) return false;
    _last[c] = c.text;
    return true;
  }

  void _onUnitPrice() {
    if (_changed(unitPrice)) _totalFromUnit();
  }

  void _onTotal() {
    if (_changed(total)) _unitFromTotal();
  }

  void _onWeight() {
    var changed = false;
    for (final source in weightSources) {
      changed = _changed(source) || changed;
    }
    if (!changed) return;
    if (parseAmount(unitPrice.text) != null) {
      _totalFromUnit();
    } else {
      _unitFromTotal();
    }
  }

  void _totalFromUnit() {
    final w = _weight();
    final u = parseAmount(unitPrice.text);
    if (w != null && u != null) _write(total, u * w);
  }

  void _unitFromTotal() {
    final w = _weight();
    final t = parseAmount(total.text);
    if (w != null && t != null) _write(unitPrice, t / w);
  }

  double? _weight() {
    final w = weight();
    return (w == null || w <= 0 || !w.isFinite) ? null : w;
  }

  void _write(TextEditingController c, double value) {
    final text = formatAmount(value);
    _last[c] = text;
    if (c.text == text) return;
    _writing = true;
    c.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _writing = false;
  }

  /// Parses user-typed amounts like `1,250.50`, `$900`, `2.01 ct`.
  static double? parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    final v = double.tryParse(cleaned);
    return (v == null || !v.isFinite) ? null : v;
  }

  /// Two decimals max, trailing zeros trimmed.
  static String formatAmount(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}
