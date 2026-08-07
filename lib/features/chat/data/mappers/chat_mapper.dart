import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_product_type.dart';
import '../../domain/models/chat_thread.dart';
import '../../domain/models/product_chat_context.dart';

abstract final class ChatMapper {
  static ChatMessage messageFromJson(
    Map<String, dynamic> json, {
    required String myUserId,
  }) {
    final fromId = json['fromId']?.toString() ?? '';
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
    final readAt = DateTime.tryParse(json['readAt']?.toString() ?? '');

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      fromId: fromId,
      toId: json['toId']?.toString() ?? '',
      body: json['message']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString(),
      messageType: _messageType(json['messageType']?.toString()),
      productId: json['productId']?.toString(),
      productType: ChatProductType.fromApi(json['productType']?.toString()),
      createdAt: createdAt,
      isRead: json['isRead'] == true,
      readAt: readAt,
      from: _participant(json['from']),
      to: _participant(json['to']),
      deletedBySender: json['deletedBySender'] == true,
      deletedByReceiver: json['deletedByReceiver'] == true,
      isMine: fromId.isNotEmpty && fromId == myUserId,
    );
  }

  static ProductChatContext contextFromJson(Map<String, dynamic> json) {
    final specsRaw = json['productSpecs'];
    final specs = <ProductChatSpec>[];
    if (specsRaw is List) {
      for (final item in specsRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final label = map['label']?.toString() ?? '';
        final value = map['value']?.toString() ?? '';
        if (label.isEmpty && value.isEmpty) continue;
        specs.add(ProductChatSpec(label: label, value: value));
      }
    }

    final imagesRaw = json['productImages'];
    final images = <String>[];
    if (imagesRaw is List) {
      for (final item in imagesRaw) {
        final url = item?.toString().trim() ?? '';
        if (url.isNotEmpty) images.add(url);
      }
    }

    final type = ChatProductType.fromApi(json['productType']?.toString()) ??
        ChatProductType.diamond;
    final priceRaw = json['productPrice'];
    double? price;
    if (priceRaw is num) {
      price = priceRaw.toDouble();
    } else if (priceRaw != null) {
      price = double.tryParse(priceRaw.toString());
    }

    return ProductChatContext(
      productId: json['productId']?.toString() ?? '',
      productType: type,
      productName: json['productName']?.toString() ?? '',
      sellerUserId: json['sellerUserId']?.toString() ?? '',
      sellerName: json['sellerName']?.toString() ?? '',
      sellerLogo: json['sellerLogo']?.toString(),
      productImages: images,
      productPrice: price,
      stockNumber: json['stockNumber']?.toString(),
      productSpecs: specs,
    );
  }

  static List<ChatThread> threadsFromMessages({
    required List<ChatMessage> messages,
    required String myUserId,
  }) {
    final map = <String, ChatThread>{};
    for (final msg in messages) {
      final productId = msg.productId;
      final productType = msg.productType;
      if (productId == null || productId.isEmpty || productType == null) {
        continue;
      }
      final peer = msg.peer(myUserId);
      final peerId = msg.peerId(myUserId);
      if (peerId.isEmpty) continue;

      final id = ChatThread.encodeId(
        productType: productType,
        productId: productId,
        peerUserId: peerId,
      );
      final existing = map[id];
      final preview = _preview(msg);
      final unreadBump =
          !msg.isMine && !msg.isRead ? 1 : 0;

      if (existing == null || msg.createdAt.isAfter(existing.lastMessageAt)) {
        map[id] = ChatThread(
          id: id,
          productId: productId,
          productType: productType,
          peerUserId: peerId,
          peerName: peer?.name.isNotEmpty == true ? peer!.name : 'Member',
          peerAvatar: peer?.displayAvatar ?? '',
          lastMessage: preview,
          lastMessageAt: msg.createdAt,
          unreadCount: (existing?.unreadCount ?? 0) + unreadBump,
          productNameHint: productType.label,
        );
      } else {
        map[id] = ChatThread(
          id: existing.id,
          productId: existing.productId,
          productType: existing.productType,
          peerUserId: existing.peerUserId,
          peerName: existing.peerName,
          peerAvatar: existing.peerAvatar,
          lastMessage: existing.lastMessage,
          lastMessageAt: existing.lastMessageAt,
          unreadCount: existing.unreadCount + unreadBump,
          productNameHint: existing.productNameHint,
        );
      }
    }

    final list = map.values.toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return list;
  }

  static ChatParticipant? _participant(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    String? companyLogo;
    final seller = map['seller'];
    if (seller is Map) {
      companyLogo = seller['companyLogo']?.toString();
    }
    return ChatParticipant(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      profilePicture: map['profilePicture']?.toString() ?? '',
      companyLogo: companyLogo,
    );
  }

  static ChatMessageType _messageType(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'IMAGE':
        return ChatMessageType.image;
      case 'PDF':
        return ChatMessageType.pdf;
      default:
        return ChatMessageType.text;
    }
  }

  static String _preview(ChatMessage msg) {
    switch (msg.messageType) {
      case ChatMessageType.image:
        return msg.body.trim().isEmpty ? 'Photo' : msg.body.trim();
      case ChatMessageType.pdf:
        return msg.body.trim().isEmpty ? 'Document' : msg.body.trim();
      case ChatMessageType.text:
        return msg.body.trim();
    }
  }
}
