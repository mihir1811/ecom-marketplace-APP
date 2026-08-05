/// Converts NestJS / class-validator API messages into user-friendly copy.
abstract final class ValidationMessageFormatter {
  static String humanize(String raw) {
    if (raw.trim().isEmpty) {
      return 'Please check your details and try again.';
    }
    final lines = raw
        .split('\n')
        .map(humanizeLine)
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return 'Please check your details and try again.';
    return lines.join('\n');
  }

  static String humanizeLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return trimmed;

    if (trimmed.contains('not exists')) {
      return 'This inquiry could not be found.';
    }
    if (trimmed.toLowerCase().contains('do not have access')) {
      return 'This inquiry is not linked to your account.';
    }
    if (trimmed.toLowerCase() == 'unauthorized') {
      return 'Your session has expired. Please sign in again.';
    }

    var match = RegExp(
      r'^property (\w+) should not exist$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) {
      return 'Something went wrong while sending your inquiry. Please try again.';
    }

    match = RegExp(
      r'^(\w+) must be a number(?: conforming to the specified constraints)?\.?$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) {
      return '${fieldLabel(match.group(1)!)} must be a valid number.';
    }

    match = RegExp(
      r'^(\w+) must be an integer number\.?$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) {
      return '${fieldLabel(match.group(1)!)} must be a whole number.';
    }

    match = RegExp(
      r'^(\w+) must be a string\.?$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) {
      return '${fieldLabel(match.group(1)!)} must be text.';
    }

    match = RegExp(
      r'^(\w+) must (?:not )?be empty\.?$|^(\w+) should not be empty\.?$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) {
      final field = match.group(1) ?? match.group(2)!;
      return 'Please enter ${fieldLabel(field).toLowerCase()}.';
    }

    match = RegExp(
      r'^(\w+) must be a boolean value\.?$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) {
      return '${fieldLabel(match.group(1)!)} must be yes or no.';
    }

    match = RegExp(
      r'^(\w+) must be one of the following values: (.+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) {
      return '${fieldLabel(match.group(1)!)} has an invalid value. '
          'Please choose from the allowed options.';
    }

    return trimmed;
  }

  static String fieldLabel(String apiKey) {
    return _labels[apiKey] ?? _fallbackLabel(apiKey);
  }

  static String _fallbackLabel(String apiKey) {
    var label = apiKey;
    label = label.replaceAll('Min', ' minimum').replaceAll('Max', ' maximum');
    label = label.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)!.toLowerCase()}',
    );
    if (label.isEmpty) return apiKey;
    return label[0].toUpperCase() + label.substring(1);
  }

  static const _labels = {
    'heightMin': 'Minimum height',
    'heightMax': 'Maximum height',
    'lengthMin': 'Minimum length',
    'lengthMax': 'Maximum length',
    'widthMin': 'Minimum width',
    'widthMax': 'Maximum width',
    'thicknessMin': 'Minimum thickness',
    'thicknessMax': 'Maximum thickness',
    'weightMin': 'Minimum weight',
    'weightMax': 'Maximum weight',
    'caratMin': 'Minimum carat',
    'caratMax': 'Maximum carat',
    'caratWeightMin': 'Minimum carat weight',
    'caratWeightMax': 'Maximum carat weight',
    'totalPriceMin': 'Minimum total price',
    'totalPriceMax': 'Maximum total price',
    'pricePerCaratMin': 'Minimum price per carat',
    'pricePerCaratMax': 'Maximum price per carat',
    'pricePerGramMin': 'Minimum price per gram',
    'pricePerGramMax': 'Maximum price per gram',
    'stoneCaratMin': 'Minimum stone carat',
    'stoneCaratMax': 'Maximum stone carat',
    'chainLengthMin': 'Minimum chain length',
    'chainLengthMax': 'Maximum chain length',
    'approxWeightMin': 'Minimum approximate weight',
    'approxWeightMax': 'Maximum approximate weight',
    'caseSizeMin': 'Minimum case size',
    'caseSizeMax': 'Maximum case size',
    'yearMin': 'Minimum year',
    'yearMax': 'Maximum year',
    'quantity': 'Quantity',
    'stoneQuantity': 'Stone quantity',
    'certificateCompany': 'Certificate company',
    'gemstoneType': 'Gemstone type',
    'imageUrl': 'Image URL',
    'referenceImage': 'Reference image',
    'deliveryLocation': 'Delivery location',
    'subCategory': 'Sub-category',
    'diamondType': 'Diamond type',
    'growthProcess': 'Growth process',
    'colorMin': 'Minimum color grade',
    'colorMax': 'Maximum color grade',
    'clarityMin': 'Minimum clarity grade',
    'clarityMax': 'Maximum clarity grade',
    'metalType': 'Metal type',
    'metalFineness': 'Metal fineness',
    'metalPurity': 'Metal purity',
    'shapeFormat': 'Shape / format',
    'totalBudgetMin': 'Minimum budget',
    'totalBudgetMax': 'Maximum budget',
  };
}
