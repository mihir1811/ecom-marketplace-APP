import '../../../../core/l10n/translations/account_commerce_messages.dart';
import '../../../../core/l10n/translations/catalog_messages.dart';
import '../../../../core/l10n/translations/jewelry_flow_messages.dart';
import '../../../../core/l10n/translations/rough_flow_messages.dart';
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
    label: AccountCommerceL10n.price,
    winRule: CompareWinRule.lowerBetter,
  ),
  CompareSpecDef(
    key: 'carat',
    label: AccountCommerceL10n.caratWeight,
    winRule: CompareWinRule.higherBetter,
  ),
  CompareSpecDef(key: 'shape', label: AccountCommerceL10n.shape),
  CompareSpecDef(key: 'measurements', label: AccountCommerceL10n.measurements),
  CompareSpecDef(key: 'certificate', label: AccountCommerceL10n.certificate),
  CompareSpecDef(
    key: 'cut',
    label: AccountCommerceL10n.cut,
    winRule: CompareWinRule.gradeBetter,
    gradeOrder: ['Ideal', 'Excellent', 'Very Good', 'Good', 'Fair'],
  ),
  CompareSpecDef(
    key: 'color',
    label: AccountCommerceL10n.color,
    winRule: CompareWinRule.gradeBetter,
    gradeOrder: ['D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M'],
  ),
  CompareSpecDef(
    key: 'clarity',
    label: AccountCommerceL10n.clarity,
    winRule: CompareWinRule.gradeBetter,
    gradeOrder: ['FL', 'IF', 'VVS1', 'VVS2', 'VS1', 'VS2', 'SI1', 'SI2'],
  ),
  CompareSpecDef(
    key: 'table',
    label: AccountCommerceL10n.tablePercent,
    winRule: CompareWinRule.none,
  ),
  CompareSpecDef(
    key: 'depth',
    label: AccountCommerceL10n.depthPercent,
    winRule: CompareWinRule.none,
  ),
  CompareSpecDef(key: 'ratio', label: AccountCommerceL10n.ratio),
  CompareSpecDef(
    key: 'polish',
    label: AccountCommerceL10n.polish,
    winRule: CompareWinRule.gradeBetter,
    gradeOrder: ['Ideal', 'Excellent', 'Very Good', 'Good', 'Fair'],
  ),
  CompareSpecDef(
    key: 'symmetry',
    label: AccountCommerceL10n.symmetry,
    winRule: CompareWinRule.gradeBetter,
    gradeOrder: ['Ideal', 'Excellent', 'Very Good', 'Good', 'Fair'],
  ),
  CompareSpecDef(key: 'fluorescence', label: AccountCommerceL10n.fluorescence),
  CompareSpecDef(key: 'lab', label: AccountCommerceL10n.lab),
];

/// Spec rows for gemstone comparison.
const gemstoneCompareSpecs = <CompareSpecDef>[
  CompareSpecDef(
    key: 'price',
    label: AccountCommerceL10n.price,
    winRule: CompareWinRule.lowerBetter,
  ),
  CompareSpecDef(
    key: 'carat',
    label: AccountCommerceL10n.totalCarat,
    winRule: CompareWinRule.higherBetter,
  ),
  CompareSpecDef(key: 'type', label: AccountCommerceL10n.type),
  CompareSpecDef(key: 'origin', label: AccountCommerceL10n.origin),
  CompareSpecDef(key: 'cut', label: AccountCommerceL10n.cut),
  CompareSpecDef(key: 'color', label: AccountCommerceL10n.color),
  CompareSpecDef(key: 'clarity', label: AccountCommerceL10n.clarity),
  CompareSpecDef(key: 'treatment', label: AccountCommerceL10n.treatment),
  CompareSpecDef(key: 'dimensions', label: AccountCommerceL10n.dimensions),
  CompareSpecDef(key: 'shape', label: AccountCommerceL10n.shape),
  CompareSpecDef(
    key: 'hardness',
    label: AccountCommerceL10n.hardness,
    winRule: CompareWinRule.higherBetter,
  ),
  CompareSpecDef(key: 'lab', label: AccountCommerceL10n.lab),
  CompareSpecDef(key: 'certificate', label: AccountCommerceL10n.certificate),
];

/// Spec rows for watch comparison.
const watchCompareSpecs = <CompareSpecDef>[
  CompareSpecDef(
    key: 'price',
    label: AccountCommerceL10n.price,
    winRule: CompareWinRule.lowerBetter,
  ),
  CompareSpecDef(key: 'brand', label: AccountCommerceL10n.brand),
  CompareSpecDef(key: 'model', label: AccountCommerceL10n.model),
  CompareSpecDef(key: 'movement', label: AccountCommerceL10n.movement),
  CompareSpecDef(key: 'caseMaterial', label: AccountCommerceL10n.caseMaterial),
  CompareSpecDef(key: 'dialColor', label: AccountCommerceL10n.dialColor),
  CompareSpecDef(key: 'gender', label: AccountCommerceL10n.gender),
  CompareSpecDef(
    key: 'year',
    label: AccountCommerceL10n.year,
    winRule: CompareWinRule.higherBetter,
  ),
];

/// Spec rows for fine jewelry comparison.
const jewelryCompareSpecs = <CompareSpecDef>[
  CompareSpecDef(
    key: 'price',
    label: AccountCommerceL10n.price,
    winRule: CompareWinRule.lowerBetter,
  ),
  CompareSpecDef(key: 'category', label: JewelryFlowL10n.category),
  CompareSpecDef(key: 'metal', label: CatalogL10n.metal),
  CompareSpecDef(key: 'purity', label: CatalogL10n.metalPurity),
  CompareSpecDef(
    key: 'metalWeight',
    label: CatalogL10n.metalWeight,
    winRule: CompareWinRule.higherBetter,
  ),
  CompareSpecDef(key: 'stone', label: CatalogL10n.stone),
  CompareSpecDef(
    key: 'stoneWeight',
    label: CatalogL10n.stoneWeight,
    winRule: CompareWinRule.higherBetter,
  ),
  CompareSpecDef(key: 'certificate', label: AccountCommerceL10n.certificate),
  CompareSpecDef(key: 'gender', label: AccountCommerceL10n.gender),
];

/// Spec rows for rough parcel comparison.
const roughCompareSpecs = <CompareSpecDef>[
  CompareSpecDef(
    key: 'price',
    label: AccountCommerceL10n.price,
    winRule: CompareWinRule.lowerBetter,
  ),
  CompareSpecDef(
    key: 'carat',
    label: AccountCommerceL10n.totalCarat,
    winRule: CompareWinRule.higherBetter,
  ),
  CompareSpecDef(
    key: 'ppc',
    label: RoughFlowL10n.pricePerCarat,
    winRule: CompareWinRule.lowerBetter,
  ),
  CompareSpecDef(key: 'pieces', label: RoughFlowL10n.pieces),
  CompareSpecDef(key: 'avgCarat', label: RoughFlowL10n.avgCarat),
  CompareSpecDef(key: 'type', label: AccountCommerceL10n.type),
  CompareSpecDef(key: 'crystalShape', label: RoughFlowL10n.crystalShape),
  CompareSpecDef(
    key: 'quality',
    label: RoughFlowL10n.roughQuality,
    winRule: CompareWinRule.gradeBetter,
    gradeOrder: [
      'Gem quality',
      'Near-gem quality',
      'Industrial',
      'Crushing / Boart',
    ],
  ),
  CompareSpecDef(key: 'potential', label: RoughFlowL10n.manufacturingPotential),
  CompareSpecDef(key: 'color', label: AccountCommerceL10n.color),
  CompareSpecDef(key: 'clarity', label: AccountCommerceL10n.clarity),
  CompareSpecDef(
    key: 'yield',
    label: RoughFlowL10n.estimatedYield,
    winRule: CompareWinRule.higherBetter,
  ),
  CompareSpecDef(key: 'parcelType', label: RoughFlowL10n.parcelType),
  CompareSpecDef(key: 'origin', label: AccountCommerceL10n.origin),
];

List<CompareSpecDef> specsForCategory(CompareCategory category) {
  return switch (category) {
    CompareCategory.diamond => diamondCompareSpecs,
    CompareCategory.gemstone => gemstoneCompareSpecs,
    CompareCategory.watch => watchCompareSpecs,
    CompareCategory.jewelry => jewelryCompareSpecs,
    CompareCategory.roughDiamond => roughCompareSpecs,
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
      final worst = usable
          .map((i) => ranks[i]!)
          .reduce((a, b) => a > b ? a : b);
      if (best == worst) return List<bool>.filled(n, false);

      return List<bool>.generate(
        n,
        (i) => ranks[i] != null && ranks[i] == best,
      );

    case CompareWinRule.none:
      return List<bool>.filled(n, false);
  }
}
