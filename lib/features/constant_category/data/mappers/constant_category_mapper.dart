import '../../domain/models/constant_category.dart';

abstract final class ConstantCategoryMapper {
  static ConstantCategoryEntry fromJson(Map<String, dynamic> json) {
    final valueJson = json['value'];
    final values = <Map<String, dynamic>>[];
    if (valueJson is List) {
      for (final item in valueJson) {
        if (item is Map<String, dynamic>) values.add(item);
      }
    }

    return ConstantCategoryEntry(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      values: values,
      createdAtLabel: _label(_parseDate(json['createdAt'])),
      updatedAtLabel: _label(_parseDate(json['updatedAt'])),
    );
  }

  static ConstantCategoryListPage listPageFromJson(
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
    final items = <ConstantCategoryEntry>[];
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

    return ConstantCategoryListPage(
      items: items,
      total: total,
      currentPage: currentPage,
      hasMore: hasMore,
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static String? _label(DateTime? date) {
    if (date == null) return null;
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
