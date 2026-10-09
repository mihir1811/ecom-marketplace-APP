import '../../domain/models/diamond_catalog_type.dart';
import '../../domain/models/diamond_filter_state.dart';
import '../../domain/models/sieve_size.dart';
import '../../domain/models/sorting_criteria.dart';

/// Builds `POST /diamond/search` bodies from UI filter + catalog scope.
abstract final class DiamondSearchRequestMapper {
  static const _defaultMinPrice = DiamondFilterState.priceMin;
  static const _defaultMaxPrice = DiamondFilterState.priceMax;
  static const _defaultMinPpc = DiamondFilterState.pricePerCaratMin;
  static const _defaultMaxPpc = DiamondFilterState.pricePerCaratMax;
  static const _defaultMinCarat = DiamondFilterState.caratMin;
  static const _defaultMaxCarat = DiamondFilterState.caratMax;
  static const _defaultMinTable = DiamondFilterState.tableMin;
  static const _defaultMaxTable = DiamondFilterState.tableMax;
  static const _defaultMinDepth = DiamondFilterState.depthMin;
  static const _defaultMaxDepth = DiamondFilterState.depthMax;
  static const _defaultMinLength = DiamondFilterState.dimensionMin;
  static const _defaultMaxLength = DiamondFilterState.dimensionMax;
  static const _defaultMinWidth = DiamondFilterState.dimensionMin;
  static const _defaultMaxWidth = DiamondFilterState.dimensionMax;
  static const _defaultMinHeight = DiamondFilterState.dimensionMin;
  static const _defaultMaxHeight = DiamondFilterState.dimensionMax;
  static const _defaultMinRatio = DiamondFilterState.ratioMin;
  static const _defaultMaxRatio = DiamondFilterState.ratioMax;
  static const _defaultMinCaratPerPcs = DiamondFilterState.caratPerPcsMinLimit;
  static const _defaultMaxCaratPerPcs = DiamondFilterState.caratPerPcsMaxLimit;
  static const _defaultMinPricePerPcs = DiamondFilterState.pricePerPcsMinLimit;
  static const _defaultMaxPricePerPcs = DiamondFilterState.pricePerPcsMaxLimit;
  static const _defaultMinTotalPcs = DiamondFilterState.totalPcsMinLimit;
  static const _defaultMaxTotalPcs = DiamondFilterState.totalPcsMaxLimit;

  static Map<String, dynamic> toBody({
    required DiamondFilterState filters,
    required DiamondCatalogType catalog,
    required int page,
    int pageSize = 24,
    List<SortingCriteria> sorting = const [],
    String? sellerId,
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

    final sid = sellerId?.trim();
    if (sid != null && sid.isNotEmpty) {
      body['seller_id'] = sid;
    }

    final sortBy = _sortBy(sorting);
    if (sortBy != null) body['sort_by'] = sortBy;

    _putStringList(body, 'shapes', filters.shapes);

    if (filters.isFancyColor) {
      _putStringList(
        body,
        'fancy_colors',
        filters.selectedFancyColors.map(_mapFancyColor).toList(),
      );
      _putStringList(
        body,
        'fancy_intensities',
        filters.selectedIntensities.map(_mapFancyIntensity).toList(),
      );
      _putStringList(
        body,
        'fancy_overtones',
        filters.selectedOvertones.map(_mapFancyOvertone).toList(),
      );
    } else {
      final colors = filters.selectedStandardColors.isNotEmpty
          ? filters.selectedStandardColors
          : _colorsFromIndexRange(filters.minColorIndex, filters.maxColorIndex);
      _putStringList(body, 'colors', _mapColorsForApi(colors));
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
    _putStringList(
      body,
      'fluorescence_colors',
      filters.selectedFluorescenceColors
          .map((c) => c.trim().toLowerCase())
          .where((c) => c != 'none')
          .toList(),
    );

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
      _putMapped(body, 'origins', filters.selectedOrigins, _mapOrigin);
      _putMapped(
        body,
        'rough_sources',
        filters.selectedRoughSources,
        _mapRoughSource,
      );
    }

    _putMapped(body, 'treatments', filters.selectedEnhancements, _mapTreatment);

    _putStringList(body, 'companies', filters.companyNames);
    _putStringList(body, 'locations', filters.vendorLocations);
    _putStringList(body, 'exclude_companies', filters.excludedCompanyNames);
    _putStringList(body, 'exclude_locations', filters.excludedVendorLocations);

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
    // Measurement filters map to separate DB columns (length/width/height/ratio).
    // Only send when narrowed — full-range ratio still drops null-ratio rows.
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
    _putNarrowedRange(
      body,
      'ratio_min',
      'ratio_max',
      filters.minRatio,
      filters.maxRatio,
      _defaultMinRatio,
      _defaultMaxRatio,
    );

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
      _putNarrowedRange(
        body,
        'table_min',
        'table_max',
        filters.minTable,
        filters.maxTable,
        _defaultMinTable,
        _defaultMaxTable,
      );
      _putNarrowedRange(
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
    if (filters.makeAnOffer) {
      body['is_make_an_offer_allowed'] = true;
    }
    // `available` takes a single status, so it is only sent when exactly
    // one is picked; several statuses fall back to no availability filter.
    final statuses = filters.selectedAvailabilities
        .map(_mapAvailability)
        .whereType<String>()
        .toSet();
    if (statuses.length == 1) {
      body['available'] = statuses.single;
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
    final ordered = List<SortingCriteria>.from(sorting)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final first = ordered.first;
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

  /// Maps each value, drops the ones that map to nothing, de-duplicates.
  static void _putMapped(
    Map<String, dynamic> body,
    String key,
    List<String> values,
    String? Function(String) map,
  ) {
    final mapped = <String>{for (final v in values) ?map(v)};
    _putStringList(body, key, mapped.toList());
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
    const colors = DiamondFilterState.colors;
    if (minIndex <= 0 && maxIndex >= colors.length - 1) return const [];
    final start = minIndex.clamp(0, colors.length - 1);
    final end = maxIndex.clamp(0, colors.length - 1);
    if (start > end) return const [];
    return colors.sublist(start, end + 1);
  }

  /// Maps UI color letters to `/diamond/filters` values.
  /// Inventory stores late colors as pairs (`O-P` … `Y-Z`), not singles.
  static List<String> _mapColorsForApi(List<String> colors) {
    const pairByLetter = <String, String>{
      'O': 'O-P',
      'P': 'O-P',
      'Q': 'Q-R',
      'R': 'Q-R',
      'S': 'S-T',
      'T': 'S-T',
      'U': 'U-V',
      'V': 'U-V',
      'W': 'W-X',
      'X': 'W-X',
      'Y': 'Y-Z',
      'Z': 'Y-Z',
    };
    final out = <String>{};
    for (final raw in colors) {
      final c = raw.trim();
      if (c.isEmpty) continue;
      final upper = c.toUpperCase();
      out.add(pairByLetter[upper] ?? upper);
    }
    return out.toList();
  }

  static List<String> _claritiesFromIndexRange(int minIndex, int maxIndex) {
    const clarities = DiamondFilterState.clarities;
    // Full clarity span (incl. I3) means "no filter".
    if (minIndex <= 0 && maxIndex >= clarities.length - 1) return const [];
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
    // Match GET `/diamond/filters` option values (e.g. "Very Strong").
    return switch (value.trim().toLowerCase()) {
      'very strong' || 'v. str' || 'vstr' => 'Very Strong',
      'none' => 'None',
      'faint' => 'Faint',
      'medium' => 'Medium',
      'slight' => 'Slight',
      'strong' => 'Strong',
      _ => value.trim(),
    };
  }

  static String _mapFancyColor(String value) {
    final lower = value.trim().toLowerCase();
    if (lower == 'multi' || lower == 'other') return 'other';
    // Filters API uses American spelling "gray".
    if (lower == 'grey') return 'gray';
    return lower;
  }

  static String _mapFancyIntensity(String value) {
    return value.trim().toLowerCase();
  }

  static String _mapFancyOvertone(String value) {
    return value.trim().toLowerCase();
  }

  /// Maps UI enhancement labels to filters/search treatment values.
  static String? _mapTreatment(String? value) {
    if (value == null) return null;
    var v = value.trim();
    if (v.isEmpty) return null;
    final lower = v.toLowerCase();
    if (lower.startsWith('none')) return null;
    v = v
        .replaceAll(RegExp(r'\s*\(treatment\)\s*', caseSensitive: false), '')
        .trim();
    return v.toLowerCase();
  }

  static String? _mapOrigin(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return null;
    return v.toLowerCase();
  }

  /// Maps UI rough-source labels onto filters API country-style values.
  static String? _mapRoughSource(String? value) {
    if (value == null) return null;
    final v = value.trim();
    if (v.isEmpty) return null;
    return switch (v.toLowerCase()) {
      'canadian' || 'canada' => 'canada',
      'russian' || 'russia' => 'russia',
      'rio tinto' => 'rio tinto',
      'sight holder' => 'sight holder',
      'others' || 'other' => null,
      _ => v.toLowerCase(),
    };
  }

  static String? _mapAvailability(String value) {
    return switch (value.trim().toLowerCase()) {
      'all' || '' => null,
      'available' || 'yes' || 'in stock' => 'yes',
      'on memo' || 'memo' => 'memo',
      'on hold' || 'hold' => 'hold',
      'sold' => 'sold',
      _ => null,
    };
  }

  static String _sellerRating(double rating) {
    if (rating == rating.roundToDouble()) {
      return rating.round().toString();
    }
    return rating.toString();
  }
}
