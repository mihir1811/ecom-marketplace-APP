import 'agent_card.dart';
import 'agent_effect.dart';

/// How a user turn ended.
sealed class AgentOutcome {
  const AgentOutcome();
}

/// Conversational answer; nothing was executed.
final class AgentReply extends AgentOutcome {
  const AgentReply(this.text, {this.options = const []});
  final String text;

  /// Suggested next requests offered as chips.
  final List<String> options;
}

/// The agent is holding the request until the user answers.
final class AgentClarification extends AgentOutcome {
  const AgentClarification(this.question, {this.options = const []});
  final String question;
  final List<String> options;
}

/// Tools finished; [effects] still need applying. Without effects the
/// answer stays in the sheet with its [cards].
final class AgentActionCompleted extends AgentOutcome {
  const AgentActionCompleted(
    this.summary, {
    this.effects = const [],
    this.cards = const [],
  });
  final String summary;
  final List<AgentEffect> effects;
  final List<AgentCard> cards;

  bool get navigates => effects.isNotEmpty;
}

final class AgentFailed extends AgentOutcome {
  const AgentFailed(this.message);
  final String message;
}

final class AgentCancelled extends AgentOutcome {
  const AgentCancelled();
}

/// Live progress while a turn runs.
sealed class AgentProgress {
  const AgentProgress();
}

final class AgentThinking extends AgentProgress {
  const AgentThinking();
}

final class AgentToolRunning extends AgentProgress {
  const AgentToolRunning(this.toolName, this.label);
  final String toolName;
  final String label;
}
