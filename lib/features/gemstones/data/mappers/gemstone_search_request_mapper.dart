import '../../domain/models/gemstone_filter_state.dart';
import '../../domain/repositories/gemstone_repository.dart';

/// Builds `POST /gem-stone/search` bodies from UI filter state.
abstract final class GemstoneSearchRequestMapper {
  static Map<String, dynamic> toBody({
    required GemstoneFilterState filters,
    required int page,
    int pageSize = GemstonePageSize.defaultSize,
    String? sortBy,
  }) {
    final isLab = _isLab(filters.stoneType);
    final isMelee = _isMelee(filters.lotType);

    final body = <String, dynamic>{
      'type': isLab ? 'LAB' : 'NATURAL',
      'kind': isMelee ? 'MELEE' : 'SINGLE',
      'page': page < 1 ? 1 : page,
      'limit': pageSize < 1 ? GemstonePageSize.defaultSize : pageSize,
    };

    if (sortBy != null && sortBy.isNotEmpty) {
      body['sort_by'] = sortBy;
    }

    _putStringList(body, 'gem_types', _gemTypes(filters));
    _putStringList(body, 'shapes', filters.selectedShapes);
    _putStringList(body, 'colors', filters.selectedColors);
    _putStringList(body, 'color_intensities', filters.selectedIntensities);
    _putStringList(body, 'clarities', filters.selectedClarities);
    _putStringList(body, 'cuts', filters.selectedCutGrades);
    _putStringList(body, 'certifications', filters.selectedCertifications);
    _putStringList(body, 'treatments', filters.selectedTreatments);
    _putStringList(body, 'fluorescence', filters.selectedFluorescence);

    final origin = filters.selectedOrigin ?? filters.selectedOriginCountry;
    if (origin != null && origin.trim().isNotEmpty) {
      body['origins'] = [_mapOrigin(origin.trim())];
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

    final company = filters.companyName.trim();
    if (company.isNotEmpty) body['companies'] = [company];

    final location = filters.vendorLocation.trim();
    if (location.isNotEmpty) body['locations'] = [location];

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

    if (filters.searchByMedia) body['has_image'] = true;

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
      ...filters.selectedGemstoneTypes.map((t) => t.trim()).where((t) => t.isNotEmpty),
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

  static void _putStringList(
    Map<String, dynamic> body,
    String key,
    List<String> values,
  ) {
    final cleaned =
        values.map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
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
}
