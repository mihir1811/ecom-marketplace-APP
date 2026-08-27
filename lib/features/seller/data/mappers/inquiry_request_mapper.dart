import '../../domain/models/seller_inquiry.dart';
import '../../../../core/network/validation_message_formatter.dart';

/// Builds create/update JSON bodies from inquiry form controller keys.
abstract final class InquiryRequestMapper {
  /// Returns a user-friendly message when a form value has the wrong type.
  static String? validateFormInput({
    required InquiryCategory category,
    required Map<String, String> textFields,
  }) {
    for (final entry in textFields.entries) {
      final apiKey = _mapKey(category, entry.key);
      if (apiKey == null || !_isAllowed(category, apiKey)) continue;

      final trimmed = entry.value.trim();
      if (trimmed.isEmpty) continue;

      if (_numericKeys.contains(apiKey) && !_isValidNumber(trimmed)) {
        return '${ValidationMessageFormatter.fieldLabel(apiKey)} must be a valid number.';
      }

      if (_boolKeys.contains(apiKey) && !_isValidBool(trimmed)) {
        return '${ValidationMessageFormatter.fieldLabel(apiKey)} must be yes or no.';
      }
    }
    return null;
  }

  static bool _isValidNumber(String value) {
    return int.tryParse(value) != null || double.tryParse(value) != null;
  }

  static bool _isValidBool(String value) {
    final lower = value.toLowerCase();
    return lower == 'true' ||
        lower == 'false' ||
        lower == 'yes' ||
        lower == 'no';
  }

  static Map<String, dynamic> toCreateBody({
    required InquiryCategory category,
    required Map<String, String> textFields,
    required Map<String, bool> boolFields,
    DateTime? urgency,
  }) {
    final body = <String, dynamic>{};

    for (final entry in textFields.entries) {
      final apiKey = _mapKey(category, entry.key);
      if (apiKey == null || !_isAllowed(category, apiKey)) continue;
      final parsed = _parseValue(apiKey, entry.value);
      if (parsed != null) body[apiKey] = parsed;
    }

    for (final entry in boolFields.entries) {
      final apiKey = _mapKey(category, entry.key);
      if (apiKey == null || !_isAllowed(category, apiKey)) continue;
      body[apiKey] = entry.value;
    }

    if (urgency != null) {
      body['urgency'] = urgency.toUtc().toIso8601String();
    }

    _applyRuntimeDefaults(category, body);

    return body;
  }

  static const _na = 'NA';

  /// Fills API runtime-required fields the user left blank with neutral defaults.
  static void _applyRuntimeDefaults(
    InquiryCategory category,
    Map<String, dynamic> body,
  ) {
    _ensureCertification(body);
    _ensureDiamondLabFields(body);
    _stripDiamondUiFields(body);

    for (final spec in _defaultsFor(category)) {
      if (!_isMissing(body, spec.key)) continue;
      body[spec.key] = spec.value;
    }
  }

  static void _ensureCertification(Map<String, dynamic> body) {
    if (body['isCertified'] == true && _isMissing(body, 'certificateCompany')) {
      body['certificateCompany'] = _na;
    }
  }

  static void _ensureDiamondLabFields(Map<String, dynamic> body) {
    if (body['diamondType'] == 'LAB' && _isMissing(body, 'growthProcess')) {
      body['growthProcess'] = _na;
    }
  }

  static void _stripDiamondUiFields(Map<String, dynamic> body) {
    if (body['diamondType'] != 'LAB') {
      body.remove('growthProcess');
    }
  }

  static bool _isMissing(Map<String, dynamic> body, String key) {
    if (!body.containsKey(key)) return true;
    final value = body[key];
    if (value == null) return true;
    if (value is String && value.trim().isEmpty) return true;
    return false;
  }

  static List<_DefaultSpec> _defaultsFor(InquiryCategory category) {
    return switch (category) {
      InquiryCategory.diamond => [
        for (final key in [
          'subCategory',
          'diamondType',
          'shape',
          'colorMin',
          'colorMax',
          'clarityMin',
          'clarityMax',
          'cut',
          'inclusionType',
          'fluorescenceIntensityMin',
          'fluorescenceIntensityMax',
          'paymentTerms',
          'remarks',
          'imageUrl',
          'deliveryLocation',
          'sieveSizeMin',
          'sieveSizeMax',
        ])
          _DefaultSpec(key, _na),
        for (final key in [
          'caratMin',
          'caratMax',
          'totalPriceMin',
          'totalPriceMax',
          'pricePerCaratMin',
          'pricePerCaratMax',
          'lengthMin',
          'lengthMax',
          'widthMin',
          'widthMax',
          'heightMin',
          'heightMax',
        ])
          _DefaultSpec(key, 0),
        const _DefaultSpec('quantity', 1),
      ],
      InquiryCategory.gemstone => [
        for (final key in [
          'gemstoneType',
          'shape',
          'clarity',
          'origin',
          'treatment',
          'description',
          'paymentTerms',
          'primaryColorMin',
          'primaryColorMax',
          'imageUrl',
          'deliveryLocation',
        ])
          _DefaultSpec(key, _na),
        for (final key in [
          'caratWeightMin',
          'caratWeightMax',
          'totalPriceMin',
          'totalPriceMax',
          'pricePerCaratMin',
          'pricePerCaratMax',
          'lengthMin',
          'lengthMax',
          'widthMin',
          'widthMax',
          'heightMin',
          'heightMax',
        ])
          _DefaultSpec(key, 0),
        const _DefaultSpec('quantity', 1),
      ],
      InquiryCategory.bullion => [
        for (final key in [
          'certificateCompany',
          'metalType',
          'metalFineness',
          'shapeFormat',
          'preferredMint',
          'description',
          'paymentTerms',
          'imageUrl',
          'deliveryLocation',
        ])
          _DefaultSpec(key, _na),
        for (final key in [
          'weightMin',
          'weightMax',
          'totalPriceMin',
          'totalPriceMax',
          'pricePerGramMin',
          'pricePerGramMax',
          'lengthMin',
          'lengthMax',
          'widthMin',
          'widthMax',
          'heightMin',
          'heightMax',
        ])
          _DefaultSpec(key, 0),
        const _DefaultSpec('quantity', 1),
      ],
      InquiryCategory.watch => [
        for (final key in [
          'brand',
          'model',
          'referenceNumber',
          'caseMaterial',
          'dialColor',
          'strapMaterial',
          'movement',
          'condition',
          'description',
          'imageUrl',
          'deliveryLocation',
        ])
          _DefaultSpec(key, _na),
        for (final key in [
          'yearMin',
          'yearMax',
          'totalPriceMin',
          'totalPriceMax',
          'caseSizeMin',
          'caseSizeMax',
        ])
          _DefaultSpec(key, 0),
      ],
      InquiryCategory.jewelry => [
        for (final key in [
          'subCategory',
          'metalType',
          'metalPurity',
          'occasion',
          'intendedWearer',
          'metalColor',
          'finish',
          'stoneType',
          'stoneShape',
          'stoneColorMin',
          'stoneColorMax',
          'stoneClarityMin',
          'stoneClarityMax',
          'stoneCut',
          'settingType',
          'ringSize',
          'necklaceLength',
          'braceletSize',
          'braceletLength',
          'engravingText',
          'paymentTerms',
          'designDescription',
          'referenceImage',
          'referenceVideo',
          'deliveryLocation',
        ])
          _DefaultSpec(key, _na),
        for (final key in [
          'stoneCaratMin',
          'stoneCaratMax',
          'stoneQuantity',
          'chainLengthMin',
          'chainLengthMax',
          'widthMin',
          'widthMax',
          'thicknessMin',
          'thicknessMax',
          'approxWeightMin',
          'approxWeightMax',
          'totalPriceMin',
          'totalPriceMax',
        ])
          _DefaultSpec(key, 0),
        const _DefaultSpec('quantity', 1),
      ],
    };
  }

  static bool _isAllowed(InquiryCategory category, String apiKey) =>
      _allowedKeys[category]?.contains(apiKey) ?? false;

  static String? _mapKey(InquiryCategory category, String formKey) {
    return switch (formKey) {
      'certificateName' => 'certificateCompany',
      'treatments' => 'treatment',
      'totalBudgetMin' => 'totalPriceMin',
      'totalBudgetMax' => 'totalPriceMax',
      'hasService' => 'hasManuals',
      'jewelrySubCategory' when category == InquiryCategory.jewelry =>
        'subCategory',
      'jewelrySubCategory' => null,
      'subCategory' when category == InquiryCategory.diamond => 'subCategory',
      'subCategory' => null,
      'caratMin' when category == InquiryCategory.gemstone => 'caratWeightMin',
      'caratMin' when category == InquiryCategory.diamond => 'caratMin',
      'caratMin' => null,
      'caratMax' when category == InquiryCategory.gemstone => 'caratWeightMax',
      'caratMax' when category == InquiryCategory.diamond => 'caratMax',
      'caratMax' => null,
      'imageUrl' when category == InquiryCategory.jewelry => 'referenceImage',
      'imageUrl' when category != InquiryCategory.jewelry => 'imageUrl',
      'referenceImage' when category == InquiryCategory.jewelry =>
        'referenceImage',
      'referenceImage' => null,
      'diamondType' when category != InquiryCategory.diamond => null,
      'colorMin' when category != InquiryCategory.diamond => null,
      'colorMax' when category != InquiryCategory.diamond => null,
      'clarityMin' when category != InquiryCategory.diamond => null,
      'clarityMax' when category != InquiryCategory.diamond => null,
      'cut' when category != InquiryCategory.diamond => null,
      'metalFineness' when category != InquiryCategory.bullion => null,
      'shapeFormat' when category != InquiryCategory.bullion => null,
      'weightMin' when category != InquiryCategory.bullion => null,
      'weightMax' when category != InquiryCategory.bullion => null,
      'metalType' when category == InquiryCategory.bullion ||
          category == InquiryCategory.jewelry =>
        'metalType',
      'metalType' => null,
      'metalPurity' when category != InquiryCategory.jewelry => null,
      'brand' when category != InquiryCategory.watch => null,
      'model' when category != InquiryCategory.watch => null,
      'shape' when category == InquiryCategory.diamond ||
          category == InquiryCategory.gemstone =>
        'shape',
      'shape' => null,
      'gemstoneType' when category == InquiryCategory.gemstone => 'gemstoneType',
      'gemstoneType' => null,
      _ => _passthroughIfAllowed(category, formKey),
    };
  }

  /// Only pass through keys that are valid API fields for [category].
  static String? _passthroughIfAllowed(InquiryCategory category, String key) {
    if (_isAllowed(category, key)) return key;
    return null;
  }

  static Object? _parseValue(String apiKey, String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (_boolKeys.contains(apiKey)) {
      final lower = trimmed.toLowerCase();
      if (lower == 'yes' || lower == 'true') return true;
      if (lower == 'no' || lower == 'false') return false;
    }

    if (_numericKeys.contains(apiKey)) {
      final asInt = int.tryParse(trimmed);
      if (asInt != null) return asInt;
      final asDouble = double.tryParse(trimmed);
      if (asDouble != null) return asDouble;
      return null;
    }

    if (apiKey == 'movement') {
      return trimmed.toUpperCase();
    }

    return trimmed;
  }

  static const _allowedKeys = {
    InquiryCategory.diamond: {
      'subCategory',
      'diamondType',
      'growthProcess',
      'isCertified',
      'certificateCompany',
      'sieveSizeMin',
      'sieveSizeMax',
      'shape',
      'caratMin',
      'caratMax',
      'colorMin',
      'colorMax',
      'clarityMin',
      'clarityMax',
      'cut',
      'bgm',
      'inclusionType',
      'fluorescenceIntensityMin',
      'fluorescenceIntensityMax',
      'caratPerPiece',
      'quantity',
      'totalPriceMin',
      'totalPriceMax',
      'pricePerCaratMin',
      'pricePerCaratMax',
      'lengthMin',
      'lengthMax',
      'widthMin',
      'widthMax',
      'heightMin',
      'heightMax',
      'paymentTerms',
      'remarks',
      'urgency',
      'imageUrl',
      'videoUrl',
      'deliveryLocation',
    },
    InquiryCategory.gemstone: {
      'gemstoneType',
      'shape',
      'caratWeightMin',
      'caratWeightMax',
      'isCertified',
      'certificateCompany',
      'primaryColorMin',
      'primaryColorMax',
      'clarity',
      'origin',
      'treatment',
      'quantity',
      'totalPriceMin',
      'totalPriceMax',
      'pricePerCaratMin',
      'pricePerCaratMax',
      'lengthMin',
      'lengthMax',
      'widthMin',
      'widthMax',
      'heightMin',
      'heightMax',
      'description',
      'paymentTerms',
      'urgency',
      'imageUrl',
      'videoUrl',
      'deliveryLocation',
    },
    InquiryCategory.bullion: {
      'isCertified',
      'certificateCompany',
      'metalType',
      'metalFineness',
      'shapeFormat',
      'weightMin',
      'weightMax',
      'preferredMint',
      'quantity',
      'totalPriceMin',
      'totalPriceMax',
      'pricePerGramMin',
      'pricePerGramMax',
      'lengthMin',
      'lengthMax',
      'widthMin',
      'widthMax',
      'heightMin',
      'heightMax',
      'description',
      'paymentTerms',
      'urgency',
      'imageUrl',
      'videoUrl',
      'deliveryLocation',
    },
    InquiryCategory.watch: {
      'brand',
      'model',
      'referenceNumber',
      'yearMin',
      'yearMax',
      'totalPriceMin',
      'totalPriceMax',
      'caseMaterial',
      'caseSizeMin',
      'caseSizeMax',
      'dialColor',
      'strapMaterial',
      'movement',
      'hasOriginalBox',
      'hasWarrantyPapers',
      'hasManuals',
      'condition',
      'description',
      'urgency',
      'imageUrl',
      'videoUrl',
      'deliveryLocation',
    },
    InquiryCategory.jewelry: {
      'subCategory',
      'metalType',
      'metalPurity',
      'occasion',
      'intendedWearer',
      'metalColor',
      'finish',
      'hasStone',
      'stoneType',
      'stoneShape',
      'stoneCaratMin',
      'stoneCaratMax',
      'stoneColorMin',
      'stoneColorMax',
      'stoneClarityMin',
      'stoneClarityMax',
      'stoneCut',
      'stoneQuantity',
      'settingType',
      'ringSize',
      'necklaceLength',
      'braceletSize',
      'braceletLength',
      'chainLengthMin',
      'chainLengthMax',
      'widthMin',
      'widthMax',
      'thicknessMin',
      'thicknessMax',
      'approxWeightMin',
      'approxWeightMax',
      'isEngravingRequired',
      'engravingText',
      'quantity',
      'totalPriceMin',
      'totalPriceMax',
      'paymentTerms',
      'designDescription',
      'referenceImage',
      'referenceVideo',
      'urgency',
      'deliveryLocation',
    },
  };

  static const _numericKeys = {
    'caratMin',
    'caratMax',
    'caratWeightMin',
    'caratWeightMax',
    'caratPerPiece',
    'quantity',
    'totalPriceMin',
    'totalPriceMax',
    'pricePerCaratMin',
    'pricePerCaratMax',
    'pricePerGramMin',
    'pricePerGramMax',
    'lengthMin',
    'lengthMax',
    'widthMin',
    'widthMax',
    'heightMin',
    'heightMax',
    'weightMin',
    'weightMax',
    'yearMin',
    'yearMax',
    'caseSizeMin',
    'caseSizeMax',
    'stoneCaratMin',
    'stoneCaratMax',
    'stoneQuantity',
    'chainLengthMin',
    'chainLengthMax',
    'thicknessMin',
    'thicknessMax',
    'approxWeightMin',
    'approxWeightMax',
  };

  static const _boolKeys = {
    'isCertified',
    'bgm',
    'hasStone',
    'hasOriginalBox',
    'hasWarrantyPapers',
    'hasManuals',
    'isEngravingRequired',
  };
}

class _DefaultSpec {
  const _DefaultSpec(this.key, this.value);

  final String key;
  final Object value;
}
