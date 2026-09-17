import '../../../../core/utils/currency_rates.dart';
import '../../domain/models/refund_list_page.dart';
import '../../domain/models/refund_request.dart';

abstract final class RefundMapper {
  static RefundRequest fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json['createdAt']);
    final updatedAt = _parseDate(json['updatedAt']) ?? createdAt;
    final resolvedAt = _parseDate(json['resolvedAt']);

    // Refunds settle via Razorpay in INR — API `amount` is always INR.
    final amountInr = _asDouble(json['amountInr']) ??
        _asDouble(json['amount']) ??
        0;
    final amountUsd = _asDouble(json['amountUsd']) ??
        (amountInr > 0 ? inrToUsd(amountInr) : 0);

    return RefundRequest(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      sellerId: json['sellerId']?.toString() ?? '',
      status: RefundStatus.fromApi(json['status']?.toString()),
      reason: json['reason']?.toString() ?? '',
      amountInr: amountInr,
      amountUsd: amountUsd,
      sellerNote: _nullableString(json['sellerNote']),
      razorpayRefundId: _nullableString(json['razorpayRefundId']),
      createdAtLabel: _label(createdAt),
      updatedAtLabel: _label(updatedAt),
      resolvedAtLabel: resolvedAt != null ? _label(resolvedAt) : null,
      user: _userFromJson(json['user']),
      seller: _sellerFromJson(json['seller']),
    );
  }

  static RefundListPage listPageFromJson(
    Map<String, dynamic>? root, {
    required int page,
    required int limit,
  }) {
    final dataNode = root?['data'];
    final payload =
        dataNode is Map<String, dynamic> ? dataNode : const <String, dynamic>{};
    final itemsJson = payload['data'];
    final metaJson = payload['meta'];
    final meta =
        metaJson is Map<String, dynamic> ? metaJson : const <String, dynamic>{};

    final list = itemsJson is List ? itemsJson : const [];
    final items = <RefundRequest>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final refund = fromJson(item);
      if (refund.id.isEmpty) continue;
      items.add(refund);
    }

    final total = _asInt(meta['total']) ?? items.length;
    final currentPage = _asInt(meta['currentPage']) ?? page;
    final lastPage = _asInt(meta['lastPage']) ?? currentPage;
    final perPage = _asInt(meta['perPage']) ?? limit;
    final hasMore = meta.containsKey('next')
        ? meta['next'] != null
        : currentPage < lastPage;

    return RefundListPage(
      items: items,
      total: total,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      hasMore: hasMore,
    );
  }

  static RefundPartyUser? _userFromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return RefundPartyUser(
      id: raw['id']?.toString() ?? '',
      name: raw['name']?.toString() ?? '',
      profilePicture: _nullableString(raw['profilePicture']),
    );
  }

  static RefundPartySeller? _sellerFromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return RefundPartySeller(
      id: raw['id']?.toString() ?? '',
      companyName: _nullableString(raw['companyName']),
      companyLogo: _nullableString(raw['companyLogo']),
    );
  }

  static String? _nullableString(Object? raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static String _label(DateTime? date) {
    if (date == null) return '—';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}, '
        '${two(date.hour)}:${two(date.minute)}';
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
