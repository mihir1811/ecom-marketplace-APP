/// Helpers for APIs that return either `{ success, data }` or a raw entity.
abstract final class ResponseParser {
  static Map<String, dynamic>? entity(Map<String, dynamic>? root) {
    if (root == null || root.isEmpty) return null;
    final data = root['data'];
    if (root.containsKey('success') && data is Map<String, dynamic>) {
      return data;
    }
    if (root.containsKey('id')) return root;
    return null;
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
