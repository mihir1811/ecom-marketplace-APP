/// One row from the notifications inbox.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.link,
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.imageUrl,
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String? imageUrl;

  /// Website path or absolute https URL. May be empty.
  final String link;
  final Map<String, String> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead, DateTime? readAt}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
      link: link,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
