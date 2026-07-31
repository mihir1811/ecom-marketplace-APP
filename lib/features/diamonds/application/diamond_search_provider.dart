import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/diamond_catalog_type.dart';
import '../domain/models/diamond_filter_state.dart';
import '../domain/models/sieve_size.dart';

/// Notifier responsible for managing the diamond search query and filter settings.
class DiamondSearchNotifier extends Notifier<DiamondFilterState> {
  @override
  DiamondFilterState build() {
    return const DiamondFilterState();
  }

  void updateOrigin(LabNaturalType value) {
    state = state.copyWith(
      labNatural: value,
      selectedFancyColors: _remapFancyColorsForMelee(
        state.selectedFancyColors,
        useMelee: value.usesMeleeFilters,
      ),
    );
  }

  void updateLabCategory(String category) {
    state = state.copyWith(
      labCategory: category,
      selectedFancyColors: _remapFancyColorsForMelee(
        state.selectedFancyColors,
        useMelee: category == 'Lab Melee',
      ),
    );
  }

  List<String> _remapFancyColorsForMelee(
    List<String> colors, {
    required bool useMelee,
  }) {
    final next = <String>{};
    if (useMelee) {
      for (final c in colors) {
        next.add(c == 'Multi' ? 'Other' : c);
      }
    } else {
      for (final c in colors) {
        next.add(c == 'Other' ? 'Multi' : c);
      }
    }
    return List<String>.unmodifiable(next);
  }

  void toggleGrowthMethod(String method) {
    final current = List<String>.from(state.selectedGrowthMethods);
    if (current.contains(method)) {
      current.remove(method);
    } else {
      current.add(method);
    }
    state = state.copyWith(
      selectedGrowthMethods: List<String>.unmodifiable(current),
    );
  }

  void toggleShape(String shape) {
    final current = List<String>.from(state.shapes);
    if (current.contains(shape)) {
      current.remove(shape);
    } else {
      current.add(shape);
    }
    state = state.copyWith(shapes: List<String>.unmodifiable(current));
  }

  void toggleCut(String cut) {
    final current = List<String>.from(state.selectedCuts);
    if (current.contains(cut)) {
      current.remove(cut);
    } else {
      current.add(cut);
    }
    state = state.copyWith(
      selectedCuts: List<String>.unmodifiable(current),
      selectedFinishPreset: const [],
    );
  }

  void togglePolish(String polish) {
    final current = List<String>.from(state.selectedPolish);
    if (current.contains(polish)) {
      current.remove(polish);
    } else {
      current.add(polish);
    }
    state = state.copyWith(
      selectedPolish: List<String>.unmodifiable(current),
      selectedFinishPreset: const [],
    );
  }

  void toggleSymmetry(String symmetry) {
    final current = List<String>.from(state.selectedSymmetry);
    if (current.contains(symmetry)) {
      current.remove(symmetry);
    } else {
      current.add(symmetry);
    }
    state = state.copyWith(
      selectedSymmetry: List<String>.unmodifiable(current),
      selectedFinishPreset: const [],
    );
  }

  void toggleFluorescence(String fluorescence) {
    final current = List<String>.from(state.selectedFluorescence);
    if (current.contains(fluorescence)) {
      current.remove(fluorescence);
    } else {
      current.add(fluorescence);
    }
    state = state.copyWith(selectedFluorescence: List<String>.unmodifiable(current));
  }

  void updateFluorescenceColor(String? color) {
    state = state.copyWith(selectedFluorescenceColor: color);
  }

  void toggleMilkyGrade(String grade) {
    final current = List<String>.from(state.selectedMilkyGrades);
    if (current.contains(grade)) {
      current.remove(grade);
    } else {
      current.add(grade);
    }
    state = state.copyWith(selectedMilkyGrades: List<String>.unmodifiable(current));
  }

  void updateEnhancement(String? value) {
    state = state.copyWith(selectedEnhancement: value);
  }

  void updateRoughSource(String? value) {
    state = state.copyWith(selectedRoughSource: value);
  }

  void updateCompanyNameSearch(String? value) {
    state = state.copyWith(companyNameSearch: value);
  }

  void updateVendorLocationSearch(String? value) {
    state = state.copyWith(vendorLocationSearch: value);
  }

  void toggleLab(String lab) {
    final current = List<String>.from(state.selectedLabs);
    if (current.contains(lab)) {
      current.remove(lab);
    } else {
      current.add(lab);
    }
    state = state.copyWith(selectedLabs: List<String>.unmodifiable(current));
  }

  void updatePriceRange(double min, double max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
  }

  void updatePricePerCaratRange(double min, double max) {
    state = state.copyWith(minPricePerCarat: min, maxPricePerCarat: max);
  }

  void updateCaratRange(double min, double max) {
    state = state.copyWith(
      minCarat: min,
      maxCarat: max,
      selectedCaratQuickRanges: const [],
    );
  }

  void updateCaratPerPcsRange(double min, double max) {
    state = state.copyWith(minCaratPerPcs: min, maxCaratPerPcs: max);
  }

  void updatePricePerPcsRange(double min, double max) {
    state = state.copyWith(minPricePerPcs: min, maxPricePerPcs: max);
  }

  void updateTotalPcsRange(double min, double max) {
    state = state.copyWith(minTotalPcs: min, maxTotalPcs: max);
  }

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

    double minC = state.minCarat;
    double maxC = state.maxCarat;

    if (current.isNotEmpty) {
      current.sort();
      minC = DiamondFilterState.caratQuickRanges[current.first]['min']!;
      maxC = DiamondFilterState.caratQuickRanges[current.last]['max']!;
    } else {
      minC = 0.0;
      maxC = 100.00;
    }

    state = state.copyWith(
      selectedCaratQuickRanges: List<int>.unmodifiable(current),
      minCarat: minC,
      maxCarat: maxC,
    );
  }

  void updateColorRange(int min, int max) {
    state = state.copyWith(minColorIndex: min, maxColorIndex: max);
  }

  void updateColorMode(bool isFancy) {
    state = state.copyWith(isFancyColor: isFancy);
  }

  void toggleStandardColor(String color) {
    final allColors = DiamondFilterState.colors;
    final current = List<String>.from(state.selectedStandardColors);
    final targetIndex = allColors.indexOf(color);

    if (current.isEmpty) {
      current.add(color);
    } else if (current.contains(color) && current.length == 1) {
      current.remove(color);
    } else {
      final firstColor = current.first;
      final firstIndex = allColors.indexOf(firstColor);

      final minIdx = firstIndex < targetIndex ? firstIndex : targetIndex;
      final maxIdx = firstIndex > targetIndex ? firstIndex : targetIndex;

      current.clear();
      for (int i = minIdx; i <= maxIdx; i++) {
        current.add(allColors[i]);
      }
    }
    state = state.copyWith(selectedStandardColors: List<String>.unmodifiable(current));
  }

  void selectAllStandardColors() {
    state = state.copyWith(
      selectedStandardColors: List<String>.unmodifiable(DiamondFilterState.colors),
    );
  }

  void clearStandardColors() {
    state = state.copyWith(selectedStandardColors: const []);
  }

  void toggleFancyColor(String color) {
    final current = List<String>.from(state.selectedFancyColors);
    if (current.contains(color)) {
      current.remove(color);
    } else {
      current.add(color);
    }
    state = state.copyWith(selectedFancyColors: List<String>.unmodifiable(current));
  }

  void toggleOvertone(String overtone) {
    final current = List<String>.from(state.selectedOvertones);
    if (current.contains(overtone)) {
      current.remove(overtone);
    } else {
      current.add(overtone);
    }
    state = state.copyWith(selectedOvertones: List<String>.unmodifiable(current));
  }

  void toggleIntensity(String intensity) {
    final current = List<String>.from(state.selectedIntensities);
    if (current.contains(intensity)) {
      current.remove(intensity);
    } else {
      current.add(intensity);
    }
    state = state.copyWith(selectedIntensities: List<String>.unmodifiable(current));
  }

  void toggleNoBgm() {
    state = state.copyWith(noBgm: !state.noBgm);
  }

  void toggleEyeClean() {
    state = state.copyWith(eyeClean: !state.eyeClean);
  }

  void updateClarityRange(int min, int max) {
    state = state.copyWith(minClarityIndex: min, maxClarityIndex: max);
  }

  void toggleClarityGradeGroup(String grade) {
    final allClarities = DiamondFilterState.clarities;
    final current = List<String>.from(state.selectedClarityGrades);
    final targetIndex = allClarities.indexOf(grade);

    if (current.isEmpty) {
      current.add(grade);
    } else if (current.contains(grade) && current.length == 1) {
      current.remove(grade);
    } else {
      final firstIndex = allClarities.indexOf(current.first);
      final minIdx = firstIndex < targetIndex ? firstIndex : targetIndex;
      final maxIdx = firstIndex > targetIndex ? firstIndex : targetIndex;
      current.clear();
      for (int i = minIdx; i <= maxIdx; i++) {
        current.add(allClarities[i]);
      }
    }
    state = state.copyWith(selectedClarityGrades: List<String>.unmodifiable(current));
  }

  void removeClarityGrade(String grade) {
    final current = List<String>.from(state.selectedClarityGrades);
    current.remove(grade);
    state = state.copyWith(selectedClarityGrades: List<String>.unmodifiable(current));
  }

  void selectAllClarityGrades() {
    state = state.copyWith(
      selectedClarityGrades: List<String>.unmodifiable(DiamondFilterState.clarities),
    );
  }

  void clearClarityGrades() {
    state = state.copyWith(selectedClarityGrades: const []);
  }

  void selectFinishPreset(String preset) {
    final current = List<String>.from(state.selectedFinishPreset);
    if (current.contains(preset)) {
      current.remove(preset);
    } else {
      current.add(preset);
    }

    List<String> cuts = [];
    List<String> polish = [];
    List<String> symmetry = [];

    for (final p in current) {
      if (p == '3X') {
        cuts.addAll(['Ideal', 'Excellent']);
        polish.addAll(['Ideal', 'Excellent']);
        symmetry.addAll(['Ideal', 'Excellent']);
      } else if (p == 'EX-') {
        cuts.addAll(['Ideal', 'Excellent', 'Very Good']);
        polish.addAll(['Ideal', 'Excellent', 'Very Good']);
        symmetry.addAll(['Ideal', 'Excellent', 'Very Good']);
      } else if (p == 'VG+') {
        cuts.addAll(['Ideal', 'Excellent', 'Very Good']);
        polish.addAll(['Ideal', 'Excellent', 'Very Good']);
        symmetry.addAll(['Ideal', 'Excellent', 'Very Good']);
      } else if (p == 'VG-') {
        cuts.addAll(['Very Good', 'Good']);
        polish.addAll(['Very Good', 'Good']);
        symmetry.addAll(['Very Good', 'Good']);
      }
    }

    state = state.copyWith(
      selectedFinishPreset: List<String>.unmodifiable(current),
      selectedCuts: cuts.toSet().toList(),
      selectedPolish: polish.toSet().toList(),
      selectedSymmetry: symmetry.toSet().toList(),
    );
  }

  void toggleHeartAndArrow() {
    state = state.copyWith(heartAndArrow: !state.heartAndArrow);
  }

  void toggleThreeEx() {
    state = state.copyWith(threeEx: !state.threeEx);
  }

  void toggleSellersWithVideo() {
    state = state.copyWith(sellersWithVideo: !state.sellersWithVideo);
  }

  void toggleSellersWithImages() {
    state = state.copyWith(sellersWithImages: !state.sellersWithImages);
  }

  void toggleSearchByMedia() {
    state = state.copyWith(searchByMedia: !state.searchByMedia);
  }

  void toggleSeparable() {
    state = state.copyWith(separable: !state.separable);
  }

  void updateSellerRating(double rating) {
    state = state.copyWith(minSellerRating: rating);
  }

  void toggleAdditionalFilters() {
    state = state.copyWith(showAdditionalFilters: !state.showAdditionalFilters);
  }

  // Upgraded ranges
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

  void updateTableRange(double min, double max) {
    state = state.copyWith(minTable: min, maxTable: max);
  }

  void updateDepthRange(double min, double max) {
    state = state.copyWith(minDepth: min, maxDepth: max);
  }

  void updateCrownAngleRange(double min, double max) {
    state = state.copyWith(minCrownAngle: min, maxCrownAngle: max);
  }

  void updateCrownHeightRange(double min, double max) {
    state = state.copyWith(minCrownHeight: min, maxCrownHeight: max);
  }

  void updatePavilionAngleRange(double min, double max) {
    state = state.copyWith(minPavilionAngle: min, maxPavilionAngle: max);
  }

  void updatePavilionDepthRange(double min, double max) {
    state = state.copyWith(minPavilionDepth: min, maxPavilionDepth: max);
  }

  void toggleGirdle(String girdle) {
    final current = List<String>.from(state.selectedGirdles);
    if (current.contains(girdle)) {
      current.remove(girdle);
    } else {
      current.add(girdle);
    }
    state = state.copyWith(selectedGirdles: List<String>.unmodifiable(current));
  }

  void clearGirdles() {
    state = state.copyWith(selectedGirdles: const []);
  }

  void toggleCulet(String culet) {
    final current = List<String>.from(state.selectedCulets);
    if (current.contains(culet)) {
      current.remove(culet);
    } else {
      current.add(culet);
    }
    state = state.copyWith(selectedCulets: List<String>.unmodifiable(current));
  }

  void clearCulets() {
    state = state.copyWith(selectedCulets: const []);
  }

  void updateOriginCountry(String? country) {
    state = state.copyWith(selectedOrigin: country);
  }

  List<String> _computePresetsFromSelection(Set<int> selected) {
    final active = <String>[];
    for (final entry in SieveSize.lotTypePresets.entries) {
      final rangeIndices = SieveSize.indicesInRange(entry.value[0], entry.value[1]);
      if (rangeIndices.isNotEmpty && rangeIndices.every((i) => selected.contains(i))) {
        active.add(entry.key);
      }
    }
    return active;
  }

  void toggleSieveSize(int index) {
    final allSieves = SieveSize.defaultSieves;
    final current = List<int>.from(state.selectedSieveIndices);

    if (current.isEmpty) {
      current.add(index);
    } else if (current.contains(index) && current.length == 1) {
      current.remove(index);
    } else {
      final firstIndex = current.first;
      final minIndex = firstIndex < index ? firstIndex : index;
      final maxIndex = firstIndex > index ? firstIndex : index;

      current
        ..clear()
        ..addAll(
          allSieves
              .where(
                (sieve) => sieve.index >= minIndex && sieve.index <= maxIndex,
              )
              .map((sieve) => sieve.index),
        );
    }

    current.sort();
    final activePresets = _computePresetsFromSelection(current.toSet());
    state = state.copyWith(
      selectedSieveIndices: List<int>.unmodifiable(current),
      activeSievePresets: List<String>.unmodifiable(activePresets),
    );
  }

  void selectSieveRange(int start, int end) {
    final min = start < end ? start : end;
    final max = start > end ? start : end;
    final current = List<int>.from(state.selectedSieveIndices);
    final rangeIndices = <int>[];
    for (int i = min; i <= max; i++) {
      rangeIndices.add(i);
    }
    final allPresent = rangeIndices.every((i) => current.contains(i));

    if (allPresent && rangeIndices.isNotEmpty) {
      for (final i in rangeIndices) {
        current.remove(i);
      }
    } else {
      for (final i in rangeIndices) {
        if (!current.contains(i)) {
          current.add(i);
        }
      }
    }
    current.sort();
    final activePresets = _computePresetsFromSelection(current.toSet());
    state = state.copyWith(
      selectedSieveIndices: List<int>.unmodifiable(current),
      activeSievePresets: List<String>.unmodifiable(activePresets),
    );
  }

  void toggleSelectAllSieves() {
    final allIndices = List.generate(SieveSize.defaultSieves.length, (i) => i);
    final current = List<int>.from(state.selectedSieveIndices);
    final allSelected = allIndices.every((i) => current.contains(i));
    if (allSelected) {
      state = state.copyWith(
        selectedSieveIndices: const [],
        activeSievePresets: const [],
      );
    } else {
      final activePresets = _computePresetsFromSelection(allIndices.toSet());
      state = state.copyWith(
        selectedSieveIndices: List<int>.unmodifiable(allIndices),
        activeSievePresets: List<String>.unmodifiable(activePresets),
      );
    }
  }

  void applySievePreset(String preset) {
    final range = SieveSize.lotTypePresets[preset];
    if (range == null) return;
    final indices = SieveSize.indicesInRange(range[0], range[1]);
    final current = List<int>.from(state.selectedSieveIndices);
    final presetSet = indices.toSet();
    final allPresent = presetSet.every((i) => current.contains(i));

    if (allPresent && presetSet.isNotEmpty) {
      for (final i in indices) {
        current.remove(i);
      }
    } else {
      for (final i in indices) {
        if (!current.contains(i)) {
          current.add(i);
        }
      }
    }
    current.sort();
    final activePresets = _computePresetsFromSelection(current.toSet());
    state = state.copyWith(
      selectedSieveIndices: List<int>.unmodifiable(current),
      activeSievePresets: List<String>.unmodifiable(activePresets),
    );
  }

  void removeSieveSize(int index) {
    final current = List<int>.from(state.selectedSieveIndices);
    current.remove(index);
    final activePresets = _computePresetsFromSelection(current.toSet());
    state = state.copyWith(
      selectedSieveIndices: List<int>.unmodifiable(current),
      activeSievePresets: List<String>.unmodifiable(activePresets),
    );
  }

  void clearSieves() {
    state = state.copyWith(
      selectedSieveIndices: const [],
      activeSievePresets: const [],
    );
  }

  void reset() {
    state = const DiamondFilterState();
  }

  void clearCuts() {
    state = state.copyWith(selectedCuts: const [], selectedFinishPreset: []);
  }

  void clearPolish() {
    state = state.copyWith(selectedPolish: const [], selectedFinishPreset: []);
  }

  void clearSymmetry() {
    state = state.copyWith(selectedSymmetry: const [], selectedFinishPreset: []);
  }

  void clearFluorescence() {
    state = state.copyWith(selectedFluorescence: const []);
  }

  void clearMilkyGrades() {
    state = state.copyWith(selectedMilkyGrades: const []);
  }

  void clearLabs() {
    state = state.copyWith(selectedLabs: const []);
  }
}

/// Global provider for accessing and modifying the diamond search criteria state.
final diamondSearchProvider = NotifierProvider<DiamondSearchNotifier, DiamondFilterState>(
  DiamondSearchNotifier.new,
);

/// Derived provider that calculates matching diamond count from filter state.
/// Must be overridden (with [computeMatchingCount]) in any scope that
/// overrides [diamondSearchProvider], e.g. the lab-grown shell.
final matchingCountProvider = Provider<int>(computeMatchingCount);

int computeMatchingCount(ProviderRef<int> ref) {
  final state = ref.watch(diamondSearchProvider);
  final catalog = ref.watch(diamondCatalogTypeProvider);
  final baseCount = catalog.isLabGrown ? 86420 : 120450;
  double multiplier = 1.0;

  if (catalog.isLabGrown) {
    multiplier *= 0.78;
  } else if (state.labNatural == LabNaturalType.natural) {
    multiplier *= 0.65;
  } else if (state.labNatural.usesMeleeFilters) {
    multiplier *= 0.35;
  }

  if (state.shapes.isNotEmpty) {
    multiplier *= (state.shapes.length * 0.12).clamp(0.12, 1.0);
  }

  final priceSpan = state.maxPrice - state.minPrice;
  multiplier *= (priceSpan / 1000000.0).clamp(0.02, 1.0);

  final caratSpan = state.maxCarat - state.minCarat;
  multiplier *= (caratSpan / 99.84).clamp(0.02, 1.0);

  if (!state.isFancyColor && state.selectedStandardColors.isNotEmpty) {
    multiplier *= (state.selectedStandardColors.length / 23.0).clamp(0.05, 1.0);
  } else if (state.isFancyColor) {
    if (state.selectedFancyColors.isNotEmpty) {
      multiplier *= (state.selectedFancyColors.length / 13.0).clamp(0.15, 1.0);
    }
    if (state.selectedOvertones.isNotEmpty) {
      multiplier *= (state.selectedOvertones.length / 26.0).clamp(0.15, 1.0);
    }
    if (state.selectedIntensities.isNotEmpty) {
      multiplier *= (state.selectedIntensities.length / 9.0).clamp(0.2, 1.0);
    }
  }

  if (state.selectedClarityGrades.isNotEmpty) {
    multiplier *= (state.selectedClarityGrades.length / 12.0).clamp(0.08, 1.0);
    } else {
      final claritySpan = (state.maxClarityIndex - state.minClarityIndex).toDouble() + 1;
      multiplier *= (claritySpan / 12.0).clamp(0.09, 1.0);
  }

  if (state.selectedCuts.isNotEmpty) {
    multiplier *= (state.selectedCuts.length / 6.0).clamp(0.15, 1.0);
  }
  if (state.selectedPolish.isNotEmpty) {
    multiplier *= (state.selectedPolish.length / 6.0).clamp(0.2, 1.0);
  }
  if (state.selectedSymmetry.isNotEmpty) {
    multiplier *= (state.selectedSymmetry.length / 6.0).clamp(0.2, 1.0);
  }

  if (state.selectedFluorescence.isNotEmpty) {
    multiplier *= (state.selectedFluorescence.length / 5.0).clamp(0.25, 1.0);
  }
  if (state.selectedFluorescenceColor != null && state.selectedFluorescenceColor != 'None') {
    multiplier *= 0.85;
  }
  if (state.selectedMilkyGrades.isNotEmpty) {
    multiplier *= (0.9 - (state.selectedMilkyGrades.length * 0.15)).clamp(0.1, 1.0);
  }
  if (state.selectedEnhancement != null && !state.selectedEnhancement!.startsWith('None')) {
    multiplier *= 0.40;
  }
  if (state.selectedRoughSource != null) {
    multiplier *= 0.75;
  }
  if (state.companyNameSearch != null && state.companyNameSearch!.trim().isNotEmpty) {
    multiplier *= 0.50;
  }
  if (state.vendorLocationSearch != null && state.vendorLocationSearch!.trim().isNotEmpty) {
    multiplier *= 0.60;
  }
  if (state.selectedOrigin != null) {
    multiplier *= 0.90;
  }

  if (state.selectedGirdles.isNotEmpty) {
    multiplier *= (state.selectedGirdles.length / 9.0).clamp(0.25, 1.0);
  }
  if (state.selectedCulets.isNotEmpty) {
    multiplier *= (state.selectedCulets.length / 8.0).clamp(0.20, 1.0);
  }

  if (state.heartAndArrow) multiplier *= 0.45;
  if (state.threeEx) multiplier *= 0.35;
  if (state.sellersWithVideo) multiplier *= 0.60;
  if (state.searchByMedia) multiplier *= 0.60;
  if (state.noBgm) multiplier *= 0.70;
  if (state.eyeClean) multiplier *= 0.80;

  if (state.minSellerRating > 0.0) {
    multiplier *= (1.0 - (state.minSellerRating * 0.15)).clamp(0.4, 1.0);
  }

  return (baseCount * multiplier).round().clamp(0, baseCount);
}
