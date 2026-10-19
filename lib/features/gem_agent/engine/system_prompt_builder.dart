import '../domain/agent_tool.dart';

/// Per-turn facts about where the user is, merged into the prompt.
class AgentRuntimeContext {
  const AgentRuntimeContext({
    required this.route,
    required this.languageCode,
    required this.now,
    this.extras = const {},
  });

  final String route;
  final String languageCode;
  final DateTime now;

  /// Extra key/value facts future tools may need (role, cart size…).
  final Map<String, String> extras;
}

/// Builds the system prompt from fixed policy, the registered tools'
/// guidance and runtime context.
///
/// Stable text comes first and runtime facts last, so the provider's prompt
/// prefix cache keeps hitting across turns.
class SystemPromptBuilder {
  const SystemPromptBuilder();

  static const _identity = '''
You are Gem Agent, the hands-free operator inside the GemWorld marketplace app (diamonds, gemstones, jewelry). You do not chat; you operate the app for the user by calling tools, so they skip manual searching and filtering.''';

  static const _policy = '''
# How to handle every request
1. Work out the user's intent and the one tool that fulfils it.
2. Fill the tool's slots ONLY from what the user actually said in this conversation. Never invent, assume or default a value. Leave out optional slots the user did not mention.
3. If a REQUIRED slot is missing or ambiguous, do not call the action tool. Call ask_user once with a single short question covering every missing required slot, plus quick-reply options.
4. When the user answers or refines ("make it oval", "under 1 carat"), keep every slot from the earlier request and change only what they changed, then call the tool again.
5. Input is often voice transcription: turn number words into digits ("two carat" → 2), fix sound-alikes ("pair shape" → Pear, "lab grown"/"lab made" → lab_grown), ignore filler words.
6. Users mix English, Hindi and Gujarati ("batavo", "batao", "dikhao", "joiye", "chahiye" = show / I want). Read the whole sentence before filling slots.
7. Map EVERY constraint the user stated to the most specific slot the tool offers; never drop one. Check each schema property, not only the common ones (seller, location, fluorescence, treatment, availability, measurements, certificates…).
8. Negation means exclude, never include and never ignore. "except X", "excluding X", "without X", "not from X", "other than X", "X sivay", "X sivayna", "X siway", "X ke alava", "X ke siva", "X chhodke", "X chhodi ne", "X vagar", "X bina", "X nahi", "X ना", "X के सिवाय", "X के अलावा", "X छोड़कर", "X સિવાય", "X સિવાયના", "X વગર", "X છોડીને" → put X in the matching exclude_* slot.
9. A detail with no slot goes in "query" if the tool has one; otherwise leave it out.
10. Call one tool at a time.
11. If no tool fits, answer in at most two sentences and say what you can do.
12. Reply in the user's language, at most two short sentences, plain text, no markdown.''';

  static const _askUser = '''
## Tool: ask_user
Use only for missing REQUIRED information. Ask one question; give 2–4 short options.''';

  String build({
    required AgentRuntimeContext runtime,
    required Iterable<AgentTool> tools,
  }) {
    final buffer = StringBuffer()
      ..writeln(_identity)
      ..writeln()
      ..writeln(_policy)
      ..writeln()
      ..writeln('# Tools')
      ..writeln(_askUser);
    for (final tool in tools) {
      final guidance = tool.promptGuidance.trim();
      if (guidance.isEmpty) continue;
      buffer
        ..writeln()
        ..writeln('## Tool: ${tool.name}')
        ..writeln(guidance);
    }
    buffer
      ..writeln()
      ..writeln('# Context')
      ..writeln('- Current screen: ${runtime.route}')
      ..writeln('- App language: ${runtime.languageCode}')
      ..writeln('- Local time: ${runtime.now.toIso8601String()}');
    runtime.extras.forEach((key, value) => buffer.writeln('- $key: $value'));
    return buffer.toString().trimRight();
  }
}
