import '../../domain/models/interested_buyer.dart';

abstract final class InterestedBuyerMapper {
  static InterestedBuyersPage pageFromJson(
    Map<String, dynamic>? root, {
    required int page,
  }) {
    final payload = _map(root?['data']) ?? const <String, dynamic>{};
    final list = payload['data'];
    final meta = _map(payload['meta']) ?? const <String, dynamic>{};
    final items = <InterestedBuyer>[
      if (list is List)
        for (final raw in list)
          if (_map(raw) case final row?)
            if (rowFromJson(row) case final buyer? when buyer.id.isNotEmpty)
              buyer,
    ];
    final currentPage = _int(meta['currentPage']) ?? page;
    final lastPage = _int(meta['lastPage']) ?? currentPage;
    return InterestedBuyersPage(
      items: items,
      summary: summaryFromJson(_map(payload['summary'])),
      total: _int(meta['total']) ?? items.length,
      currentPage: currentPage,
      hasMore: meta.containsKey('next')
          ? meta['next'] != null
          : currentPage < lastPage,
    );
  }

  static InterestedBuyersSummary summaryFromJson(Map<String, dynamic>? json) {
    if (json == null) return InterestedBuyersSummary.empty;
    return InterestedBuyersSummary(
      items: _int(json['items']) ?? 0,
      buyers: _int(json['buyers']) ?? 0,
      notContacted: _int(json['notContacted']) ?? 0,
      totalValue: _num(json['totalValue']) ?? 0,
    );
  }

  static InterestedBuyer? rowFromJson(Map<String, dynamic> json) {
    final product = _map(json['product']);
    if (product == null) return null;
    final last = _map(json['lastContact']);
    final lastKind = InterestedContactKind.fromApi(last?['kind']?.toString());
    final open = _map(json['openOffer']);
    final name = _string(json['buyerName']);
    return InterestedBuyer(
      id: json['id']?.toString() ?? '',
      buyerName: name ?? 'Buyer',
      addedAt: _date(json['addedAt']),
      quantity: _num(json['quantity']) ?? 0,
      lineTotal: _num(json['lineTotal']) ?? 0,
      product: InterestedProduct(
        id: product['id']?.toString() ?? '',
        type: product['type']?.toString() ?? '',
        title: _string(product['title']),
        image: _string(product['image']),
        stockNumber: _string(product['stockNumber']),
        minimumOfferPrice: _num(product['minimumOfferPrice']),
      ),
      lastContact: lastKind == null
          ? null
          : InterestedLastContact(kind: lastKind, at: _date(last?['at'])),
      nextContactAt: _date(json['nextContactAt']),
      buyerReplied: json['buyerReplied'] == true,
      chatPath: _string(json['chatPath']),
      openOffer: open == null
          ? null
          : InterestedOpenOffer(
              id: open['id']?.toString() ?? '',
              amount: _num(open['amount']) ?? 0,
              status: open['status']?.toString().toUpperCase() ?? 'PENDING',
              fromSeller: open['fromSeller'] == true,
              expiresAt: _date(open['expiresAt']),
            ),
      canMessage: json['canMessage'] == true,
      canOffer: json['canOffer'] == true,
      offerBlock: InterestedOfferBlock.fromApi(json['offerBlock']?.toString()),
    );
  }

  static Map<String, dynamic>? _map(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }

  static String? _string(Object? v) {
    if (v == null) return null;
    final t = v.toString().trim();
    return t.isEmpty ? null : t;
  }

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  static int? _int(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return v == null ? null : int.tryParse(v.toString());
  }

  /// Amounts stay [num]: a whole price like 950 arrives without a decimal.
  static num? _num(Object? v) {
    if (v is num) return v;
    return v == null ? null : num.tryParse(v.toString());
  }
}
