/// Gem Agent — frontend agentic layer (voice/text → LLM tool calling →
/// app actions). The app only mounts [GemAgentOverlay]; tools are
/// registered in `tools/gem_agent_tools.dart`.
library;

export 'presentation/gem_agent_overlay.dart' show GemAgentOverlay;
