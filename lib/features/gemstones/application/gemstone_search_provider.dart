import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/gemstone_filter_state.dart';

/// Notifier responsible for managing the gemstone search query and filter settings.
class GemstoneSearchNotifier extends Notifier<GemstoneFilterState> {
  @override
  GemstoneFilterState build() {
    return const GemstoneFilterState();
  }

  List<String> _toggled(List<String> source, String value) {
    final current = List<String>.from(source);
    if (current.contains(value)) {
      current.remove(value);
    } else {
      current.add(value);
    }
    return List<String>.unmodifiable(current);
  }

  void updateStoneType(String? value) {
    final next = state.stoneType == value ? null : value;
    final isLab = (next ?? '').toLowerCase().contains('lab');
    if (isLab) {
      state = state.copyWith(
        stoneType: next,
        selectedOrigin: null,
        selectedOriginCountry: null,
      );
    } else {
      state = state.copyWith(stoneType: next);
    }
  }

  void updateLotType(String? value) {
    final next = state.lotType == value ? null : value;
    var colors = state.selectedColors;
    if (next == 'Melee' && colors.contains('Multi')) {
      colors = List<String>.unmodifiable([
        for (final c in colors) if (c != 'Multi') c,
        if (!colors.contains('Other')) 'Other',
      ]);
    }
    state = state.copyWith(lotType: next, selectedColors: colors);
  }

  void toggleGemstoneType(String type) {
    state = state.copyWith(
      selectedGemstoneTypes: _toggled(state.selectedGemstoneTypes, type),
    );
  }

  void toggleBirthstoneMonth(String month) {
    final stone = GemstoneFilterState.birthstones[month]?.trim();
    final months = _toggled(state.selectedBirthstoneMonths, month);
    final selecting = months.contains(month);

    var types = List<String>.from(state.selectedGemstoneTypes);
    var shapes = List<String>.from(state.selectedShapes);

    if (stone != null && stone.isNotEmpty) {
      final stillNeeded = months.any(
        (m) => GemstoneFilterState.birthstones[m] == stone,
      );
      if (selecting) {
        if (!types.contains(stone)) types.add(stone);
        if (GemstoneFilterState.shapeSvgNames.containsKey(stone) &&
            !shapes.contains(stone)) {
          shapes.add(stone);
        }
      } else if (!stillNeeded) {
        types.remove(stone);
        if (GemstoneFilterState.shapeSvgNames.containsKey(stone)) {
          shapes.remove(stone);
        }
      }
    }

    state = state.copyWith(
      selectedBirthstoneMonths: months,
      selectedGemstoneTypes: List<String>.unmodifiable(types),
      selectedShapes: List<String>.unmodifiable(shapes),
    );
  }

  void toggleShape(String shape) {
    state = state.copyWith(
      selectedShapes: _toggled(state.selectedShapes, shape),
    );
  }

  void updateTotalCaratRange(double min, double max) {
    state = state.copyWith(
      minTotalCarat: min,
      maxTotalCarat: max,
      selectedCaratQuickRanges: const [],
    );
  }

  /// Range-selects quick carat chips exactly like the diamond filter screen.
  void toggleCaratQuickRange(int index) {
    final current = List<int>.from(state.selectedCaratQuickRanges);
    if (current.isEmpty) {
      current.add(index);
    } else if (current.contains(index) && current.length == 1) {
      current.remove(index);
    } else {
      final first = current.first;
      final minIdx = first < index ? first : index;
      final maxIdx = first > index ? first : index;
      current.clear();
      for (int i = minIdx; i <= maxIdx; i++) {
        current.add(i);
      }
    }

    double minC = state.minTotalCarat;
    double maxC = state.maxTotalCarat;

    if (current.isNotEmpty) {
      current.sort();
      minC = GemstoneFilterState.caratQuickRanges[current.first]['min']!;
      maxC = GemstoneFilterState.caratQuickRanges[current.last]['max']!;
    } else {
      minC = GemstoneFilterState.caratMin;
      maxC = GemstoneFilterState.caratMax;
    }

    state = state.copyWith(
      selectedCaratQuickRanges: List<int>.unmodifiable(current),
      minTotalCarat: minC,
      maxTotalCarat: maxC,
    );
  }

  void updateCaratPerPieceRange(double min, double max) {
    state = state.copyWith(minCaratPerPiece: min, maxCaratPerPiece: max);
  }

  void updatePricePerPieceRange(double min, double max) {
    state = state.copyWith(minPricePerPiece: min, maxPricePerPiece: max);
  }

  void updatePricePerCaratRange(double min, double max) {
    state = state.copyWith(minPricePerCarat: min, maxPricePerCarat: max);
  }

  void updateTotalPcsRange(double min, double max) {
    state = state.copyWith(minTotalPcs: min, maxTotalPcs: max);
  }

  void updateTotalPriceRange(double min, double max) {
    state = state.copyWith(minTotalPrice: min, maxTotalPrice: max);
  }

  void toggleColor(String color) {
    state = state.copyWith(
      selectedColors: _toggled(state.selectedColors, color),
    );
  }

  void toggleIntensity(String intensity) {
    state = state.copyWith(
      selectedIntensities: _toggled(state.selectedIntensities, intensity),
    );
  }

  void toggleModifier(String modifier) {
    state = state.copyWith(
      selectedModifiers: _toggled(state.selectedModifiers, modifier),
    );
  }

  void toggleFluorescence(String grade) {
    state = state.copyWith(
      selectedFluorescence: _toggled(state.selectedFluorescence, grade),
    );
  }

  void updateFluorescenceColor(String? color) {
    state = state.copyWith(
      selectedFluorescenceColor:
          state.selectedFluorescenceColor == color ? null : color,
    );
  }

  void toggleClarity(String clarity) {
    state = state.copyWith(
      selectedClarities: _toggled(state.selectedClarities, clarity),
    );
  }

  void updateQualityGrade(String? grade) {
    state = state.copyWith(
      selectedQualityGrade: state.selectedQualityGrade == grade ? null : grade,
    );
  }

  void toggleSeparable() {
    state = state.copyWith(separable: !state.separable);
  }

  void toggleSearchByMedia() {
    state = state.copyWith(searchByMedia: !state.searchByMedia);
  }

  void updateAvailability(String? value) {
    final next = (value == null || value.trim().isEmpty) ? 'All' : value.trim();
    state = state.copyWith(selectedAvailability: next);
  }

  void toggleMakeAnOffer() {
    state = state.copyWith(makeAnOffer: !state.makeAnOffer);
  }

  void toggleTreatment(String treatment) {
    state = state.copyWith(
      selectedTreatments: _toggled(state.selectedTreatments, treatment),
    );
  }

  void toggleCertification(String cert) {
    state = state.copyWith(
      selectedCertifications: _toggled(state.selectedCertifications, cert),
    );
  }

  void updateOrigin(String? origin) {
    state = state.copyWith(selectedOrigin: origin);
  }

  void toggleCutGrade(String grade) {
    state = state.copyWith(
      selectedCutGrades: _toggled(state.selectedCutGrades, grade),
    );
  }

  void addVendorLocation(String location) {
    final loc = location.trim();
    if (loc.isEmpty) return;
    final exists = state.vendorLocations.any(
      (item) => item.toLowerCase() == loc.toLowerCase(),
    );
    if (exists) return;
    state = state.copyWith(
      vendorLocations: List<String>.unmodifiable([...state.vendorLocations, loc]),
    );
  }

  void removeVendorLocation(String location) {
    state = state.copyWith(
      vendorLocations: List<String>.unmodifiable(
        state.vendorLocations.where((item) => item != location),
      ),
    );
  }

  void addCompanyName(String name) {
    final value = name.trim();
    if (value.isEmpty) return;
    final exists = state.companyNames.any(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );
    if (exists) return;
    state = state.copyWith(
      companyNames: List<String>.unmodifiable([...state.companyNames, value]),
    );
  }

  void removeCompanyName(String name) {
    state = state.copyWith(
      companyNames: List<String>.unmodifiable(
        state.companyNames.where((item) => item != name),
      ),
    );
  }

  void updateOriginCountry(String? country) {
    state = state.copyWith(selectedOriginCountry: country);
  }

  void updateLengthRange(double min, double max) {
    state = state.copyWith(minLength: min, maxLength: max);
  }

  void updateWidthRange(double min, double max) {
    state = state.copyWith(minWidth: min, maxWidth: max);
  }

  void updateHeightRange(double min, double max) {
    state = state.copyWith(minHeight: min, maxHeight: max);
  }

  void updateRatioRange(double min, double max) {
    state = state.copyWith(minRatio: min, maxRatio: max);
  }

  void reset() {
    state = const GemstoneFilterState(
      stoneType: 'Natural',
      lotType: 'Single',
    );
  }

  /// Replaces the full filter snapshot (e.g. Gem AI “See more”).
  void replaceFilters(GemstoneFilterState filters) {
    state = filters;
  }
}

/// Global provider for accessing and modifying the gemstone search criteria state.
final gemstoneSearchProvider =
    NotifierProvider<GemstoneSearchNotifier, GemstoneFilterState>(
  GemstoneSearchNotifier.new,
);

/// Derived provider that estimates matching gemstone count from filter state.
final matchingGemstoneCountProvider = Provider<int>((ref) {
  final state = ref.watch(gemstoneSearchProvider);
  double multiplier = 1.0;

  if (state.stoneType != null) multiplier *= 0.55;
  if (state.lotType != null) multiplier *= 0.60;

  if (state.selectedGemstoneTypes.isNotEmpty) {
    multiplier *= (state.selectedGemstoneTypes.length * 0.08).clamp(0.08, 1.0);
  }
  if (state.selectedBirthstoneMonths.isNotEmpty) {
    multiplier *=
        (state.selectedBirthstoneMonths.length / 12.0).clamp(0.10, 1.0);
  }
  if (state.selectedShapes.isNotEmpty) {
    multiplier *= (state.selectedShapes.length * 0.12).clamp(0.12, 1.0);
  }

  final caratSpan = state.maxTotalCarat - state.minTotalCarat;
  multiplier *= (caratSpan / GemstoneFilterState.caratMax).clamp(0.02, 1.0);

  final priceSpan = state.maxTotalPrice - state.minTotalPrice;
  multiplier *=
      (priceSpan / GemstoneFilterState.totalPriceMax).clamp(0.02, 1.0);

  if (state.selectedColors.isNotEmpty) {
    multiplier *= (state.selectedColors.length / 11.0).clamp(0.10, 1.0);
  }
  if (state.selectedIntensities.isNotEmpty) {
    multiplier *= (state.selectedIntensities.length / 4.0).clamp(0.25, 1.0);
  }
  if (state.selectedModifiers.isNotEmpty) {
    multiplier *= (state.selectedModifiers.length / 4.0).clamp(0.25, 1.0);
  }
  if (state.selectedFluorescence.isNotEmpty) {
    multiplier *= (state.selectedFluorescence.length / 5.0).clamp(0.25, 1.0);
  }
  if (state.selectedFluorescenceColor != null &&
      state.selectedFluorescenceColor != 'None') {
    multiplier *= 0.85;
  }
  if (state.selectedClarities.isNotEmpty) {
    multiplier *= (state.selectedClarities.length / 4.0).clamp(0.25, 1.0);
  }
  if (state.selectedQualityGrade != null) multiplier *= 0.45;
  if (state.separable) multiplier *= 0.30;
  if (state.selectedTreatments.isNotEmpty) {
    multiplier *= (state.selectedTreatments.length / 15.0).clamp(0.10, 1.0);
  }
  if (state.selectedCertifications.isNotEmpty) {
    multiplier *= (state.selectedCertifications.length / 8.0).clamp(0.20, 1.0);
  }
  if (state.selectedOrigin != null) multiplier *= 0.60;
  if (state.selectedCutGrades.isNotEmpty) {
    multiplier *= (state.selectedCutGrades.length / 5.0).clamp(0.25, 1.0);
  }
  if (state.searchByMedia) multiplier *= 0.60;
    if (state.vendorLocations.isNotEmpty) multiplier *= 0.70;
    if (state.companyNames.isNotEmpty) multiplier *= 0.75;
  if (state.selectedOriginCountry != null) multiplier *= 0.65;

  return (86300 * multiplier).round().clamp(0, 86300);
});
