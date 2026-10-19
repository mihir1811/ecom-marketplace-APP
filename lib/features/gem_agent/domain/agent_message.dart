import 'dart:convert';

/// Speaker of one conversation entry, mirroring LLM chat roles.
enum AgentRole { user, assistant, tool }

/// A tool invocation requested by the model.
class AgentToolCall {
  const AgentToolCall({
    required this.id,
    required this.name,
    required this.rawArguments,
  });

  final String id;
  final String name;

  /// JSON object text exactly as the model produced it.
  final String rawArguments;

  /// Decoded arguments, or null when the model sent malformed JSON.
  Map<String, Object?>? decodeArguments() {
    final text = rawArguments.trim();
    if (text.isEmpty) return const {};
    try {
      final decoded = jsonDecode(text);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } on FormatException {
      return null;
    }
  }
}

/// One provider-neutral conversation entry kept in agent memory.
class AgentMessage {
  const AgentMessage._({
    required this.role,
    this.content,
    this.toolCalls = const [],
    this.toolCallId,
    this.toolName,
  });

  factory AgentMessage.user(String text) =>
      AgentMessage._(role: AgentRole.user, content: text);

  factory AgentMessage.assistant(
    String? text, {
    List<AgentToolCall> toolCalls = const [],
  }) => AgentMessage._(
    role: AgentRole.assistant,
    content: text,
    toolCalls: toolCalls,
  );

  factory AgentMessage.tool({
    required String callId,
    required String name,
    required String content,
  }) => AgentMessage._(
    role: AgentRole.tool,
    content: content,
    toolCallId: callId,
    toolName: name,
  );

  final AgentRole role;
  final String? content;
  final List<AgentToolCall> toolCalls;
  final String? toolCallId;
  final String? toolName;
}
