enum PromotionType {
  percentage('PERCENTAGE', 'Percentage'),
  fixedAmount('FIXED_AMOUNT', 'Fixed amount');

  const PromotionType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static PromotionType fromApi(String? raw) {
    for (final type in PromotionType.values) {
      if (type.apiValue == raw) return type;
    }
    return PromotionType.percentage;
  }
}

class Discount {
  const Discount({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    required this.startDateLabel,
    required this.endDateLabel,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String description;
  final PromotionType type;
  final String value;
  final String startDateLabel;
  final String endDateLabel;
  final bool isActive;
}

class PromoCode {
  const PromoCode({
    required this.id,
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    required this.startDateLabel,
    required this.endDateLabel,
    this.maxUses,
    this.usedCount,
    this.isActive = true,
  });

  final String id;
  final String code;
  final String description;
  final PromotionType type;
  final String value;
  final String startDateLabel;
  final String endDateLabel;
  final int? maxUses;
  final int? usedCount;
  final bool isActive;
}

class DiscountInput {
  const DiscountInput({
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    required this.startDate,
    required this.endDate,
  });

  final String name;
  final String description;
  final PromotionType type;
  final num value;
  final DateTime startDate;
  final DateTime endDate;

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'description': description.trim(),
        'type': type.apiValue,
        'value': value,
        'startDate': _isoDate(startDate),
        'endDate': _isoDate(endDate),
      };

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class PromoCodeInput {
  const PromoCodeInput({
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    required this.startDate,
    required this.endDate,
    this.maxUses,
  });

  final String code;
  final String description;
  final PromotionType type;
  final num value;
  final DateTime startDate;
  final DateTime endDate;
  final int? maxUses;

  Map<String, dynamic> toJson() => {
        'code': code.trim(),
        'description': description.trim(),
        'type': type.apiValue,
        'value': value,
        'startDate': DiscountInput._isoDate(startDate),
        'endDate': DiscountInput._isoDate(endDate),
        if (maxUses != null) 'maxUses': maxUses,
      };
}

class PublicPromotions {
  const PublicPromotions({
    required this.discounts,
    required this.promoCodes,
  });

  final List<Discount> discounts;
  final List<PromoCode> promoCodes;
}
