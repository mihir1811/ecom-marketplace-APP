enum FeeType {
  gst('GST'),
  transactionFee('TRANSACTION_FEE'),
  deliveryFee('DELIVERY_FEE'),
  referralCommission('REFERRAL_COMMISSION'),
  platformFee('PLATFORM_FEE'),
  gemworldVerification('GEMWORLD_VERIFICATION'),
  unknown('UNKNOWN');

  const FeeType(this.apiValue);
  final String apiValue;

  static FeeType fromApi(String? raw) {
    for (final type in FeeType.values) {
      if (type.apiValue == raw) return type;
    }
    return FeeType.unknown;
  }
}

enum FeeValueType {
  percentage('PERCENTAGE'),
  fixed('FIXED'),
  unknown('UNKNOWN');

  const FeeValueType(this.apiValue);
  final String apiValue;

  static FeeValueType fromApi(String? raw) {
    for (final type in FeeValueType.values) {
      if (type.apiValue == raw) return type;
    }
    return FeeValueType.unknown;
  }

  bool get isPercentage => this == FeeValueType.percentage;
  bool get isFixed => this == FeeValueType.fixed;
}

class FeeRule {
  const FeeRule({
    required this.id,
    required this.name,
    required this.feeType,
    required this.valueType,
    required this.value,
    required this.productCategories,
    required this.priority,
    required this.isActive,
    this.minCartValueInr,
    this.maxCartValueInr,
  });

  final String id;
  final String name;
  final FeeType feeType;
  final FeeValueType valueType;
  final double value;
  final List<String> productCategories;
  final double? minCartValueInr;
  final double? maxCartValueInr;
  final int priority;
  final bool isActive;

  /// Percent points → fraction (`2.36` → `0.0236`).
  double get rateFraction => value / 100.0;

  bool appliesToCategory(String productType) {
    if (productCategories.isEmpty) return true;
    final normalized = productType.trim();
    return productCategories.any(
      (c) => c.toLowerCase() == normalized.toLowerCase(),
    );
  }

  bool appliesToCartValueInr(double cartInr) {
    final min = minCartValueInr;
    final max = maxCartValueInr;
    if (min != null && cartInr < min) return false;
    if (max != null && cartInr > max) return false;
    return true;
  }
}

class FeeRulesCatalog {
  const FeeRulesCatalog({
    this.rules = const [],
    this.configuredFeeTypes = const [],
    this.isFromApi = false,
  });

  final List<FeeRule> rules;
  final List<String> configuredFeeTypes;

  /// True when this catalog came from a successful `GET /fees` response.
  /// When true, missing fee types charge `0` (no local hardcoded fallbacks).
  final bool isFromApi;

  static const empty = FeeRulesCatalog();

  bool get isEmpty => rules.isEmpty;

  List<FeeRule> ofType(FeeType type) =>
      rules.where((r) => r.isActive && r.feeType == type).toList();

  /// True when GET /fees currently exposes an active GemWorld verification rule.
  bool get offersGemworldVerification =>
      ofType(FeeType.gemworldVerification).isNotEmpty;

  /// Verification percent points from the active rule (`1` → 1%), else 0.
  double get gemworldVerificationPercent {
    final rules = ofType(FeeType.gemworldVerification)
        .where((r) => r.valueType.isPercentage);
    if (rules.isEmpty) return 0;
    return rules.first.value;
  }
}
