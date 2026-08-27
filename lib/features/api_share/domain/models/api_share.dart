/// Permission values accepted by generate / update API share DTOs.
enum ApiSharePermission {
  hold('HOLD'),
  sell('SELL'),
  insert('INSERT'),
  update('UPDATE');

  const ApiSharePermission(this.apiValue);

  final String apiValue;

  static ApiSharePermission? tryParse(String? raw) {
    final value = raw?.trim().toUpperCase();
    if (value == null || value.isEmpty) return null;
    for (final p in ApiSharePermission.values) {
      if (p.apiValue == value) return p;
    }
    return null;
  }

  static List<ApiSharePermission> parseList(Iterable<dynamic>? raw) {
    if (raw == null) return const [];
    final out = <ApiSharePermission>[];
    for (final item in raw) {
      final parsed = tryParse(item?.toString());
      if (parsed != null && !out.contains(parsed)) out.add(parsed);
    }
    return out;
  }
}

/// Seller-owned shared API key (`GET/POST/PATCH /api-share`).
class ApiShareKey {
  const ApiShareKey({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.apiKey,
    required this.permissions,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String email;
  final String apiKey;
  final List<ApiSharePermission> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get maskedApiKey {
    final key = apiKey.trim();
    if (key.length <= 8) return key;
    return '••••${key.substring(key.length - 8)}';
  }

  ApiShareKey copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? apiKey,
    List<ApiSharePermission>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiShareKey(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      apiKey: apiKey ?? this.apiKey,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Public inventory snapshot for a valid `apiKey` (`GET /api-share/data`).
class ApiShareData {
  const ApiShareData({
    required this.ownerId,
    required this.permissions,
    required this.diamonds,
  });

  final String ownerId;
  final List<ApiSharePermission> permissions;
  final List<Map<String, dynamic>> diamonds;
}
