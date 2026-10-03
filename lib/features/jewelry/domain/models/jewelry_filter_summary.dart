import 'jewelry_filter_state.dart';

/// Jewelry filter sections, in screen order.
enum JewelryFilterSection { style, price, metal, stone, size, quality, listing }

/// Counts active filters per jewelry filter section so the UI can badge
/// sections, show the total on the primary action and summarise collapsed
/// sections without opening them.
///
/// Style chips on the results page (sub-categories) are not counted: they
/// are always visible there.
class JewelryFilterSummary {
  JewelryFilterSummary._(this._counts);

  factory JewelryFilterSummary.of(JewelryFilterState s) {
    int flag(bool v) => v ? 1 : 0;
    final counts = <JewelryFilterSection, int>{
      JewelryFilterSection.style: s.genders.length + s.occasions.length,
      JewelryFilterSection.price: flag(
        s.priceMin > JewelryFilterState.priceMinLimit ||
            s.priceMax < JewelryFilterState.priceMaxLimit,
      ),
      JewelryFilterSection.metal:
          s.metalTypes.length +
          s.metalColors.length +
          s.metalPurities.length +
          s.metalFinishes.length +
          s.platings.length +
          flag(
            s.metalWeightMin > JewelryFilterState.metalWeightMinLimit ||
                s.metalWeightMax < JewelryFilterState.metalWeightMaxLimit,
          ),
      JewelryFilterSection.stone:
          flag(s.stoneType != null) +
          s.stoneCategories.length +
          s.stoneShapes.length +
          s.stoneColors.length +
          s.stoneClarities.length +
          s.stoneSettings.length +
          flag(
            s.stoneWeightMin > JewelryFilterState.stoneWeightMinLimit ||
                s.stoneWeightMax < JewelryFilterState.stoneWeightMaxLimit,
          ),
      JewelryFilterSection.size:
          s.ringSizes.length +
          s.braceletSizes.length +
          s.braceletLengths.length +
          s.chainLengths.length +
          s.necklaceLengths.length,
      JewelryFilterSection.quality:
          s.certifications.length + s.conditions.length,
      JewelryFilterSection.listing:
          flag(s.selectedAvailability != 'All') +
          flag(s.makeAnOffer) +
          flag(s.withMediaOnly) +
          flag(s.deliveryTime != null),
    };
    return JewelryFilterSummary._(counts);
  }

  final Map<JewelryFilterSection, int> _counts;

  int count(JewelryFilterSection section) => _counts[section] ?? 0;

  int get total => _counts.values.fold(0, (a, b) => a + b);

  @override
  bool operator ==(Object other) =>
      other is JewelryFilterSummary &&
      JewelryFilterSection.values.every((s) => other.count(s) == count(s));

  @override
  int get hashCode => Object.hashAll(JewelryFilterSection.values.map(count));
}

/// Size filters offered for a parent category (empty when none apply).
enum JewelrySizeKind { ring, braceletSize, braceletLength, chain, necklace }

List<JewelrySizeKind> jewelrySizeKindsFor(String? category) =>
    switch (JewelryFilterState.parentCategoryOrDefault(category)) {
      'Rings' => const [JewelrySizeKind.ring],
      'Bracelets' => const [
        JewelrySizeKind.braceletSize,
        JewelrySizeKind.braceletLength,
      ],
      'Chains' => const [JewelrySizeKind.chain],
      'Necklaces' => const [JewelrySizeKind.necklace],
      _ => const [],
    };
