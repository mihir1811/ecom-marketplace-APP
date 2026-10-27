/// Parsing helpers for marketplace payloads.
///
/// Catalogue records send decimals as strings (`"3799.14"`); quotes and
/// orders send numbers. These accept both.
abstract final class MarketplaceJson {
  static num? asNum(Object? v) => v is num ? v : num.tryParse('${v ?? ''}');

  static double money(Object? v) => (asNum(v) ?? 0).toDouble();

  static double? decimal(Object? v) => asNum(v)?.toDouble();

  static int asInt(Object? v, [int fallback = 0]) =>
      asNum(v)?.toInt() ?? fallback;

  static int? intOrNull(Object? v) => asNum(v)?.toInt();

  /// ISO timestamp → local time.
  static DateTime? date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  static Map<String, dynamic> obj(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, value) => MapEntry('$k', value));
    return const <String, dynamic>{};
  }

  static Map<String, String> strings(Object? v) => v is Map
      ? {
          for (final e in v.entries)
            if (e.value != null) '${e.key}': '${e.value}',
        }
      : const <String, String>{};

  static List<String> stringList(Object? v) => v is List
      ? [
          for (final e in v)
            if (e != null && '$e'.trim().isNotEmpty) '$e'.trim(),
        ]
      : const <String>[];

  static List<T> listOf<T>(
    Object? v,
    T Function(Map<String, dynamic> json) parse,
  ) => v is List
      ? [
          for (final e in v)
            if (e is Map) parse(obj(e)),
        ]
      : <T>[];

  /// Trimmed non-empty text, else null.
  static String? text(Object? v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  /// The envelope's `data`.
  static Object? data(Object? root) =>
      root is Map && root.containsKey('data') ? root['data'] : root;
}
