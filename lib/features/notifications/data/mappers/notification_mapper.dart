import '../../domain/models/app_notification.dart';
import '../../domain/models/notification_page.dart';

/// Maps notification JSON into domain models.
abstract final class NotificationMapper {
  static AppNotification fromJson(Map<String, dynamic> json) {
    final data = <String, String>{};
    final rawData = json['data'];
    if (rawData is Map) {
      for (final entry in rawData.entries) {
        final value = entry.value;
        if (value == null) continue;
        data[entry.key.toString()] = value.toString();
      }
    }

    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      imageUrl: _stringOrNull(json['imageUrl']),
      link: json['link']?.toString() ?? '',
      data: data,
      isRead: json['isRead'] == true,
      readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static NotificationPage pageFromEnvelope(
    Map<String, dynamic>? root, {
    required int page,
    required int limit,
  }) {
    final dataNode = root?['data'];
    final payload = dataNode is Map<String, dynamic>
        ? dataNode
        : const <String, dynamic>{};
    final itemsJson = payload['data'];
    final metaJson = payload['meta'];
    final meta = metaJson is Map<String, dynamic>
        ? metaJson
        : const <String, dynamic>{};

    final items = <AppNotification>[];
    if (itemsJson is List) {
      for (final item in itemsJson) {
        if (item is! Map) continue;
        final notification = fromJson(Map<String, dynamic>.from(item));
        if (notification.id.isEmpty) continue;
        items.add(notification);
      }
    }

    final total = _asInt(meta['total']) ?? items.length;
    final currentPage = _asInt(meta['currentPage']) ?? page;
    final lastPage = _asInt(meta['lastPage']) ?? currentPage;
    final perPage = _asInt(meta['perPage']) ?? limit;
    final hasMore = meta.containsKey('next')
        ? meta['next'] != null
        : currentPage < lastPage;

    return NotificationPage(
      items: items,
      total: total,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      hasMore: hasMore,
      unreadCount: _asInt(payload['unreadCount']) ?? 0,
    );
  }

  static int unreadCountFromEnvelope(Map<String, dynamic>? root) {
    final data = root?['data'];
    if (data is! Map) return 0;
    return _asInt(data['count']) ?? _asInt(data['unreadCount']) ?? 0;
  }

  static String? _stringOrNull(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return null;
    return text;
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
