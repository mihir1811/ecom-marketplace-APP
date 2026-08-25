import '../../../../core/utils/app_currency.dart';
import '../../domain/models/reference_models.dart';

abstract final class ReferenceMapper {
  static ReferenceProfile profileFromJson(Map<String, dynamic> json) {
    final historyRaw = json['outboundHistory'];
    final history = <ReferenceRequest>[];
    if (historyRaw is List) {
      for (final item in historyRaw) {
        if (item is! Map<String, dynamic>) continue;
        final req = requestFromJson(item);
        if (req.id.isEmpty) continue;
        history.add(req);
      }
    }

    final activeRaw = json['activeOutbound'];
    ReferenceRequest? active;
    if (activeRaw is Map<String, dynamic>) {
      active = requestFromJson(activeRaw);
      if (active.id.isEmpty) active = null;
    }

    return ReferenceProfile(
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      referralCode: json['referralCode']?.toString() ?? '',
      shareRegisterUrl: json['shareRegisterUrl']?.toString() ?? '',
      inboundPendingCount: _asInt(json['inboundPendingCount']) ?? 0,
      inboundAcceptedCount: _asInt(json['inboundAcceptedCount']) ?? 0,
      totalCommissionEarned: _asDouble(json['totalCommissionEarned']) ?? 0,
      activeOutbound: active,
      outboundHistory: history,
    );
  }

  static ReferenceRequest requestFromJson(Map<String, dynamic> json) {
    final party = _partyFromJson(
      json['referrer'] ??
          json['requester'] ??
          json['referred'] ??
          json['user'] ??
          json['referredUser'],
    );
    final createdAt = _parseDate(json['createdAt']);
    final acceptedAt = _parseDate(json['acceptedAt']);

    return ReferenceRequest(
      id: json['id']?.toString() ?? '',
      status: ReferenceStatus.fromApi(json['status']?.toString()),
      createdAtLabel: _label(createdAt),
      acceptedAtLabel: acceptedAt != null ? _label(acceptedAt) : null,
      party: party,
    );
  }

  static List<ReferenceRequest> requestListFromJson(Object? data) {
    if (data is! List) return const [];
    final items = <ReferenceRequest>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final req = requestFromJson(item);
      if (req.id.isEmpty) continue;
      items.add(req);
    }
    return items;
  }

  static ReferencePurchasePage purchasesFromJson(
    Map<String, dynamic>? root, {
    required int page,
    required int limit,
  }) {
    final data = root?['data'];
    final payload = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final purchasesRaw = payload['purchases'];
    final list = purchasesRaw is List ? purchasesRaw : const [];
    final items = <ReferencePurchase>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final purchase = purchaseFromJson(item);
      if (purchase.id.isEmpty) continue;
      items.add(purchase);
    }

    final meta = root?['meta'];
    final metaMap = meta is Map<String, dynamic> ? meta : const <String, dynamic>{};
    final pagination = metaMap['pagination'];
    final pageMeta =
        pagination is Map<String, dynamic> ? pagination : const <String, dynamic>{};

    return ReferencePurchasePage(
      items: items,
      page: _asInt(pageMeta['page']) ?? page,
      limit: _asInt(pageMeta['limit']) ?? limit,
      total: _asInt(pageMeta['total']) ?? items.length,
      totalPages: _asInt(pageMeta['totalPages']) ?? 1,
    );
  }

  static ReferencePurchase purchaseFromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ??
        json['orderId']?.toString() ??
        json['purchaseId']?.toString() ??
        '';
    final productType = json['productType']?.toString();
    final title = json['title']?.toString() ??
        json['productName']?.toString() ??
        json['name']?.toString() ??
        productType ??
        'Purchase';
    final amount = _asDouble(
      json['commissionAmount'] ??
          json['commission'] ??
          json['amount'] ??
          json['total'] ??
          json['price'],
    );
    final createdAt = _parseDate(json['createdAt'] ?? json['purchasedAt']);

    return ReferencePurchase(
      id: id,
      label: title,
      amountLabel: amount == null ? '—' : AppCurrency.inr(amount),
      createdAtLabel: _label(createdAt),
      productType: productType,
      raw: json,
    );
  }

  static ReferenceParty? _partyFromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return ReferenceParty(
      id: raw['id']?.toString() ?? '',
      name: raw['name']?.toString() ?? '',
      email: raw['email']?.toString() ?? '',
      userName: raw['userName']?.toString() ?? '',
      referralCode: raw['referralCode']?.toString() ?? '',
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  static String _label(DateTime? value) {
    if (value == null) return '—';
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
