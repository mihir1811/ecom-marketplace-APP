import 'bullions_filter_state.dart';

/// Bullion filter sections, in screen order.
enum BullionsFilterSection {
  formWeight,
  price,
  quantity,
  provenance,
  listing,
  dimensions,
}

/// Counts active filters per bullion filter section so the UI can badge
/// sections and summarise collapsed sections without opening them.
class BullionsFilterSummary {
  BullionsFilterSummary._(this._counts);

  factory BullionsFilterSummary.of(BullionsFilterState s) {
    int flag(bool v) => v ? 1 : 0;
    int range(double a, double b) => flag(a > 0 || b > 0);
    final counts = <BullionsFilterSection, int>{
      BullionsFilterSection.formWeight:
          s.shapes.length +
          s.weightChips.length +
          range(s.weightMin, s.weightMax),
      BullionsFilterSection.price: range(s.priceMin, s.priceMax),
      BullionsFilterSection.quantity: range(s.quantityMin, s.quantityMax),
      BullionsFilterSection.provenance:
          s.conditions.length + s.certifications.length + s.mintMarks.length,
      BullionsFilterSection.listing:
          flag(s.selectedAvailability != 'All') + flag(s.makeAnOffer),
      BullionsFilterSection.dimensions:
          range(s.lengthMin, s.lengthMax) +
          range(s.widthMin, s.widthMax) +
          range(s.heightMin, s.heightMax),
    };
    return BullionsFilterSummary._(counts);
  }

  final Map<BullionsFilterSection, int> _counts;

  int count(BullionsFilterSection section) => _counts[section] ?? 0;

  int get total => _counts.values.fold(0, (a, b) => a + b);

  @override
  bool operator ==(Object other) =>
      other is BullionsFilterSummary &&
      BullionsFilterSection.values.every((s) => other.count(s) == count(s));

  @override
  int get hashCode => Object.hashAll(BullionsFilterSection.values.map(count));
}
