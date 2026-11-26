/// `CHAT_SEND_BLOCKED` socket event: the server dropped the seller's
/// message because they contacted this buyer from Interested buyers and the
/// buyer has not written back yet. Nothing was saved or delivered.
class ChatSendBlocked {
  const ChatSendBlocked({
    required this.code,
    required this.message,
    required this.toId,
    this.productId,
  });

  /// e.g. `CART_OUTREACH_AWAITING_REPLY`.
  final String code;

  /// Text to show above the composer.
  final String message;

  /// The buyer the message was for.
  final String toId;
  final String? productId;

  static ChatSendBlocked? fromJson(Map<String, dynamic> json) {
    final toId = json['toId']?.toString().trim() ?? '';
    if (toId.isEmpty) return null;
    final message = json['message']?.toString().trim() ?? '';
    final productId = json['productId']?.toString().trim();
    return ChatSendBlocked(
      code: json['code']?.toString().trim() ?? '',
      message: message.isEmpty
          ? 'You can send another message after this buyer replies to you.'
          : message,
      toId: toId,
      productId: productId == null || productId.isEmpty ? null : productId,
    );
  }
}
