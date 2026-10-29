import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'agent_session.dart';
import 'llm_client.dart';
import 'tool_result.dart';

/// What a tool may use while executing.
class AgentToolContext {
  const AgentToolContext({
    required this.ref,
    required this.cancelToken,
    required this.userUtterances,
    this.session = AgentSession.guest,
    this.clock,
  });

  /// Read app repositories/providers. Prefer returning effects over
  /// mutating app state directly.
  final Ref ref;

  /// Cancelled when the user dismisses the agent mid-turn.
  final CancelToken cancelToken;

  /// Everything the user said in this session, oldest first — lets tools
  /// verify that a required slot was really stated, not guessed by the model.
  final List<String> userUtterances;

  /// Who is asking (signed in, seller, which side of the app).
  final AgentSession session;

  /// Fixed "now" for date windows ("today"); the device clock when null.
  final DateTime? clock;

  DateTime get now => clock ?? DateTime.now();
}

/// One capability the agent can invoke. Add a tool by implementing this
/// and listing it in `gem_agent_tools.dart`; nothing else changes.
abstract class AgentTool {
  const AgentTool();

  /// snake_case function name the model calls.
  String get name;

  /// When to use the tool, written for the model.
  String get description;

  /// JSON Schema of the arguments.
  Map<String, Object?> get parameters;

  /// Rules, vocabulary and examples merged into the system prompt while the
  /// tool is registered. Keep it terse; it is sent on every request.
  String get promptGuidance => '';

  /// Account the tool needs. Tools the session may not use are neither
  /// advertised to the model nor executed.
  AgentToolAccess get access => AgentToolAccess.public;

  /// Status line shown while the tool runs.
  String progressLabel(Map<String, Object?> args) => 'Working on it…';

  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  );

  LlmToolSpec get spec =>
      LlmToolSpec(name: name, description: description, parameters: parameters);
}
