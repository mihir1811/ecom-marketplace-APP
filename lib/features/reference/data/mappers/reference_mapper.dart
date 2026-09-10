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
    final List list;
    Map<String, dynamic> payload = const <String, dynamic>{};
    if (data is List) {
      list = data;
    } else if (data is Map) {
      payload = Map<String, dynamic>.from(data);
      final purchasesRaw =
          payload['purchases'] ?? payload['items'] ?? payload['results'];
      list = purchasesRaw is List ? purchasesRaw : const [];
    } else {
      list = const [];
    }

    final items = <ReferencePurchase>[];
    for (final item in list) {
      if (item is! Map) continue;
      final purchase = purchaseFromJson(Map<String, dynamic>.from(item));
      if (purchase.id.isEmpty) continue;
      items.add(purchase);
    }

    final meta = root?['meta'];
    final metaMap = meta is Map
        ? Map<String, dynamic>.from(meta)
        : const <String, dynamic>{};
    final pagination = metaMap['pagination'] ?? payload['pagination'];
    final pageMeta = pagination is Map
        ? Map<String, dynamic>.from(pagination)
        : const <String, dynamic>{};

    return ReferencePurchasePage(
      items: items,
      page: _asInt(pageMeta['page']) ?? page,
      limit: _asInt(pageMeta['limit']) ?? limit,
      total: _asInt(pageMeta['total']) ?? items.length,
      totalPages: _asInt(pageMeta['totalPages']) ?? 1,
    );
  }

  static ReferencePurchase purchaseFromJson(Map<String, dynamic> json) {
    final id =
        json['id']?.toString() ??
        json['_id']?.toString() ??
        json['orderId']?.toString() ??
        json['purchaseId']?.toString() ??
        '';

    final itemsRaw = json['items'];
    final parsedItems = <ReferencePurchaseItem>[];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final name = map['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        parsedItems.add(
          ReferencePurchaseItem(
            name: name,
            productType: map['productType']?.toString().trim() ?? '',
            quantity: _asInt(map['quantity']) ?? 1,
          ),
        );
      }
    }

    final buyerRaw = json['buyer'] ?? json['referredUser'] ?? json['user'];
    String? buyerLabel;
    if (buyerRaw is Map) {
      final buyer = Map<String, dynamic>.from(buyerRaw);
      final party = ReferenceParty(
        id: buyer['id']?.toString() ?? '',
        name: buyer['name']?.toString() ?? '',
        email: buyer['email']?.toString() ?? '',
        userName: buyer['userName']?.toString() ?? '',
        referralCode: buyer['referralCode']?.toString() ?? '',
      );
      final label = party.nameDotEmail.trim();
      buyerLabel = label.isEmpty ? null : label;
    }

    final productType =
        json['productType']?.toString() ??
        json['orderType']?.toString() ??
        (parsedItems.isNotEmpty ? parsedItems.first.productType : null);

    final String title;
    if (parsedItems.length == 1) {
      title = parsedItems.first.name;
    } else if (parsedItems.length > 1) {
      title = '${parsedItems.length} items · ${parsedItems.first.name}';
    } else {
      title =
          json['title']?.toString() ??
          json['productName']?.toString() ??
          json['name']?.toString() ??
          buyerLabel ??
          productType ??
          'Purchase';
    }

    final amount =
        _asDouble(
          json['commissionInr'] ??
              json['commissionAmount'] ??
              json['commissionAmountInr'] ??
              json['commission'] ??
              json['amount'] ??
              json['amountInr'] ??
              json['earnedAmount'] ??
              json['total'],
        ) ??
        0;
    final createdAt = _parseDate(
      json['commissionAt'] ??
          json['orderCreatedAt'] ??
          json['createdAt'] ??
          json['purchasedAt'] ??
          json['created_at'] ??
          json['date'],
    );

    return ReferencePurchase(
      id: id,
      label: title,
      amountLabel: AppCurrency.inr(amount),
      createdAtLabel: _label(createdAt),
      commissionInr: amount,
      commissionAt: createdAt,
      orderStatus: json['orderStatus']?.toString(),
      orderType: json['orderType']?.toString(),
      buyerLabel: buyerLabel,
      items: parsedItems,
      productType: productType,
      raw: json,
    );
  }

  static ReferenceParty? _partyFromJson(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return ReferenceParty(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      referralCode: map['referralCode']?.toString() ?? '',
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    if (raw is num) {
      final n = raw.toInt();
      // seconds vs milliseconds
      final ms = n < 100000000000 ? n * 1000 : n;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return _parseDate(map['\$date'] ?? map['date'] ?? map['value']);
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final asNum = num.tryParse(text);
    if (asNum != null) return _parseDate(asNum);
    return DateTime.tryParse(text)?.toLocal();
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
    var text = value.toString().trim();
    if (text.isEmpty) return null;
    text = text
        .replaceAll('₹', '')
        .replaceAll('\$', '')
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(text);
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
