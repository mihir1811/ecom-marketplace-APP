import 'jewelry_filter_state.dart';

/// Jewelry filter sections, in screen order.
enum JewelryFilterSection { style, price, metal, stone, listing }

/// Counts active filters per jewelry filter section so the UI can badge
/// sections, show the total on the primary action and summarise collapsed
/// sections without opening them.
///
/// The category and style chips on the results page are not counted: they
/// are always visible there.
class JewelryFilterSummary {
  JewelryFilterSummary._(this._counts);

  factory JewelryFilterSummary.of(JewelryFilterState s) {
    int flag(bool v) => v ? 1 : 0;
    final counts = <JewelryFilterSection, int>{
      JewelryFilterSection.style: s.styles.length + s.occasions.length,
      JewelryFilterSection.price: flag(s.hasPrice),
      JewelryFilterSection.metal: s.metals.length,
      JewelryFilterSection.stone:
          s.gemstones.length + s.origins.length + s.shapes.length,
      JewelryFilterSection.listing:
          flag(s.availability != null) + flag(s.tag != null),
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
