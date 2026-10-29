import 'dart:convert';

import 'agent_card.dart';
import 'agent_effect.dart';

/// Outcome of one tool execution. Its [toModelContent] is what the model
/// sees; the rest drives the engine (stop, ask, chain) and the UI.
sealed class ToolResult {
  const ToolResult();

  String toModelContent();
}

/// Work done. [completesTurn] ends the turn without another model round
/// trip (fast path for action tools such as search → navigate); otherwise
/// [data] is fed back so the model can chain the next tool.
final class ToolSuccess extends ToolResult {
  const ToolSuccess({
    required this.summary,
    this.data = const {},
    this.effects = const [],
    this.cards = const [],
    this.completesTurn = false,
  });

  /// Short user-facing line shown when the turn completes.
  final String summary;
  final Map<String, Object?> data;

  /// Applied after the turn; any effect closes the sheet (navigation).
  final List<AgentEffect> effects;

  /// Shown in the sheet with [summary] when nothing navigates.
  final List<AgentCard> cards;
  final bool completesTurn;

  @override
  String toModelContent() =>
      jsonEncode({'status': 'ok', 'summary': summary, ...data});
}

/// Required information is missing — the turn pauses on [question].
final class ToolNeedsInput extends ToolResult {
  const ToolNeedsInput({
    required this.question,
    this.missing = const [],
    this.options = const [],
  });

  final String question;
  final List<String> missing;

  /// Quick replies offered as chips.
  final List<String> options;

  @override
  String toModelContent() => jsonEncode({
    'status': 'needs_input',
    'missing': missing,
    'question_asked': question,
  });
}

/// Tool failed. [recoverable] failures (bad arguments) go back to the model
/// to retry; others end the turn with [message].
final class ToolFailure extends ToolResult {
  const ToolFailure(this.message, {this.recoverable = false});

  /// User-safe text. Never carries raw server errors.
  final String message;
  final bool recoverable;

  @override
  String toModelContent() => jsonEncode({'status': 'error', 'error': message});
}
