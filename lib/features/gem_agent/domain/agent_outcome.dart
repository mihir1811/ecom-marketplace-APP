import 'agent_effect.dart';

/// How a user turn ended.
sealed class AgentOutcome {
  const AgentOutcome();
}

/// Conversational answer; nothing was executed.
final class AgentReply extends AgentOutcome {
  const AgentReply(this.text);
  final String text;
}

/// The agent is holding the request until the user answers.
final class AgentClarification extends AgentOutcome {
  const AgentClarification(this.question, {this.options = const []});
  final String question;
  final List<String> options;
}

/// An action tool finished; [effects] still need applying.
final class AgentActionCompleted extends AgentOutcome {
  const AgentActionCompleted(this.summary, {this.effects = const []});
  final String summary;
  final List<AgentEffect> effects;
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
