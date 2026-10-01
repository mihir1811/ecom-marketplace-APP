import '../../../chat/domain/models/chat_message.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/models/notification_page.dart';

/// Maps notification JSON into domain models.
abstract final class NotificationMapper {
  /// Banner for a message that arrived on the chat socket. Uses the same
  /// `type` and data keys as a `CHAT_MESSAGE` push, so taps route the same
  /// way and the push copy of the message is recognised as a duplicate.
  static AppNotification fromChatMessage(ChatMessage message) {
    final sender = message.from?.name.trim() ?? '';
    final text = message.body.trim();
    final productType = message.productType?.apiValue;
    return AppNotification(
      id: '',
      type: 'CHAT_MESSAGE',
      title: sender.isEmpty ? 'New message' : sender,
      body: text.isNotEmpty
          ? text
          : switch (message.messageType) {
              ChatMessageType.image => 'Sent you a photo',
              ChatMessageType.pdf => 'Sent you a document',
              ChatMessageType.text => 'Sent you a message',
            },
      link: '',
      data: {
        'senderId': message.fromId,
        'messageId': message.id,
        'productId': ?message.productId,
        'productType': ?productType,
        'threadId': 'chat_${message.fromId}_${message.productId ?? ''}',
      },
      isRead: false,
      createdAt: message.createdAt,
    );
  }

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

  /// Builds an unread inbox row from an FCM message.
  ///
  /// [data] is the FCM `data` block (`notificationId`, `type`, `link`, entity
  /// ids); [title] and [body] come from the `notification` block, falling back
  /// to same-named data keys for data-only pushes.
  static AppNotification fromPush(
    Map<String, dynamic> data, {
    String? title,
    String? body,
    String? imageUrl,
    DateTime? sentTime,
  }) {
    final values = <String, String>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if (value == null) continue;
      values[entry.key] = value.toString();
    }
    return AppNotification(
      id: values['notificationId'] ?? '',
      type: values['type'] ?? '',
      title: _stringOrNull(title) ?? values['title'] ?? '',
      body: _stringOrNull(body) ?? values['body'] ?? '',
      imageUrl: _stringOrNull(imageUrl) ?? _stringOrNull(values['imageUrl']),
      link: values['link'] ?? '',
      data: values,
      isRead: false,
      createdAt: sentTime ?? DateTime.now(),
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
