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

  static String? _nullableString(Object? raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }
}
