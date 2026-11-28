import '../../../../core/l10n/translations/account_commerce_messages.dart';
import '../../../../core/l10n/translations/rough_flow_messages.dart';
import 'compare_category.dart';
import 'compare_item.dart';
import 'compare_spec.dart';

/// A titled run of spec rows on the comparison screen.
class CompareSpecGroup {
  const CompareSpecGroup({required this.titleKey, required this.specs});

  final String titleKey;
  final List<CompareSpecDef> specs;
}

const _groupOrder = <CompareCategory, List<(String, List<String>)>>{
  CompareCategory.diamond: [
    (AccountCommerceL10n.compareGroupEssentials, ['price', 'carat', 'shape']),
    (AccountCommerceL10n.compareGroupFourCs, ['cut', 'color', 'clarity']),
    (
      AccountCommerceL10n.compareGroupProportions,
      ['measurements', 'table', 'depth', 'ratio'],
    ),
    (
      AccountCommerceL10n.compareGroupFinish,
      ['polish', 'symmetry', 'fluorescence'],
    ),
    (AccountCommerceL10n.compareGroupProvenance, ['certificate', 'lab']),
  ],
  CompareCategory.gemstone: [
    (
      AccountCommerceL10n.compareGroupEssentials,
      ['price', 'carat', 'type', 'shape'],
    ),
    (
      AccountCommerceL10n.compareGroupCharacter,
      ['cut', 'color', 'clarity', 'treatment'],
    ),
    (AccountCommerceL10n.compareGroupProportions, ['dimensions', 'hardness']),
    (
      AccountCommerceL10n.compareGroupProvenance,
      ['origin', 'lab', 'certificate'],
    ),
  ],
  CompareCategory.watch: [
    (
      AccountCommerceL10n.compareGroupEssentials,
      ['price', 'brand', 'model', 'year'],
    ),
    (
      AccountCommerceL10n.compareGroupCraft,
      ['movement', 'caseMaterial', 'dialColor'],
    ),
  ],
  CompareCategory.roughDiamond: [
    (
      AccountCommerceL10n.compareGroupEssentials,
      ['price', 'carat', 'ppc', 'type'],
    ),
    (
      AccountCommerceL10n.compareGroupCharacter,
      ['crystalShape', 'quality', 'potential', 'color', 'clarity'],
    ),
    (
      RoughFlowL10n.compareGroupParcel,
      ['pieces', 'avgCarat', 'yield', 'parcelType'],
    ),
    (AccountCommerceL10n.compareGroupProvenance, ['origin']),
  ],
  CompareCategory.jewelry: [
    (AccountCommerceL10n.compareGroupEssentials, ['price', 'category']),
    (AccountCommerceL10n.compareGroupMetal, ['metal', 'purity', 'metalWeight']),
    (AccountCommerceL10n.compareGroupStones, ['stone', 'stoneWeight']),
    (AccountCommerceL10n.compareGroupProvenance, ['certificate']),
  ],
};

/// [specs] arranged into titled groups; anything unmapped lands in Details.
List<CompareSpecGroup> groupSpecs(
  CompareCategory category,
  List<CompareSpecDef> specs,
) {
  final byKey = {for (final s in specs) s.key: s};
  final used = <String>{};
  final groups = <CompareSpecGroup>[];
  final order = _groupOrder[category] ?? const <(String, List<String>)>[];
  for (final (title, keys) in order) {
    final rows = [
      for (final k in keys)
        if (byKey[k] != null) byKey[k]!,
    ];
    used.addAll(rows.map((e) => e.key));
    if (rows.isNotEmpty) {
      groups.add(CompareSpecGroup(titleKey: title, specs: rows));
    }
  }
  final rest = [
    for (final s in specs)
      if (!used.contains(s.key)) s,
  ];
  if (rest.isNotEmpty) {
    groups.add(
      CompareSpecGroup(
        titleKey: AccountCommerceL10n.compareGroupDetails,
        specs: rest,
      ),
    );
  }
  return groups;
}

/// Whether [value] stands for "no data".
bool isMissingCompareValue(String? value) {
  final v = value?.trim() ?? '';
  return v.isEmpty || v == '-' || v == '—' || v.toUpperCase() == 'N/A';
}

/// Per-row and per-piece lead tallies for a comparison.
class CompareInsights {
  CompareInsights._(
    this.leaders,
    this.wins,
    this.decisive,
    this.identical,
    this.empty,
  );

  factory CompareInsights.of(
    List<CompareItem> items,
    List<CompareSpecDef> specs,
  ) {
    final leaders = <String, List<bool>>{};
    final identical = <String>{};
    final empty = <String>{};
    final wins = List<int>.filled(items.length, 0);
    var decisive = 0;
    for (final spec in specs) {
      final displays = [for (final e in items) e.displayValues[spec.key] ?? ''];
      final flags = leadingFlags(
        displayValues: displays,
        numericValues: [for (final e in items) e.numericValues[spec.key]],
        spec: spec,
      );
      leaders[spec.key] = flags;
      if (flags.contains(true)) {
        decisive++;
        for (var i = 0; i < flags.length; i++) {
          if (flags[i]) wins[i]++;
        }
      }
      if (displays.every(isMissingCompareValue)) empty.add(spec.key);
      final normalized = displays.map((e) => e.trim().toLowerCase()).toSet();
      if (items.length > 1 && normalized.length == 1) identical.add(spec.key);
    }
    return CompareInsights._(leaders, wins, decisive, identical, empty);
  }

  /// Spec key → whether each piece leads that row.
  final Map<String, List<bool>> leaders;

  /// Rows each piece leads.
  final List<int> wins;

  /// Rows where some piece leads.
  final int decisive;

  /// Spec keys where every piece shows the same value.
  final Set<String> identical;

  /// Spec keys no piece has a value for.
  final Set<String> empty;

  bool leads(String key, int index) =>
      (leaders[key] ?? const []).elementAtOrNull(index) ?? false;

  /// Index of the piece with the most leads, when it is the only one.
  int? get frontRunner {
    if (wins.length < 2 || decisive == 0) return null;
    var best = 0;
    for (var i = 1; i < wins.length; i++) {
      if (wins[i] > wins[best]) best = i;
    }
    final ties = wins.where((w) => w == wins[best]).length;
    return ties == 1 && wins[best] > 0 ? best : null;
  }
}
