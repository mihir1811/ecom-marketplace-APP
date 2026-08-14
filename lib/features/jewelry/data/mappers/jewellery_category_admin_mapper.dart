import '../../../../core/network/response_parser.dart';
import '../../domain/models/jewellery_category_admin.dart';

abstract final class JewelleryCategoryAdminMapper {
  static JewelleryCategoryAdmin fromJson(Map<String, dynamic> json) {
    final subsJson = json['subcategories'];
    final subs = <JewellerySubcategoryAdmin>[];
    if (subsJson is List) {
      for (final item in subsJson) {
        if (item is Map<String, dynamic>) {
          subs.add(subcategoryFromJson(item));
        }
      }
    }
    return JewelleryCategoryAdmin(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['isActive'] != false,
      imageUrl: _nullableString(json['imageUrl']),
      subcategories: subs,
    );
  }

  static JewellerySubcategoryAdmin subcategoryFromJson(
    Map<String, dynamic> json,
  ) {
    return JewellerySubcategoryAdmin(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      isActive: json['isActive'] != false,
      imageUrl: _nullableString(json['imageUrl']),
    );
  }

  static JewelleryCategoryAdmin? categoryFromResponse(
    Map<String, dynamic>? root,
  ) {
    final entity = ResponseParser.entity(root);
    return entity == null ? null : fromJson(entity);
  }

  static JewellerySubcategoryAdmin? subcategoryFromResponse(
    Map<String, dynamic>? root,
  ) {
    final entity = ResponseParser.entity(root);
    return entity == null ? null : subcategoryFromJson(entity);
  }

  static JewelleryCategoryListPage listPageFromJson(
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
    final items = <JewelleryCategoryAdmin>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final category = fromJson(item);
      if (category.id.isEmpty) continue;
      items.add(category);
    }

    final total = _asInt(meta['total']) ?? items.length;
    final currentPage = _asInt(meta['currentPage']) ?? page;
    final lastPage = _asInt(meta['lastPage']) ?? currentPage;
    final hasMore = meta.containsKey('next')
        ? meta['next'] != null
        : currentPage < lastPage;

    return JewelleryCategoryListPage(
      items: items,
      total: total,
      currentPage: currentPage,
      hasMore: hasMore,
    );
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String? _nullableString(Object? raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }
}
