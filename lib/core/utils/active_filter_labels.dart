/// Collects readable active-filter pills ("Rolex", "Under $5k", "18K") and
/// tracks how many summary items of each section [S] they cover, so the
/// caller can still show a "Section · n" pill for anything without a value.
class ActiveFilterLabels<S> {
  final List<String> _labels = [];
  final Map<S, int> _covered = {};

  /// Adds [label] covering [covers] summary items of [section].
  void add(S section, String label, {int covers = 1}) {
    _labels.add(label);
    _covered[section] = (_covered[section] ?? 0) + covers;
  }

  /// One pill for [values] ("A, B" / "A, B +3"), optionally prefixed.
  void values(S section, Iterable<String> values, {String? name}) {
    final list = values.toList();
    if (list.isEmpty) return;
    final text = list.length <= 3
        ? list.join(', ')
        : '${list.take(2).join(', ')} +${list.length - 2}';
    add(section, name == null ? text : '$name: $text', covers: list.length);
  }

  /// "$A–$B", "$A+" or "Under $B"; nothing when both ends are unset.
  void range(
    S section, {
    required double? min,
    required double? max,
    required String Function(double v) format,
    String suffix = '',
  }) {
    if (min == null && max == null) return;
    final label = min != null && max != null
        ? '${format(min)}–${format(max)}'
        : min != null
        ? '${format(min)}+'
        : 'Under ${format(max!)}';
    add(section, '$label$suffix');
  }

  int covered(S section) => _covered[section] ?? 0;

  /// Value pills, then "title · n" for items no value pill covers.
  List<String> build({
    required Iterable<S> sections,
    required int Function(S section) count,
    required String Function(S section) title,
  }) => [
    ..._labels,
    for (final s in sections)
      if (count(s) - covered(s) > 0) '${title(s)} · ${count(s) - covered(s)}',
  ];

  /// Trims trailing zeros: 2.50 → 2.5, 3.00 → 3.
  static String number(double v) =>
      v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
}
