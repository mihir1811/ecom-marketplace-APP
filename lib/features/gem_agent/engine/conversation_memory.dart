import '../domain/agent_message.dart';

/// Session history sent to the model.
///
/// The window always starts on a user message so an assistant tool call is
/// never separated from its tool results (providers reject orphans).
class ConversationMemory {
  ConversationMemory({this.maxMessages = 24});

  final int maxMessages;
  final List<AgentMessage> _messages = [];

  int get length => _messages.length;

  void add(AgentMessage message) => _messages.add(message);

  /// Drops everything from [index] on (rolls back a failed turn).
  void truncate(int index) {
    if (index < _messages.length) {
      _messages.removeRange(index, _messages.length);
    }
  }

  void clear() => _messages.clear();

  List<String> get userUtterances => [
    for (final m in _messages)
      if (m.role == AgentRole.user && (m.content ?? '').isNotEmpty) m.content!,
  ];

  List<AgentMessage> window() {
    if (_messages.length <= maxMessages) return List.unmodifiable(_messages);
    var start = _messages.length - maxMessages;
    while (start < _messages.length &&
        _messages[start].role != AgentRole.user) {
      start++;
    }
    return List.unmodifiable(_messages.sublist(start));
  }
}
