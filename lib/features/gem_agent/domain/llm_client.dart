import 'package:dio/dio.dart';

import '../../../core/error/result.dart';
import 'agent_message.dart';

/// Function schema advertised to the model.
class LlmToolSpec {
  const LlmToolSpec({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;

  /// JSON Schema object describing the arguments.
  final Map<String, Object?> parameters;
}

/// One completion request: system prompt, history and available tools.
class LlmRequest {
  const LlmRequest({
    required this.systemPrompt,
    required this.messages,
    this.tools = const [],
  });

  final String systemPrompt;
  final List<AgentMessage> messages;
  final List<LlmToolSpec> tools;
}

/// Model turn: free text, tool calls, or both.
class LlmResponse {
  const LlmResponse({this.text, this.toolCalls = const []});

  final String? text;
  final List<AgentToolCall> toolCalls;
}

enum LlmFailureKind {
  notConfigured,
  unauthorized,
  modelUnavailable,
  rateLimited,
  offline,
  cancelled,
  server,
  invalidResponse,
}

/// User-safe LLM failure. Raw provider errors never leave the client.
class LlmFailure {
  const LlmFailure(this.kind, this.message);

  final LlmFailureKind kind;
  final String message;

  bool get isCancelled => kind == LlmFailureKind.cancelled;
}

/// Provider-agnostic chat model. Swap implementations (OpenAI, proxy,
/// another vendor, a fake in tests) without touching the engine or tools.
abstract interface class LlmClient {
  Future<Result<LlmResponse, LlmFailure>> complete(
    LlmRequest request, {
    CancelToken? cancelToken,
  });
}
