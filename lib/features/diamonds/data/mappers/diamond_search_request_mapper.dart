import '../../domain/models/diamond_catalog_type.dart';
import '../../domain/models/diamond_filter_state.dart';
import '../../domain/models/sieve_size.dart';
import '../../domain/models/sorting_criteria.dart';

/// Builds `POST /diamond/search` bodies from UI filter + catalog scope.
abstract final class DiamondSearchRequestMapper {
  static const _defaultMinPrice = 0.0;
  static const _defaultMaxPrice = 1000000.0;
  static const _defaultMinPpc = 0.0;
  static const _defaultMaxPpc = 200000.0;
  static const _defaultMinCarat = 0.16;
  static const _defaultMaxCarat = 100.0;
  static const _defaultMinRatio = 0.5;
  static const _defaultMaxRatio = 5.0;
  static const _defaultMinTable = 0.0;
  static const _defaultMaxTable = 100.0;
  static const _defaultMinDepth = 0.0;
  static const _defaultMaxDepth = 100.0;
  static const _defaultMinLength = 0.0;
  static const _defaultMaxLength = 100.0;
  static const _defaultMinWidth = 0.0;
  static const _defaultMaxWidth = 100.0;
  static const _defaultMinHeight = 0.0;
  static const _defaultMaxHeight = 100.0;
  static const _defaultMinCaratPerPcs = 0.16;
  static const _defaultMaxCaratPerPcs = 100.0;
  static const _defaultMinPricePerPcs = 0.0;
  static const _defaultMaxPricePerPcs = 200000.0;
  static const _defaultMinTotalPcs = 1.0;
  static const _defaultMaxTotalPcs = 1000000.0;

  static Map<String, dynamic> toBody({
    required DiamondFilterState filters,
    required DiamondCatalogType catalog,
    required int page,
    int pageSize = 24,
    List<SortingCriteria> sorting = const [],
  }) {
    final isLab = catalog.isLabGrown;
    final isMelee = isLab
        ? filters.labCategory == 'Lab Melee'
        : filters.labNatural.usesMeleeFilters;

    final body = <String, dynamic>{
      'type': isLab ? 'LAB' : 'NATURAL',
      'kind': isMelee ? 'MELEE' : 'SINGLE',
      'page': page < 1 ? 1 : page,
      'limit': pageSize < 1 ? 24 : pageSize,
    };

    final sortBy = _sortBy(sorting);
    if (sortBy != null) body['sort_by'] = sortBy;

    _putStringList(body, 'shapes', filters.shapes);

    if (filters.isFancyColor) {
      _putStringList(
        body,
        'fancy_colors',
        filters.selectedFancyColors.map(_mapFancyColor).toList(),
      );
      _putStringList(body, 'fancy_intensities', filters.selectedIntensities);
      _putStringList(body, 'fancy_overtones', filters.selectedOvertones);
    } else {
      final colors = filters.selectedStandardColors.isNotEmpty
          ? filters.selectedStandardColors
          : _colorsFromIndexRange(filters.minColorIndex, filters.maxColorIndex);
      _putStringList(body, 'colors', colors);
    }

    final clarities = filters.selectedClarityGrades.isNotEmpty
        ? filters.selectedClarityGrades
        : _claritiesFromIndexRange(
            filters.minClarityIndex,
            filters.maxClarityIndex,
          );
    _putStringList(body, 'clarities', clarities);
    _putStringList(
      body,
      'cuts',
      filters.selectedCuts.map(_mapCutGrade).toList(),
    );
    _putStringList(
      body,
      'polish',
      filters.selectedPolish.map(_mapFinishGrade).toList(),
    );
    _putStringList(
      body,
      'symmetry',
      filters.selectedSymmetry.map(_mapFinishGrade).toList(),
    );
    _putStringList(
      body,
      'certifications',
      filters.selectedLabs
          .where((lab) => lab.trim().isNotEmpty && lab != 'Others')
          .toList(),
    );
    _putStringList(
      body,
      'fluorescence',
      filters.selectedFluorescence.map(_mapFluorescence).toList(),
    );
    if (filters.selectedFluorescenceColor != null &&
        filters.selectedFluorescenceColor!.isNotEmpty) {
      body['fluorescence_colors'] = [filters.selectedFluorescenceColor];
    }

    if (isLab) {
      _putStringList(
        body,
        'growth_types',
        filters.selectedGrowthMethods
            .map((m) => m.trim().toLowerCase())
            .where((m) => m.isNotEmpty)
            .toList(),
      );
    } else {
      if (filters.selectedOrigin != null &&
          filters.selectedOrigin!.trim().isNotEmpty) {
        body['origins'] = [filters.selectedOrigin!.trim()];
      }
      if (filters.selectedRoughSource != null &&
          filters.selectedRoughSource!.trim().isNotEmpty) {
        body['rough_sources'] = [filters.selectedRoughSource!.trim()];
      }
    }

    final treatment = filters.selectedEnhancement;
    if (treatment != null &&
        treatment.trim().isNotEmpty &&
        !treatment.toLowerCase().startsWith('none')) {
      body['treatments'] = [treatment.trim()];
    }

    final company = filters.companyNameSearch?.trim();
    if (company != null && company.isNotEmpty) {
      body['companies'] = [company];
    }
    final location = filters.vendorLocationSearch?.trim();
    if (location != null && location.isNotEmpty) {
      body['locations'] = [location];
    }

    _putRange(
      body,
      'price_min',
      'price_max',
      filters.minPrice,
      filters.maxPrice,
      _defaultMinPrice,
      _defaultMaxPrice,
    );
    _putRange(
      body,
      'price_per_carat_min',
      'price_per_carat_max',
      filters.minPricePerCarat,
      filters.maxPricePerCarat,
      _defaultMinPpc,
      _defaultMaxPpc,
    );
    // Intentionally omit ratio_*/length_*/width_*/height_* unless narrowed.
    // The search API excludes null measurement fields, so full-range ratio
    // predicates (even 0.5–5) return zero hits.
    _putNarrowedRange(
      body,
      'length_min',
      'length_max',
      filters.minLength,
      filters.maxLength,
      _defaultMinLength,
      _defaultMaxLength,
    );
    _putNarrowedRange(
      body,
      'width_min',
      'width_max',
      filters.minWidth,
      filters.maxWidth,
      _defaultMinWidth,
      _defaultMaxWidth,
    );
    _putNarrowedRange(
      body,
      'height_min',
      'height_max',
      filters.minHeight,
      filters.maxHeight,
      _defaultMinHeight,
      _defaultMaxHeight,
    );
    // Do not send ratio_* — API null-excludes ratio and returns empty sets.

    if (isMelee) {
      _putRange(
        body,
        'carat_min',
        'carat_max',
        filters.minCaratPerPcs,
        filters.maxCaratPerPcs,
        _defaultMinCaratPerPcs,
        _defaultMaxCaratPerPcs,
      );
      _putRange(
        body,
        'total_carat_min',
        'total_carat_max',
        filters.minCarat,
        filters.maxCarat,
        _defaultMinCarat,
        _defaultMaxCarat,
      );
      _putRange(
        body,
        'total_pcs_min',
        'total_pcs_max',
        filters.minTotalPcs,
        filters.maxTotalPcs,
        _defaultMinTotalPcs,
        _defaultMaxTotalPcs,
      );
      _putRange(
        body,
        'price_per_pcs_min',
        'price_per_pcs_max',
        filters.minPricePerPcs,
        filters.maxPricePerPcs,
        _defaultMinPricePerPcs,
        _defaultMaxPricePerPcs,
      );

      final sieves = filters.selectedSieveIndices
          .where((i) => i >= 0 && i < SieveSize.defaultSieves.length)
          .map((i) => SieveSize.defaultSieves[i].apiLabel)
          .toList();
      _putStringList(body, 'sieve_sizes', sieves);

      if (filters.separable) body['is_separable'] = true;
    } else {
      _putRange(
        body,
        'carat_min',
        'carat_max',
        filters.minCarat,
        filters.maxCarat,
        _defaultMinCarat,
        _defaultMaxCarat,
      );
      _putRange(
        body,
        'table_min',
        'table_max',
        filters.minTable,
        filters.maxTable,
        _defaultMinTable,
        _defaultMaxTable,
      );
      _putRange(
        body,
        'depth_min',
        'depth_max',
        filters.minDepth,
        filters.maxDepth,
        _defaultMinDepth,
        _defaultMaxDepth,
      );
      _putStringList(body, 'girdles', filters.selectedGirdles);
      _putStringList(body, 'culets', filters.selectedCulets);
    }

    if (filters.searchByMedia || filters.sellersWithImages) {
      body['has_image'] = true;
    }
    if (filters.minSellerRating > 0) {
      body['seller_rating'] = _sellerRating(filters.minSellerRating);
    }

    return body;
  }

  /// Query params for `GET /diamond/filters`.
  static Map<String, dynamic> filtersQuery({
    required DiamondFilterState filters,
    required DiamondCatalogType catalog,
  }) {
    final isLab = catalog.isLabGrown;
    final isMelee = isLab
        ? filters.labCategory == 'Lab Melee'
        : filters.labNatural.usesMeleeFilters;
    return {
      'type': isLab ? 'lab' : 'natural',
      'kind': isMelee ? 'melee' : 'single',
    };
  }

  static String? _sortBy(List<SortingCriteria> sorting) {
    if (sorting.isEmpty) return null;
    final first = sorting.first;
    final asc = first.direction == SortDirection.ascending;
    return switch (first.fieldKey) {
      'price' => asc ? 'final_price_asc' : 'final_price_desc',
      'pricePerCarat' => asc ? 'ppc_asc' : 'ppc_desc',
      'carat' => asc ? 'carat_asc' : 'carat_desc',
      _ => null,
    };
  }

  static void _putStringList(
    Map<String, dynamic> body,
    String key,
    List<String> values,
  ) {
    final cleaned = values
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return;
    body[key] = cleaned;
  }

  static void _putRange(
    Map<String, dynamic> body,
    String minKey,
    String maxKey,
    double min,
    double max,
    double defaultMin,
    double defaultMax,
  ) {
    if (_isFullRange(min, max, defaultMin, defaultMax)) return;
    if (!_nearlyEqual(min, defaultMin)) body[minKey] = min;
    if (!_nearlyEqual(max, defaultMax)) body[maxKey] = max;
  }

  /// Like [_putRange], but requires the range to be strictly inside the default
  /// bounds before either bound is sent (avoids null-excluding API predicates).
  static void _putNarrowedRange(
    Map<String, dynamic> body,
    String minKey,
    String maxKey,
    double min,
    double max,
    double defaultMin,
    double defaultMax,
  ) {
    if (_isFullRange(min, max, defaultMin, defaultMax)) return;
    final narrowedMin = min > defaultMin + 1e-6;
    final narrowedMax = max < defaultMax - 1e-6;
    if (!narrowedMin && !narrowedMax) return;
    if (narrowedMin) body[minKey] = min;
    if (narrowedMax) body[maxKey] = max;
  }

  static bool _isFullRange(
    double min,
    double max,
    double defaultMin,
    double defaultMax,
  ) {
    return min <= defaultMin + 1e-6 && max >= defaultMax - 1e-6;
  }

  static bool _nearlyEqual(double a, double b) => (a - b).abs() <= 1e-6;

  static List<String> _colorsFromIndexRange(int minIndex, int maxIndex) {
    final colors = DiamondFilterState.colors;
    if (minIndex <= 0 && maxIndex >= colors.length - 1) return const [];
    final start = minIndex.clamp(0, colors.length - 1);
    final end = maxIndex.clamp(0, colors.length - 1);
    if (start > end) return const [];
    return colors.sublist(start, end + 1);
  }

  static List<String> _claritiesFromIndexRange(int minIndex, int maxIndex) {
    // UI default is 0..10 (not the full 0..11 list), treat as "no filter".
    if (minIndex <= 0 && maxIndex >= 10) return const [];
    final clarities = DiamondFilterState.clarities;
    final start = minIndex.clamp(0, clarities.length - 1);
    final end = maxIndex.clamp(0, clarities.length - 1);
    if (start > end) return const [];
    return clarities.sublist(start, end + 1);
  }

  static String _mapCutGrade(String value) {
    return switch (value.trim().toLowerCase()) {
      'ideal' || 'id' => 'ID',
      'excellent' || 'ex' => 'EX',
      'very good' || 'vg' => 'VG',
      'good' || 'gd' => 'GD',
      'fair' || 'fr' => 'FR',
      'poor' || 'pr' => 'PR',
      _ => value.trim().toUpperCase(),
    };
  }

  static String _mapFinishGrade(String value) {
    return switch (value.trim().toLowerCase()) {
      'ideal' || 'excellent' || 'ex' || 'id' => 'EX',
      'very good' || 'vg' => 'VG',
      'good' || 'gd' => 'GD',
      'fair' || 'fr' => 'FR',
      'poor' || 'pr' => 'PR',
      _ => value.trim().toUpperCase(),
    };
  }

  static String _mapFluorescence(String value) {
    return switch (value.trim().toLowerCase()) {
      'very strong' || 'v. str' || 'vstr' => 'V. Str',
      'none' => 'None',
      'faint' => 'Faint',
      'medium' => 'Medium',
      'slight' => 'Slight',
      'strong' => 'Strong',
      _ => value.trim(),
    };
  }

  static String _mapFancyColor(String value) {
    final v = value.trim();
    if (v.toLowerCase() == 'multi' || v.toLowerCase() == 'other') {
      return 'other';
    }
    return v;
  }

  static String _sellerRating(double rating) {
    if (rating == rating.roundToDouble()) {
      return rating.round().toString();
    }
    return rating.toString();
  }
}
