import '../domain/agent_tool.dart';
import 'ask_user/ask_user_tool.dart';
import 'bullion_search/bullion_search_tool.dart';
import 'diamond_search/diamond_search_tool.dart';
import 'gemstone_search/gemstone_search_tool.dart';
import 'jewelry_search/jewelry_search_tool.dart';
import 'watch_search/watch_search_tool.dart';

/// Every capability Gem Agent has. To add one: implement [AgentTool] in its
/// own folder under `tools/` (catalog searches extend `CatalogSearchTool`)
/// and append it here. The prompt, schemas and engine pick it up.
const List<AgentTool> gemAgentTools = [
  AskUserTool(),
  DiamondSearchTool(),
  GemstoneSearchTool(),
  WatchSearchTool(),
  JewelrySearchTool(),
  BullionSearchTool(),
];
