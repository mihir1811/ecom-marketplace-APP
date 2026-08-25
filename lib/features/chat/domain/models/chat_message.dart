import 'chat_product_type.dart';

enum ChatMessageType { text, image, pdf }

class ChatParticipant {
  const ChatParticipant({
    required this.id,
    required this.name,
    required this.role,
    this.profilePicture = '',
    this.companyLogo,
  });

  final String id;
  final String name;
  final String role;
  final String profilePicture;
  final String? companyLogo;

  String get displayAvatar =>
      (companyLogo != null && companyLogo!.trim().isNotEmpty)
          ? companyLogo!.trim()
          : profilePicture.trim();
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.body,
    required this.messageType,
    required this.createdAt,
    required this.isRead,
    required this.isMine,
    this.fileUrl,
    this.productId,
    this.productType,
    this.productNameHint = '',
    this.readAt,
    this.from,
    this.to,
    this.deletedBySender = false,
    this.deletedByReceiver = false,
  });

  final String id;
  final String fromId;
  final String toId;
  final String body;
  final String? fileUrl;
  final ChatMessageType messageType;
  final String? productId;
  final ChatProductType? productType;
  final String productNameHint;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final ChatParticipant? from;
  final ChatParticipant? to;
  final bool deletedBySender;
  final bool deletedByReceiver;
  final bool isMine;

  String peerId(String myUserId) => fromId == myUserId ? toId : fromId;

  ChatParticipant? peer(String myUserId) =>
      fromId == myUserId ? to : from;
}
