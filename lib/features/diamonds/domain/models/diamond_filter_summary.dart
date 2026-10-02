import 'diamond_filter_state.dart';

/// Finder sections, in screen order.
enum DiamondFinderSection {
  shape,
  sizePrice,
  colorClarity,
  grading,
  inclusions,
  listing,
  seller,
  measurements,
  proportions,
}

/// Counts active (non-default) filters per finder section so the UI can
/// badge sections, show the total on the primary action and summarise
/// collapsed sections without the user opening them.
class DiamondFilterSummary {
  DiamondFilterSummary._(this._counts);

  factory DiamondFilterSummary.of(DiamondFilterState s) {
    const d = DiamondFilterState();
    int flag(bool v) => v ? 1 : 0;
    int range(double a, double b, double da, double db) =>
        flag(a != da || b != db);

    final counts = <DiamondFinderSection, int>{
      DiamondFinderSection.shape: s.shapes.length,
      DiamondFinderSection.sizePrice:
          range(s.minCarat, s.maxCarat, d.minCarat, d.maxCarat) +
          range(s.minPrice, s.maxPrice, d.minPrice, d.maxPrice) +
          range(
            s.minPricePerCarat,
            s.maxPricePerCarat,
            d.minPricePerCarat,
            d.maxPricePerCarat,
          ) +
          s.selectedCaratQuickRanges.length +
          s.selectedSieveIndices.length +
          range(
            s.minCaratPerPcs,
            s.maxCaratPerPcs,
            d.minCaratPerPcs,
            d.maxCaratPerPcs,
          ) +
          range(
            s.minPricePerPcs,
            s.maxPricePerPcs,
            d.minPricePerPcs,
            d.maxPricePerPcs,
          ) +
          range(s.minTotalPcs, s.maxTotalPcs, d.minTotalPcs, d.maxTotalPcs),
      DiamondFinderSection.colorClarity:
          flag(
            s.minColorIndex != d.minColorIndex ||
                s.maxColorIndex != d.maxColorIndex,
          ) +
          flag(s.isFancyColor != d.isFancyColor) +
          s.selectedStandardColors.length +
          s.selectedFancyColors.length +
          s.selectedOvertones.length +
          s.selectedIntensities.length +
          s.selectedClarityGrades.length +
          flag(
            s.minClarityIndex != d.minClarityIndex ||
                s.maxClarityIndex != d.maxClarityIndex,
          ),
      DiamondFinderSection.grading:
          s.selectedFinishPreset.length +
          s.selectedCuts.length +
          s.selectedPolish.length +
          s.selectedSymmetry.length +
          s.selectedLabs.length,
      DiamondFinderSection.inclusions:
          flag(s.noBgm) +
          flag(s.eyeClean) +
          flag(s.heartAndArrow) +
          s.selectedMilkyGrades.length +
          s.selectedFluorescence.length +
          flag(s.selectedFluorescenceColor != null) +
          flag(s.selectedEnhancement != null),
      DiamondFinderSection.listing:
          flag(s.searchByMedia) +
          flag(s.makeAnOffer) +
          flag(s.separable) +
          flag(s.selectedAvailability != d.selectedAvailability) +
          s.selectedGrowthMethods.length,
      DiamondFinderSection.seller:
          s.vendorLocations.length +
          s.companyNames.length +
          flag(s.selectedOrigin != null) +
          flag(s.selectedRoughSource != null) +
          flag(s.minSellerRating != d.minSellerRating),
      DiamondFinderSection.measurements:
          range(s.minLength, s.maxLength, d.minLength, d.maxLength) +
          range(s.minWidth, s.maxWidth, d.minWidth, d.maxWidth) +
          range(s.minHeight, s.maxHeight, d.minHeight, d.maxHeight) +
          range(s.minRatio, s.maxRatio, d.minRatio, d.maxRatio),
      DiamondFinderSection.proportions:
          range(s.minTable, s.maxTable, d.minTable, d.maxTable) +
          range(s.minDepth, s.maxDepth, d.minDepth, d.maxDepth) +
          range(
            s.minCrownAngle,
            s.maxCrownAngle,
            d.minCrownAngle,
            d.maxCrownAngle,
          ) +
          range(
            s.minCrownHeight,
            s.maxCrownHeight,
            d.minCrownHeight,
            d.maxCrownHeight,
          ) +
          range(
            s.minPavilionAngle,
            s.maxPavilionAngle,
            d.minPavilionAngle,
            d.maxPavilionAngle,
          ) +
          range(
            s.minPavilionDepth,
            s.maxPavilionDepth,
            d.minPavilionDepth,
            d.maxPavilionDepth,
          ) +
          s.selectedGirdles.length +
          s.selectedCulets.length,
    };
    return DiamondFilterSummary._(counts);
  }

  final Map<DiamondFinderSection, int> _counts;

  int count(DiamondFinderSection section) => _counts[section] ?? 0;

  int get total => _counts.values.fold(0, (a, b) => a + b);

  @override
  bool operator ==(Object other) =>
      other is DiamondFilterSummary &&
      DiamondFinderSection.values.every((s) => other.count(s) == count(s));

  @override
  int get hashCode => Object.hashAll(DiamondFinderSection.values.map(count));
}
