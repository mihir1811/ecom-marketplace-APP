/// Tolerant reader for model-produced tool arguments: case/spacing
/// insensitive vocabulary matching, numbers sent as strings, single values
/// sent instead of lists. Unknown values are collected in [ignored].
class CatalogArgs {
  CatalogArgs(this._args);

  final Map<String, Object?> _args;
  final List<String> ignored = [];

  /// Values of [key] matched onto [vocabulary] (canonical spelling kept).
  List<String> pick(String key, Iterable<String> vocabulary) {
    final picked = <String>[];
    for (final raw in strings(key)) {
      final match = matchValue(raw, vocabulary);
      if (match == null) {
        ignored.add('$key:$raw');
      } else if (!picked.contains(match)) {
        picked.add(match);
      }
    }
    return picked;
  }

  /// Like [pick] but returns values that did not match instead of dropping
  /// them (e.g. to fall back to free-text search).
  (List<String> matched, List<String> unmatched) split(
    String key,
    Iterable<String> vocabulary,
  ) {
    final matched = <String>[];
    final unmatched = <String>[];
    for (final raw in strings(key)) {
      final match = matchValue(raw, vocabulary);
      if (match == null) {
        unmatched.add(raw);
      } else if (!matched.contains(match)) {
        matched.add(match);
      }
    }
    return (matched, unmatched);
  }

  String? text(String key) {
    final value = _args[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String> strings(String key) => switch (_args[key]) {
    final String s when s.trim().isNotEmpty => [s.trim()],
    final List<Object?> list => [
      for (final item in list)
        if (item != null && item.toString().trim().isNotEmpty)
          item.toString().trim(),
    ],
    _ => const [],
  };

  double? number(String key) {
    final n = switch (_args[key]) {
      final num v => v.toDouble(),
      final String v => double.tryParse(v.trim()),
      _ => null,
    };
    return n == null || n.isNaN || n < 0 ? null : n;
  }

  /// `[min, max]` from `<key>_min` / `<key>_max`, swapped when reversed.
  (double?, double?) range(String key) {
    final min = number('${key}_min');
    final max = number('${key}_max');
    if (min != null && max != null && min > max) return (max, min);
    return (min, max);
  }

  bool flag(String key) => _args[key] == true;

  /// Free-text names (sellers, cities) as said, de-duplicated ignoring case.
  List<String> names(String key) {
    final out = <String>[];
    for (final raw in strings(key)) {
      final name = raw.replaceAll(RegExp(r'\s+'), ' ');
      if (!out.any((n) => n.toLowerCase() == name.toLowerCase())) {
        out.add(name);
      }
    }
    return out;
  }

  /// Include/exclude name pairs; a name the user excluded never stays in
  /// the include list.
  (List<String> include, List<String> exclude) includeExclude(
    String includeKey,
    String excludeKey,
  ) {
    final exclude = names(excludeKey);
    bool excluded(String n) =>
        exclude.any((e) => e.toLowerCase() == n.toLowerCase());
    return ([...names(includeKey).where((n) => !excluded(n))], exclude);
  }

  /// One [availabilityValues] status, or null.
  String? availability() {
    final raw = text('availability');
    final match = matchValue(raw, availabilityValues);
    if (raw != null && match == null) ignored.add('availability:$raw');
    return match;
  }

  /// Listing statuses shared by every catalog finder.
  static const availabilityValues = ['Available', 'On Memo', 'On Hold', 'Sold'];

  static String? matchValue(String? raw, Iterable<String> vocabulary) {
    if (raw == null) return null;
    final key = normalize(raw);
    if (key.isEmpty) return null;
    // Exact spelling first, so "AAA" never lands on "AAA+".
    final lower = raw.trim().toLowerCase();
    for (final value in vocabulary) {
      if (value.toLowerCase() == lower) return value;
    }
    for (final value in vocabulary) {
      if (normalize(value) == key) return value;
    }
    return null;
  }

  static String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// Schema for an array of strings limited to [values].
Map<String, Object?> enumList(Iterable<String> values, [String? hint]) => {
  'type': 'array',
  'items': {'type': 'string', 'enum': values.toList()},
  if (hint != null) 'description': hint,
};

/// Schema for free-text names the catalog has no fixed list for.
Map<String, Object?> textList(String hint) => {
  'type': 'array',
  'items': {'type': 'string'},
  'description': hint,
};

/// Schema for a yes-only switch.
Map<String, Object?> flagField(String hint) => {
  'type': 'boolean',
  'description': hint,
};

/// Seller include/exclude slots shared by stone catalogs.
Map<String, Object?> sellerFields() => {
  'sellers': textList(
    'Only these seller / company / supplier names, as said (e.g. "SRK").',
  ),
  'exclude_sellers': textList(
    'Hide these sellers: "except SRK", "not from SRK", "SRK sivay".',
  ),
  'seller_locations': textList('Only sellers in these cities / countries.'),
  'exclude_seller_locations': textList('Hide sellers in these places.'),
};

/// Listing slots shared by every catalog.
Map<String, Object?> listingFields() => {
  'availability': {
    'type': 'string',
    'enum': CatalogArgs.availabilityValues,
    'description': 'Only when the user names a status ("in stock").',
  },
  'make_an_offer': flagField('Only listings that accept offers.'),
};

/// Schema for a number with an optional [hint].
Map<String, Object?> numberField([String? hint]) => {
  'type': 'number',
  if (hint != null) 'description': hint,
};
