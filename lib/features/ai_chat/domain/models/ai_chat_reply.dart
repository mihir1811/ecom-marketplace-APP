import 'ai_chat_message.dart';
import 'ai_chat_product.dart';

class AiChatReply {
  const AiChatReply({
    required this.reply,
    required this.sessionId,
    this.products = const [],
    this.productGroups = const [],
    this.totalFound = 0,
  });

  final String reply;
  final String sessionId;
  final List<AiChatProduct> products;
  final List<AiChatProductGroup> productGroups;
  final int totalFound;
}

class AiChatSessionSummary {
  const AiChatSessionSummary({
    required this.sessionId,
    required this.title,
    required this.preview,
    this.messageCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String sessionId;
  final String title;
  final String preview;
  final int messageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class AiChatSessionDetail {
  const AiChatSessionDetail({
    required this.sessionId,
    required this.title,
    this.messages = const [],
  });

  final String sessionId;
  final String title;
  final List<AiChatMessage> messages;
}
