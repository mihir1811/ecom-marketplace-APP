import '../../domain/models/fee_rule.dart';

abstract final class FeeRuleMapper {
  static FeeRulesCatalog catalogFromJson(Map<String, dynamic>? root) {
    final data = root?['data'];
    final list = data is List ? data : const [];
    final rules = <FeeRule>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final rule = fromJson(item);
      if (rule.id.isEmpty) continue;
      rules.add(rule);
    }

    final configured = root?['configuredFeeTypes'];
    final types = <String>[];
    if (configured is List) {
      for (final t in configured) {
        final s = t?.toString().trim();
        if (s != null && s.isNotEmpty) types.add(s);
      }
    }

    return FeeRulesCatalog(rules: rules, configuredFeeTypes: types);
  }

  static FeeRule fromJson(Map<String, dynamic> json) {
    final categoriesRaw = json['productCategories'];
    final categories = <String>[];
    if (categoriesRaw is List) {
      for (final c in categoriesRaw) {
        final s = c?.toString().trim();
        if (s != null && s.isNotEmpty) categories.add(s);
      }
    }

    return FeeRule(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      feeType: FeeType.fromApi(json['feeType']?.toString()),
      valueType: FeeValueType.fromApi(json['valueType']?.toString()),
      value: _asDouble(json['value']) ?? 0,
      productCategories: categories,
      minCartValueInr: _asDouble(json['minCartValueInr']),
      maxCartValueInr: _asDouble(json['maxCartValueInr']),
      priority: _asInt(json['priority']) ?? 0,
      isActive: json['isActive'] != false,
    );
  }

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
