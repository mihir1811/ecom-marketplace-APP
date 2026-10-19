import 'diamond_filter_state.dart';
import 'diamond_filter_summary.dart';

/// Readable pills for the active filters ("Round", "2–2.09 ct", "D–F",
/// "VS1–VS2", "Cut: Excellent"), plus how many [DiamondFilterSummary] items
/// each section's pills already cover so callers can summarise the rest.
class DiamondActiveFilters {
  DiamondActiveFilters._(this.labels, this._covered);

  factory DiamondActiveFilters.of(
    DiamondFilterState s, {
    required String Function(double amount) formatPrice,
  }) {
    const d = DiamondFilterState();
    final labels = <String>[];
    final covered = <DiamondFinderSection, int>{};
    void cover(DiamondFinderSection section, int n) =>
        covered[section] = (covered[section] ?? 0) + n;

    if (s.labNatural.usesMeleeFilters) labels.add(s.labNatural.label);
    if (s.labCategory == 'Lab Melee') labels.add(s.labCategory);

    if (s.shapes.isNotEmpty) {
      labels.add(
        s.shapes.length <= 3
            ? s.shapes.join(', ')
            : '${s.shapes.take(2).join(', ')} +${s.shapes.length - 2}',
      );
      cover(DiamondFinderSection.shape, s.shapes.length);
    }

    if (s.minCarat != d.minCarat || s.maxCarat != d.maxCarat) {
      labels.add('${_num(s.minCarat)}–${_num(s.maxCarat)} ct');
      cover(DiamondFinderSection.sizePrice, 1);
    }
    if (s.minPrice != d.minPrice || s.maxPrice != d.maxPrice) {
      labels.add('${formatPrice(s.minPrice)}–${formatPrice(s.maxPrice)}');
      cover(DiamondFinderSection.sizePrice, 1);
    }

    if (s.isFancyColor) cover(DiamondFinderSection.colorClarity, 1);
    if (s.isFancyColor && s.selectedFancyColors.isNotEmpty) {
      labels.add(_list(s.selectedFancyColors));
      cover(DiamondFinderSection.colorClarity, s.selectedFancyColors.length);
    } else if (s.selectedStandardColors.isNotEmpty) {
      labels.add(_grades(s.selectedStandardColors, DiamondFilterState.colors));
      cover(DiamondFinderSection.colorClarity, s.selectedStandardColors.length);
    }
    if (s.minColorIndex != d.minColorIndex ||
        s.maxColorIndex != d.maxColorIndex) {
      labels.add(
        '${DiamondFilterState.colors[s.minColorIndex]}–'
        '${DiamondFilterState.colors[s.maxColorIndex]}',
      );
      cover(DiamondFinderSection.colorClarity, 1);
    }
    if (s.selectedClarityGrades.isNotEmpty) {
      labels.add(
        _grades(s.selectedClarityGrades, DiamondFilterState.clarities),
      );
      cover(DiamondFinderSection.colorClarity, s.selectedClarityGrades.length);
    }
    if (s.minClarityIndex != d.minClarityIndex ||
        s.maxClarityIndex != d.maxClarityIndex) {
      labels.add(
        '${DiamondFilterState.clarities[s.minClarityIndex]}–'
        '${DiamondFilterState.clarities[s.maxClarityIndex]}',
      );
      cover(DiamondFinderSection.colorClarity, 1);
    }

    void named(DiamondFinderSection section, String name, List<String> v) {
      if (v.isEmpty) return;
      labels.add(name.isEmpty ? _list(v) : '$name: ${_list(v)}');
      cover(section, v.length);
    }

    named(DiamondFinderSection.grading, '', s.selectedFinishPreset);
    named(DiamondFinderSection.grading, 'Cut', s.selectedCuts);
    named(DiamondFinderSection.grading, 'Polish', s.selectedPolish);
    named(DiamondFinderSection.grading, 'Symmetry', s.selectedSymmetry);
    named(DiamondFinderSection.grading, '', s.selectedLabs);
    named(DiamondFinderSection.inclusions, 'Fluor.', s.selectedFluorescence);
    named(DiamondFinderSection.listing, '', s.selectedGrowthMethods);
    named(DiamondFinderSection.seller, 'Seller', s.companyNames);
    named(DiamondFinderSection.seller, 'Excl.', s.excludedCompanyNames);
    named(DiamondFinderSection.seller, 'Location', s.vendorLocations);
    named(DiamondFinderSection.seller, 'Excl.', s.excludedVendorLocations);

    return DiamondActiveFilters._(labels, covered);
  }

  final List<String> labels;
  final Map<DiamondFinderSection, int> _covered;

  /// Summary items of [section] already shown in [labels].
  int covered(DiamondFinderSection section) => _covered[section] ?? 0;

  static String _num(double v) =>
      v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');

  static String _list(List<String> values) => values.length <= 3
      ? values.join(', ')
      : '${values.take(2).join(', ')} +${values.length - 2}';

  /// "D–F" for a contiguous run on [scale], otherwise a short list.
  static String _grades(List<String> values, List<String> scale) {
    if (values.length < 3) return values.join(', ');
    final idx = [for (final v in values) scale.indexOf(v)]..sort();
    final contiguous =
        !idx.contains(-1) && idx.last - idx.first == idx.length - 1;
    return contiguous
        ? '${scale[idx.first]}–${scale[idx.last]}'
        : _list(values);
  }
}
