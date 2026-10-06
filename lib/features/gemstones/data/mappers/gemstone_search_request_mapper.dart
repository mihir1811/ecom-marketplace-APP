import '../../domain/models/gemstone_filter_state.dart';
import '../../domain/repositories/gemstone_repository.dart';

/// Builds `POST /gem-stone/search` bodies from UI filter state.
abstract final class GemstoneSearchRequestMapper {
  static Map<String, dynamic> toBody({
    required GemstoneFilterState filters,
    required int page,
    int pageSize = GemstonePageSize.defaultSize,
    String? sortBy,
    String? sellerId,
  }) {
    final isLab = _isLab(filters.stoneType);
    final isMelee = _isMelee(filters.lotType);

    final body = <String, dynamic>{
      'type': isLab ? 'LAB' : 'NATURAL',
      'kind': isMelee ? 'MELEE' : 'SINGLE',
      'page': page < 1 ? 1 : page,
      'limit': pageSize < 1 ? GemstonePageSize.defaultSize : pageSize,
    };

    final sid = sellerId?.trim();
    if (sid != null && sid.isNotEmpty) {
      body['seller_id'] = sid;
    }

    if (sortBy != null && sortBy.isNotEmpty) {
      body['sort_by'] = sortBy;
    }

    _putStringList(body, 'gem_types', _gemTypes(filters));
    _putStringList(body, 'shapes', filters.selectedShapes);
    _putStringList(body, 'colors', filters.selectedColors);
    _putStringList(body, 'color_intensities', filters.selectedIntensities);
    _putStringList(body, 'clarities', filters.selectedClarities);
    _putStringList(body, 'cuts', filters.selectedCutGrades);
    _putStringList(
      body,
      'certifications',
      filters.selectedCertifications.map(_mapCertification).toList(),
    );
    _putStringList(
      body,
      'treatments',
      filters.selectedTreatments.map(_mapTreatment).toList(),
    );
    _putStringList(body, 'fluorescence', filters.selectedFluorescence);

    if (!isLab) {
      final origins = {
        for (final o in [
          ?filters.selectedOrigin,
          ...filters.selectedOriginCountries,
        ])
          if (o.trim().isNotEmpty) _mapOrigin(o.trim()),
      };
      _putStringList(body, 'origins', origins.toList());
    }

    final grade = filters.selectedQualityGrade;
    if (grade != null && grade.trim().isNotEmpty) {
      body['quality_grades'] = [grade.trim()];
    }

    final fluoColor = filters.selectedFluorescenceColor;
    if (fluoColor != null &&
        fluoColor.trim().isNotEmpty &&
        fluoColor != 'None') {
      body['fluorescence_colors'] = [fluoColor.trim()];
    }

    _putStringList(body, 'companies', filters.companyNames);
    _putStringList(body, 'locations', filters.vendorLocations);
    _putStringList(body, 'exclude_companies', filters.excludedCompanyNames);
    _putStringList(body, 'exclude_locations', filters.excludedVendorLocations);

    if (isMelee) {
      _putRange(
        body,
        'carat_per_pcs_min',
        'carat_per_pcs_max',
        filters.minCaratPerPiece,
        filters.maxCaratPerPiece,
        GemstoneFilterState.caratMin,
        GemstoneFilterState.caratMax,
      );
      _putRange(
        body,
        'total_carat_min',
        'total_carat_max',
        filters.minTotalCarat,
        filters.maxTotalCarat,
        GemstoneFilterState.caratMin,
        GemstoneFilterState.caratMax,
      );
      _putRange(
        body,
        'quantity_min',
        'quantity_max',
        filters.minTotalPcs,
        filters.maxTotalPcs,
        GemstoneFilterState.pcsMin,
        GemstoneFilterState.pcsMax,
      );
      _putRange(
        body,
        'price_per_pcs_min',
        'price_per_pcs_max',
        filters.minPricePerPiece,
        filters.maxPricePerPiece,
        GemstoneFilterState.priceMin,
        GemstoneFilterState.pricePerPieceMax,
      );
      if (filters.separable) body['is_separable'] = true;
    } else {
      _putRange(
        body,
        'carat_min',
        'carat_max',
        filters.minTotalCarat,
        filters.maxTotalCarat,
        GemstoneFilterState.caratMin,
        GemstoneFilterState.caratMax,
      );
    }

    _putRange(
      body,
      'price_min',
      'price_max',
      filters.minTotalPrice,
      filters.maxTotalPrice,
      GemstoneFilterState.priceMin,
      GemstoneFilterState.totalPriceMax,
    );
    _putRange(
      body,
      'price_per_carat_min',
      'price_per_carat_max',
      filters.minPricePerCarat,
      filters.maxPricePerCarat,
      GemstoneFilterState.priceMin,
      GemstoneFilterState.pricePerPieceMax,
    );

    // Separate length/width/height columns on search (not the measurement string).
    // Do not send ratio_* — gem inventory has empty ratio and any ratio filter
    // returns zero hits.
    _putNarrowedRange(
      body,
      'length_min',
      'length_max',
      filters.minLength,
      filters.maxLength,
      GemstoneFilterState.dimensionMin,
      GemstoneFilterState.dimensionMax,
    );
    _putNarrowedRange(
      body,
      'width_min',
      'width_max',
      filters.minWidth,
      filters.maxWidth,
      GemstoneFilterState.dimensionMin,
      GemstoneFilterState.dimensionMax,
    );
    _putNarrowedRange(
      body,
      'height_min',
      'height_max',
      filters.minHeight,
      filters.maxHeight,
      GemstoneFilterState.dimensionMin,
      GemstoneFilterState.dimensionMax,
    );

    if (filters.searchByMedia) body['has_image'] = true;
    if (filters.makeAnOffer) body['is_make_an_offer_allowed'] = true;
    // `available` takes a single status, so it is only sent when exactly
    // one is picked; several statuses fall back to no availability filter.
    final statuses = filters.selectedAvailabilities
        .map(_mapAvailability)
        .whereType<String>()
        .toSet();
    if (statuses.length == 1) body['available'] = statuses.single;

    return body;
  }

  /// Query params for `GET /gem-stone/filters`.
  static Map<String, dynamic> filtersQuery(GemstoneFilterState filters) {
    return {
      'type': _isLab(filters.stoneType) ? 'lab' : 'natural',
      'kind': _isMelee(filters.lotType) ? 'melee' : 'single',
    };
  }

  static bool _isLab(String? stoneType) {
    final v = (stoneType ?? 'Natural').toLowerCase();
    return v.contains('lab');
  }

  static bool _isMelee(String? lotType) {
    return (lotType ?? 'Single').toLowerCase() == 'melee';
  }

  static List<String> _gemTypes(GemstoneFilterState filters) {
    final types = <String>{
      ...filters.selectedGemstoneTypes
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty),
    };
    for (final month in filters.selectedBirthstoneMonths) {
      final stone = GemstoneFilterState.birthstones[month];
      if (stone != null && stone.trim().isNotEmpty) types.add(stone.trim());
    }
    return types.toList();
  }

  static String _mapOrigin(String origin) {
    return switch (origin) {
      'Burma' => 'Burma (Myanmar)',
      _ => origin,
    };
  }

  /// Maps UI treatment labels to GET `/gem-stone/filters` values.
  static String _mapTreatment(String value) {
    return switch (value.trim().toLowerCase()) {
      'oiled' || 'oiling' => 'Oiling',
      'heated' => 'Heated',
      'none' => 'None',
      _ => value.trim(),
    };
  }

  /// Maps UI lab labels to filters/search certification values.
  static String _mapCertification(String value) {
    final v = value.trim();
    return switch (v.toLowerCase()) {
      'gübelin' || 'gubelin' => 'Gubelin',
      'others' ||
      'other' ||
      'non-certified' ||
      'non certified' => 'Non-certified',
      _ => v,
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
    if (min <= defaultMin + 1e-6 && max >= defaultMax - 1e-6) return;
    if ((min - defaultMin).abs() > 1e-6) body[minKey] = min;
    if ((max - defaultMax).abs() > 1e-6) body[maxKey] = max;
  }

  /// Requires the range to be strictly inside defaults before either bound is
  /// sent (avoids null-excluding measurement predicates on full spans).
  static void _putNarrowedRange(
    Map<String, dynamic> body,
    String minKey,
    String maxKey,
    double min,
    double max,
    double defaultMin,
    double defaultMax,
  ) {
    if (min <= defaultMin + 1e-6 && max >= defaultMax - 1e-6) return;
    final narrowedMin = min > defaultMin + 1e-6;
    final narrowedMax = max < defaultMax - 1e-6;
    if (!narrowedMin && !narrowedMax) return;
    if (narrowedMin) body[minKey] = min;
    if (narrowedMax) body[maxKey] = max;
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
}
