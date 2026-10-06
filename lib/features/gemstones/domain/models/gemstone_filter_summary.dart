import 'gemstone_filter_state.dart';

/// Gemstone finder sections, in screen order.
enum GemstoneFinderSection {
  gemType,
  shape,
  sizePrice,
  colorQuality,
  grading,
  listing,
  seller,
  measurements,
}

/// Counts active (non-default) filters per gemstone finder section so the
/// UI can badge sections, show the total on the primary action and
/// summarise collapsed sections without opening them.
class GemstoneFilterSummary {
  GemstoneFilterSummary._(this._counts);

  factory GemstoneFilterSummary.of(GemstoneFilterState s) {
    const d = GemstoneFilterState();
    int flag(bool v) => v ? 1 : 0;
    int range(double a, double b, double da, double db) =>
        flag(a != da || b != db);

    final counts = <GemstoneFinderSection, int>{
      GemstoneFinderSection.gemType:
          s.selectedGemstoneTypes.length + s.selectedBirthstoneMonths.length,
      GemstoneFinderSection.shape: s.selectedShapes.length,
      GemstoneFinderSection.sizePrice:
          range(
            s.minTotalCarat,
            s.maxTotalCarat,
            d.minTotalCarat,
            d.maxTotalCarat,
          ) +
          range(
            s.minTotalPrice,
            s.maxTotalPrice,
            d.minTotalPrice,
            d.maxTotalPrice,
          ) +
          range(
            s.minPricePerPiece,
            s.maxPricePerPiece,
            d.minPricePerPiece,
            d.maxPricePerPiece,
          ) +
          range(
            s.minPricePerCarat,
            s.maxPricePerCarat,
            d.minPricePerCarat,
            d.maxPricePerCarat,
          ) +
          range(
            s.minCaratPerPiece,
            s.maxCaratPerPiece,
            d.minCaratPerPiece,
            d.maxCaratPerPiece,
          ) +
          range(s.minTotalPcs, s.maxTotalPcs, d.minTotalPcs, d.maxTotalPcs) +
          s.selectedCaratQuickRanges.length,
      GemstoneFinderSection.colorQuality:
          s.selectedColors.length +
          s.selectedIntensities.length +
          s.selectedModifiers.length +
          s.selectedFluorescence.length +
          flag(s.selectedFluorescenceColor != null) +
          s.selectedClarities.length +
          flag(s.selectedQualityGrade != null),
      GemstoneFinderSection.grading:
          s.selectedCertifications.length +
          s.selectedCutGrades.length +
          s.selectedTreatments.length,
      GemstoneFinderSection.listing:
          flag(s.separable) +
          flag(s.searchByMedia) +
          flag(s.makeAnOffer) +
          s.selectedAvailabilities.length,
      GemstoneFinderSection.seller:
          s.vendorLocations.length +
          s.companyNames.length +
          s.excludedVendorLocations.length +
          s.excludedCompanyNames.length +
          s.selectedOriginCountries.length +
          flag(s.selectedOrigin != null),
      GemstoneFinderSection.measurements:
          range(s.minLength, s.maxLength, d.minLength, d.maxLength) +
          range(s.minWidth, s.maxWidth, d.minWidth, d.maxWidth) +
          range(s.minHeight, s.maxHeight, d.minHeight, d.maxHeight) +
          range(s.minRatio, s.maxRatio, d.minRatio, d.maxRatio),
    };
    return GemstoneFilterSummary._(counts);
  }

  final Map<GemstoneFinderSection, int> _counts;

  int count(GemstoneFinderSection section) => _counts[section] ?? 0;

  int get total => _counts.values.fold(0, (a, b) => a + b);

  @override
  bool operator ==(Object other) =>
      other is GemstoneFilterSummary &&
      GemstoneFinderSection.values.every((s) => other.count(s) == count(s));

  @override
  int get hashCode => Object.hashAll(GemstoneFinderSection.values.map(count));
}
