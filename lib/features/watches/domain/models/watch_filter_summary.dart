import 'watch_filter_state.dart';

/// Watch filter sections, in screen order.
enum WatchFilterSection {
  brandModel,
  style,
  price,
  movement,
  caseBezel,
  dial,
  strap,
  condition,
  listing,
}

/// Counts active filters per watch filter section so the UI can badge
/// sections, show the total on the primary action and summarise collapsed
/// sections without opening them.
class WatchFilterSummary {
  WatchFilterSummary._(this._counts);

  factory WatchFilterSummary.of(WatchFilterState s) {
    int flag(bool v) => v ? 1 : 0;
    final counts = <WatchFilterSection, int>{
      WatchFilterSection.brandModel: s.brands.length + s.models.length,
      WatchFilterSection.style: s.categories.length + s.genders.length,
      WatchFilterSection.price: flag(s.priceMin > 0 || s.priceMax > 0),
      WatchFilterSection.movement:
          s.movements.length +
          s.configurations.length +
          s.materials.length +
          s.powerReserves.length +
          s.waterResistances.length,
      WatchFilterSection.caseBezel:
          s.caseShapes.length +
          s.caseSizeRanges.length +
          s.caseMaterials.length +
          s.caseBacks.length +
          s.lugWidths.length +
          s.bezelTypes.length +
          s.bezelMaterials.length,
      WatchFilterSection.dial:
          s.dialColors.length +
          s.preciousStoneTypes.length +
          s.glassMaterials.length +
          s.indexes.length,
      WatchFilterSection.strap:
          s.strapMaterials.length +
          s.strapColors.length +
          s.claspTypes.length +
          s.claspMaterials.length +
          s.crownTypes.length,
      WatchFilterSection.condition:
          s.conditions.length +
          s.modelYears.length +
          s.certifications.length +
          flag(s.boxIncluded) +
          flag(s.papersIncluded) +
          flag(s.warrantyCardIncluded) +
          flag(s.fullSetIncluded),
      WatchFilterSection.listing:
          flag(s.selectedAvailability != 'All') +
          flag(s.makeAnOffer) +
          s.withMedia.length,
    };
    return WatchFilterSummary._(counts);
  }

  final Map<WatchFilterSection, int> _counts;

  int count(WatchFilterSection section) => _counts[section] ?? 0;

  int get total => _counts.values.fold(0, (a, b) => a + b);

  @override
  bool operator ==(Object other) =>
      other is WatchFilterSummary &&
      WatchFilterSection.values.every((s) => other.count(s) == count(s));

  @override
  int get hashCode => Object.hashAll(WatchFilterSection.values.map(count));
}
