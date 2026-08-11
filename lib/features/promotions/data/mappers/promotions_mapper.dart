import '../../../../core/network/response_parser.dart';
import '../../domain/models/promotion.dart';

abstract final class PromotionsMapper {
  static Discount discountFromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: PromotionType.fromApi(json['type']?.toString()),
      value: json['value']?.toString() ?? '',
      startDateLabel: _dateLabel(json['startDate']),
      endDateLabel: _dateLabel(json['endDate']),
      isActive: json['isActive'] != false,
    );
  }

  static PromoCode promoCodeFromJson(Map<String, dynamic> json) {
    return PromoCode(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: PromotionType.fromApi(json['type']?.toString()),
      value: json['value']?.toString() ?? '',
      startDateLabel: _dateLabel(json['startDate']),
      endDateLabel: _dateLabel(json['endDate']),
      maxUses: _asInt(json['maxUses']),
      usedCount: _asInt(json['usedCount']),
      isActive: json['isActive'] != false,
    );
  }

  static List<Discount> discountsFromRoot(Map<String, dynamic>? root) {
    final data = root?['data'];
    if (data is List) {
      return [
        for (final item in data)
          if (item is Map<String, dynamic>) discountFromJson(item),
      ];
    }
    return const [];
  }

  static List<PromoCode> promoCodesFromRoot(Map<String, dynamic>? root) {
    final data = root?['data'];
    if (data is List) {
      return [
        for (final item in data)
          if (item is Map<String, dynamic>) promoCodeFromJson(item),
      ];
    }
    return const [];
  }

  static Discount? discountFromResponse(Map<String, dynamic>? root) {
    final entity = ResponseParser.entity(root);
    return entity == null ? null : discountFromJson(entity);
  }

  static PromoCode? promoCodeFromResponse(Map<String, dynamic>? root) {
    final entity = ResponseParser.entity(root);
    return entity == null ? null : promoCodeFromJson(entity);
  }

  static PublicPromotions publicFromRoot(Map<String, dynamic>? root) {
    final data = root?['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final discountsJson = map['discounts'];
    final promoCodesJson = map['promoCodes'];
    final discounts = <Discount>[];
    final promoCodes = <PromoCode>[];
    if (discountsJson is List) {
      for (final item in discountsJson) {
        if (item is Map<String, dynamic>) {
          discounts.add(discountFromJson(item));
        }
      }
    }
    if (promoCodesJson is List) {
      for (final item in promoCodesJson) {
        if (item is Map<String, dynamic>) {
          promoCodes.add(promoCodeFromJson(item));
        }
      }
    }
    return PublicPromotions(discounts: discounts, promoCodes: promoCodes);
  }

  static String _dateLabel(Object? raw) {
    final date = raw == null ? null : DateTime.tryParse(raw.toString());
    if (date == null) return raw?.toString() ?? '—';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.month)}/${two(date.day)}/${date.year}';
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
