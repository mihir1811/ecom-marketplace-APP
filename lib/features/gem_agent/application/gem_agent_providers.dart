import 'package:flutter_riverpod/flutter_riverpod.dart';

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
final gemAgentLlmProvider = Provider<LlmClient>(
  (ref) => OpenAiChatClient(ref.watch(gemAgentConfigProvider)),
);

final gemAgentToolRegistryProvider = Provider<ToolRegistry>(
  (ref) => ToolRegistry(gemAgentTools),
);

/// Session-long engine; its memory survives closing the sheet.
final gemAgentEngineProvider = Provider<AgentEngine>(
  (ref) => AgentEngine(
    llm: ref.watch(gemAgentLlmProvider),
    registry: ref.watch(gemAgentToolRegistryProvider),
    memory: ConversationMemory(),
  ),
);

final gemAgentSpeechProvider = Provider<SpeechInputService>(
  (ref) => SpeechInputService(),
);
