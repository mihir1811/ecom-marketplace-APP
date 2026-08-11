import '../../domain/models/recently_viewed.dart';

abstract final class RecentlyViewedMapper {
  static RecentlyViewedEntry fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final productMap = product is Map<String, dynamic> ? product : null;

    return RecentlyViewedEntry(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productType: json['productType']?.toString() ?? '',
      viewedAtLabel: _label(_parseDate(json['viewedAt'] ?? json['createdAt'])),
      stockNumber: _nullableString(productMap?['stockNumber']),
      productTitle: _nullableString(productMap?['title']) ??
          _nullableString(productMap?['name']),
    );
  }

  static RecentlyViewedListPage listPageFromJson(
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
    final items = <RecentlyViewedEntry>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final entry = fromJson(item);
      if (entry.id.isEmpty) continue;
      items.add(entry);
    }

    final total = _asInt(meta['total']) ?? items.length;
    final currentPage = _asInt(meta['currentPage']) ?? page;
    final lastPage = _asInt(meta['lastPage']) ?? currentPage;
    final hasMore = meta.containsKey('next')
        ? meta['next'] != null
        : currentPage < lastPage;

    return RecentlyViewedListPage(
      items: items,
      total: total,
      currentPage: currentPage,
      hasMore: hasMore,
    );
  }

  static RecentlyViewedId idFromJson(Map<String, dynamic> json) {
    return RecentlyViewedId(
      productId: json['productId']?.toString() ?? '',
      productType: json['productType']?.toString() ?? '',
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
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
