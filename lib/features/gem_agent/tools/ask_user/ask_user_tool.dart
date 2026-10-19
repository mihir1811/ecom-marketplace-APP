import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';

/// Built-in slot-filling tool: pauses the turn on a question to the user.
/// Its prompt rules live in the system prompt policy.
class AskUserTool extends AgentTool {
  const AskUserTool();

  @override
  String get name => 'ask_user';

  @override
  String get description =>
      'Ask the user for missing required information before acting. '
      'Use instead of guessing.';

  @override
  Map<String, Object?> get parameters => const {
    'type': 'object',
    'properties': {
      'question': {
        'type': 'string',
        'description': 'One short question in the user\'s language.',
      },
      'options': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': '2–4 short quick replies.',
      },
      'missing': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Names of the missing slots.',
      },
    },
    'required': ['question'],
  };

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    final question = (args['question'] as String?)?.trim() ?? '';
    if (question.isEmpty) {
      return const ToolFailure('question is required.', recoverable: true);
    }
    return ToolNeedsInput(
      question: question,
      options: _strings(args['options']).take(4).toList(),
      missing: _strings(args['missing']),
    );
  }

  static List<String> _strings(Object? value) => [
    if (value is List)
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
  ];
}
