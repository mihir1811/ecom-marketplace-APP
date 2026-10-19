import '../domain/agent_tool.dart';
import '../domain/llm_client.dart';

/// Name-indexed set of tools the agent may call.
class ToolRegistry {
  ToolRegistry(Iterable<AgentTool> tools)
    : _tools = {for (final tool in tools) tool.name: tool};

  final Map<String, AgentTool> _tools;

  Iterable<AgentTool> get tools => _tools.values;

  AgentTool? find(String name) => _tools[name];

  List<LlmToolSpec> get specs => [for (final tool in tools) tool.spec];
}
