import '../../domain/models/api_share.dart';

abstract final class ApiShareMapper {
  static ApiShareKey keyFromJson(Map<String, dynamic> json) {
    return ApiShareKey(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      apiKey: json['apiKey']?.toString() ?? '',
      permissions: ApiSharePermission.parseList(json['permissions'] as List?),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }

  static List<ApiShareKey> keysFromRoot(Map<String, dynamic>? root) {
    final data = root?['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => keyFromJson(Map<String, dynamic>.from(e)))
        .where((k) => k.id.isNotEmpty)
        .toList();
  }

  static ApiShareData dataFromJson(Map<String, dynamic> json) {
    final diamondsRaw = json['diamonds'];
    final diamonds = <Map<String, dynamic>>[];
    if (diamondsRaw is List) {
      for (final item in diamondsRaw) {
        if (item is Map) {
          diamonds.add(Map<String, dynamic>.from(item));
        }
      }
    }
    return ApiShareData(
      ownerId: json['ownerId']?.toString() ?? '',
      permissions: ApiSharePermission.parseList(json['permissions'] as List?),
      diamonds: diamonds,
    );
  }

  static DateTime? _date(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
