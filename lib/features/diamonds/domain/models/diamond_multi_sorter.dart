import '../models/diamond.dart';
import '../models/sorting_criteria.dart';

/// Stable multi-criteria sort: each next criterion only breaks ties from prior ones.
class DiamondMultiSorter {
  const DiamondMultiSorter._();

  static List<Diamond> apply(
    List<Diamond> items,
    List<SortingCriteria> sorting,
  ) {
    if (sorting.isEmpty || items.length < 2) return items;

    final ordered = List<SortingCriteria>.from(sorting)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    final result = List<Diamond>.from(items);
    result.sort((a, b) {
      for (final criteria in ordered) {
        final cmp = _compareField(a, b, criteria.fieldKey);
        if (cmp != 0) {
          return criteria.direction == SortDirection.ascending ? cmp : -cmp;
        }
      }
      return 0;
    });
    return result;
  }

  static int _compareField(Diamond a, Diamond b, String fieldKey) {
    return switch (fieldKey) {
      'price' => a.price.compareTo(b.price),
      'pricePerCarat' => (a.pricePerCarat ?? _ppc(a))
          .compareTo(b.pricePerCarat ?? _ppc(b)),
      'carat' => a.carat.compareTo(b.carat),
      _ => 0,
    };
  }

  static double _ppc(Diamond d) {
    if (d.carat <= 0) return d.price;
    return d.price / d.carat;
  }
}
