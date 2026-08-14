/// Helpers for APIs that return either `{ success, data }` or a raw entity.
abstract final class ResponseParser {
  static Map<String, dynamic>? asMap(Object? value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  static Map<String, dynamic>? entity(Map<String, dynamic>? root) {
    if (root == null || root.isEmpty) return null;

    var data = asMap(root['data']);
    if (data != null) {
      final nested = asMap(data['data']);
      if (nested != null && _looksLikeEntity(nested) && !_looksLikeEntity(data)) {
        data = nested;
      }
      final user = asMap(data['user']) ?? asMap(data['profile']);
      if (user != null && _looksLikeEntity(user)) {
        return {...data, ...user};
      }
      if (data.isNotEmpty) return data;
    }

    if (_looksLikeEntity(root)) return root;
    return null;
  }

  static bool _looksLikeEntity(Map<String, dynamic> map) {
    return map.containsKey('id') ||
        map.containsKey('_id') ||
        map.containsKey('userId') ||
        map.containsKey('email') ||
        map.containsKey('userName') ||
        map.containsKey('username') ||
        map.containsKey('name');
  }

  static List<Map<String, dynamic>> list(Map<String, dynamic>? root) {
    if (root == null) return const [];
    final data = root['data'];
    if (data is List) {
      return [
        for (final item in data)
          if (item is Map<String, dynamic>) item,
      ];
    }
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is List) {
        return [
          for (final item in nested)
            if (item is Map<String, dynamic>) item,
        ];
      }
    }
    return const [];
  }
}
