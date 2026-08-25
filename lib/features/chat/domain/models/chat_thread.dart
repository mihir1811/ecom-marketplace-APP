import 'chat_message.dart';
import 'chat_product_type.dart';

class ChatThread {
  const ChatThread({
    required this.id,
    required this.productId,
    required this.productType,
    required this.peerUserId,
    required this.peerName,
    required this.lastMessage,
    required this.lastMessageAt,
    this.peerAvatar = '',
    this.unreadCount = 0,
    this.productNameHint = '',
  });

  /// Encoded as `productType~productId~peerUserId`.
  final String id;
  final String productId;
  final ChatProductType productType;
  final String peerUserId;
  final String peerName;
  final String peerAvatar;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final String productNameHint;

  /// User-facing listing line (never a raw product UUID).
  String get listingLabel {
    final hint = productNameHint.trim();
    if (hint.isEmpty || hint.toLowerCase() == productType.label.toLowerCase()) {
      return productType.label;
    }
    return '${productType.label} · $hint';
  }

  static String encodeId({
    required ChatProductType productType,
    required String productId,
    required String peerUserId,
  }) =>
      '${productType.apiValue}~$productId~$peerUserId';

  static ({
    ChatProductType productType,
    String productId,
    String peerUserId,
  })? decodeId(String id) {
    final parts = id.split('~');
    if (parts.length != 3) return null;
    final type = ChatProductType.fromApi(parts[0]);
    if (type == null) return null;
    if (parts[1].isEmpty || parts[2].isEmpty) return null;
    return (
      productType: type,
      productId: parts[1],
      peerUserId: parts[2],
    );
  }
}

class ChatMessageListPage {
  const ChatMessageListPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.hasMore,
  });

  final List<ChatMessage> items;
  final int total;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final bool hasMore;
}
