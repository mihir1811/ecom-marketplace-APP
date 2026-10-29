import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/auth_token_store.dart';
import '../data/gem_agent_config.dart';
import '../data/openai_chat_client.dart';
import '../domain/llm_client.dart';
import '../engine/agent_engine.dart';
import '../engine/conversation_memory.dart';
import '../engine/tool_registry.dart';
import '../tools/gem_agent_tools.dart';
import 'speech_input_service.dart';

/// Build-time agent settings.
final gemAgentConfigProvider = Provider<GemAgentConfig>(
  (ref) => GemAgentConfig.fromEnvironment(),
);

/// Chat model behind the agent. Override to swap vendor or fake in tests.
final gemAgentLlmProvider = Provider<LlmClient>((ref) {
  final store = ref.watch(authTokenStoreProvider);
  return OpenAiChatClient(
    ref.watch(gemAgentConfigProvider),
    readSessionToken: store.readAccessToken,
  );
});

final gemAgentToolRegistryProvider = Provider<ToolRegistry>(
  (ref) => ToolRegistry(gemAgentTools),
);

/// Structured step log. Debug builds print it; wire analytics here for
/// production dashboards (latency, tool mix, guard hits, failures).
final gemAgentTracerProvider = Provider<AgentTracer?>(
  (ref) => kDebugMode
      ? (event, fields) => debugPrint('GemAgent.$event $fields')
      : null,
);

/// Engine with session-long memory. Rebuilt — so memory starts empty — when
/// the signed-in account changes: one user's conversation (and the account
/// data in it) is never visible to the next.
final gemAgentEngineProvider = Provider<AgentEngine>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  return AgentEngine(
    llm: ref.watch(gemAgentLlmProvider),
    registry: ref.watch(gemAgentToolRegistryProvider),
    memory: ConversationMemory(),
    tracer: ref.watch(gemAgentTracerProvider),
  );
});

final gemAgentSpeechProvider = Provider<SpeechInputService>(
  (ref) => SpeechInputService(),
);
