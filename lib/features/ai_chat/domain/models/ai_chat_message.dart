import 'ai_chat_product.dart';

enum AiChatRole {
  user,
  assistant;

  String get apiValue => name;

  static AiChatRole fromApi(String? value) {
    return value == 'assistant' ? AiChatRole.assistant : AiChatRole.user;
  }
}

class AiChatHistoryTurn {
  const AiChatHistoryTurn({required this.role, required this.content});

  final AiChatRole role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role.apiValue, 'content': content};
}

class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.imageUrls = const [],
    this.products = const [],
    this.productGroups = const [],
    this.totalFound,
    this.createdAt,
    this.isLocal = false,
    this.sourceQuery = '',
  });

  final String id;
  final AiChatRole role;
  final String content;
  final List<String> imageUrls;
  final List<AiChatProduct> products;
  final List<AiChatProductGroup> productGroups;
  final int? totalFound;
  final DateTime? createdAt;
  final bool isLocal;

  /// User text that produced this assistant reply (for “See more” filters).
  final String sourceQuery;

  AiChatHistoryTurn toHistoryTurn() =>
      AiChatHistoryTurn(role: role, content: content);
}
