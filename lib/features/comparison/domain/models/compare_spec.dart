import 'compare_category.dart';

/// How a comparable spec picks a "leading" value among selected items.
enum CompareWinRule {
  /// Lower numeric value wins (e.g. price).
  lowerBetter,

  /// Higher numeric value wins (e.g. carat, year, hardness).
  higherBetter,

  /// Grade string ranked by [gradeOrder] (best first).
  gradeBetter,

  /// Not comparable — never highlighted.
  none,
}

/// Column definition for one comparison table row.
class CompareSpecDef {
  const CompareSpecDef({
    required this.key,
    required this.label,
    this.winRule = CompareWinRule.none,
    this.gradeOrder = const [],
  });

  final String key;
  final String label;
  final CompareWinRule winRule;

  /// Best → worst for [CompareWinRule.gradeBetter].
  final List<String> gradeOrder;
}

/// Spec rows for diamond (lab + natural) comparison.
const diamondCompareSpecs = <CompareSpecDef>[
  CompareSpecDef(
    key: 'price',
    label: 'Price',
    winRule: CompareWinRule.lowerBetter,
  ),
  CompareSpecDef(
    key: 'carat',
    label: 'Carat Weight',
    winRule: CompareWinRule.higherBetter,
  ),
  CompareSpecDef(key: 'shape', label: 'Shape'),
  CompareSpecDef(key: 'measurements', label: 'Measurements'),
  CompareSpecDef(key: 'certificate', label: 'Certificate #'),
  CompareSpecDef(
    key: 'cut',
    label: 'Cut',
    winRule: CompareWinRule.gradeBetter,
    gradeOrder: ['Ideal', 'Excellent', 'Very Good', 'Good', 'Fair'],
  ),
  CompareSpecDef(
    key: 'color',
    label: 'Color',
    winRule: CompareWinRule.gradeBetter,
    gradeOrder: ['D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M'],
  ),
  CompareSpecDef(
    key: 'clarity',
    label: 'Clarity',
    winRule: CompareWinRule.gradeBetter,
    gradeOrder: [
      'FL',
      'IF',
      'VVS1',
      'VVS2',
      'VS1',
      'VS2',
      'SI1',
      'SI2',
    ],
  ),
  CompareSpecDef(
    key: 'table',
    label: 'Table %',
    winRule: CompareWinRule.none,
  ),
  CompareSpecDef(
    key: 'depth',
    label: 'Depth %',
    winRule: CompareWinRule.none,
  ),
  CompareSpecDef(key: 'ratio', label: 'Ratio'),
  CompareSpecDef(
    key: 'polish',
    label: 'Polish',
    winRule: CompareWinRule.gradeBetter,
    gradeOrder: ['Ideal', 'Excellent', 'Very Good', 'Good', 'Fair'],
  ),
  CompareSpecDef(
    key: 'symmetry',
    label: 'Symmetry',
    winRule: CompareWinRule.gradeBetter,
    gradeOrder: ['Ideal', 'Excellent', 'Very Good', 'Good', 'Fair'],
  ),
  CompareSpecDef(key: 'fluorescence', label: 'Fluorescence'),
  CompareSpecDef(key: 'lab', label: 'Lab'),
];

/// Spec rows for gemstone comparison.
const gemstoneCompareSpecs = <CompareSpecDef>[
  CompareSpecDef(
    key: 'price',
    label: 'Price',
    winRule: CompareWinRule.lowerBetter,
  ),
  CompareSpecDef(
    key: 'carat',
    label: 'Total Carat',
    winRule: CompareWinRule.higherBetter,
  ),
  CompareSpecDef(key: 'type', label: 'Type'),
  CompareSpecDef(key: 'origin', label: 'Origin'),
  CompareSpecDef(key: 'cut', label: 'Cut'),
  CompareSpecDef(key: 'color', label: 'Color'),
  CompareSpecDef(key: 'clarity', label: 'Clarity'),
  CompareSpecDef(key: 'treatment', label: 'Treatment'),
  CompareSpecDef(key: 'dimensions', label: 'Dimensions'),
  CompareSpecDef(key: 'shape', label: 'Shape'),
  CompareSpecDef(
    key: 'hardness',
    label: 'Hardness',
    winRule: CompareWinRule.higherBetter,
  ),
  CompareSpecDef(key: 'lab', label: 'Lab'),
  CompareSpecDef(key: 'certificate', label: 'Certificate #'),
];

/// Spec rows for watch comparison.
const watchCompareSpecs = <CompareSpecDef>[
  CompareSpecDef(
    key: 'price',
    label: 'Price',
    winRule: CompareWinRule.lowerBetter,
  ),
  CompareSpecDef(key: 'brand', label: 'Brand'),
  CompareSpecDef(key: 'model', label: 'Model'),
  CompareSpecDef(key: 'movement', label: 'Movement'),
  CompareSpecDef(key: 'caseMaterial', label: 'Case Material'),
  CompareSpecDef(key: 'dialColor', label: 'Dial Color'),
  CompareSpecDef(key: 'gender', label: 'Gender'),
  CompareSpecDef(
    key: 'year',
    label: 'Year',
    winRule: CompareWinRule.higherBetter,
  ),
];

List<CompareSpecDef> specsForCategory(CompareCategory category) {
  return switch (category) {
    CompareCategory.diamond => diamondCompareSpecs,
    CompareCategory.gemstone => gemstoneCompareSpecs,
    CompareCategory.watch => watchCompareSpecs,
  };
}

/// Computes which item indices are leading for [spec] (ties all win).
List<bool> leadingFlags({
  required List<String> displayValues,
  required List<double?> numericValues,
  required CompareSpecDef spec,
}) {
  final n = displayValues.length;
  if (n == 0 || spec.winRule == CompareWinRule.none) {
    return List<bool>.filled(n, false);
  }

  switch (spec.winRule) {
    case CompareWinRule.lowerBetter:
    case CompareWinRule.higherBetter:
      final usable = <int>[];
      for (var i = 0; i < n; i++) {
        if (numericValues[i] != null) usable.add(i);
      }
      if (usable.length < 2) return List<bool>.filled(n, false);

      final nums = usable.map((i) => numericValues[i]!).toList();
      final best = spec.winRule == CompareWinRule.lowerBetter
          ? nums.reduce((a, b) => a < b ? a : b)
          : nums.reduce((a, b) => a > b ? a : b);

      // Only highlight when there is a meaningful difference.
      final worst = spec.winRule == CompareWinRule.lowerBetter
          ? nums.reduce((a, b) => a > b ? a : b)
          : nums.reduce((a, b) => a < b ? a : b);
      if (best == worst) return List<bool>.filled(n, false);

      return List<bool>.generate(
        n,
        (i) => numericValues[i] != null && numericValues[i] == best,
      );

    case CompareWinRule.gradeBetter:
      final ranks = <int?>[];
      for (var i = 0; i < n; i++) {
        final raw = displayValues[i].trim();
        if (raw.isEmpty || raw.toUpperCase() == 'N/A') {
          ranks.add(null);
          continue;
        }
        final idx = spec.gradeOrder.indexWhere(
          (g) => g.toLowerCase() == raw.toLowerCase(),
        );
        ranks.add(idx >= 0 ? idx : null);
      }
      final usable = <int>[];
      for (var i = 0; i < n; i++) {
        if (ranks[i] != null) usable.add(i);
      }
      if (usable.length < 2) return List<bool>.filled(n, false);

      final best = usable.map((i) => ranks[i]!).reduce((a, b) => a < b ? a : b);
      final worst = usable.map((i) => ranks[i]!).reduce((a, b) => a > b ? a : b);
      if (best == worst) return List<bool>.filled(n, false);

      return List<bool>.generate(
        n,
        (i) => ranks[i] != null && ranks[i] == best,
      );

    case CompareWinRule.none:
      return List<bool>.filled(n, false);
  }
}
