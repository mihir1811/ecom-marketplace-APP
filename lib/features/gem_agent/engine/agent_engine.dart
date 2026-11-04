import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../domain/agent_card.dart';
import '../domain/agent_effect.dart';
import '../domain/agent_message.dart';
import '../domain/agent_outcome.dart';
import '../domain/agent_session.dart';
import '../domain/agent_tool.dart';
import '../domain/llm_client.dart';
import '../domain/tool_result.dart';
import 'conversation_memory.dart';
import 'guardrails.dart';
import 'local_router.dart';
import 'side_resolver.dart';
import 'system_prompt_builder.dart';
import 'tool_registry.dart';
import 'turn_limiter.dart';

/// Receives one structured event per step (`turn`, `guard`, `local`, `llm`,
/// `tool`, `outcome`) for logging / analytics. Fields carry names, counts
/// and timings only — never what the user typed or tool data.
typedef AgentTracer = void Function(String event, Map<String, Object?> fields);

/// The guard → route → reason → act → observe loop.
///
/// 1. [InputGuard] answers injection, secret probing, other people's data
///    and off-topic requests itself; none of it reaches the model or memory.
/// 2. [LocalRouter] answers small talk, runs fixed account look-ups and asks
///    for missing required details without a model call.
/// 3. Otherwise each step asks the model for the next move with only the
///    tools this user may use; tool calls run, their results go back into
///    memory, and the loop continues until the model answers, a tool needs
///    input, tools complete the turn, or [maxSteps] is reached.
class AgentEngine {
  AgentEngine({
    required this.llm,
    required this.registry,
    required this.memory,
    this.promptBuilder = const SystemPromptBuilder(),
    this.inputGuard = const InputGuard(),
    this.outputGuard = const OutputGuard(),
    this.router = const LocalRouter(),
    this.sides = const AgentSideResolver(),
    TurnLimiter? limiter,
    this.maxSteps = 6,
    this.toolTimeout = const Duration(seconds: 40),
    this.sessionTtl = const Duration(minutes: 30),
    this.maxToolContentChars = 6000,
    this.maxCards = 6,
    this.tracer,
  }) : limiter = limiter ?? TurnLimiter();

  final LlmClient llm;
  final ToolRegistry registry;
  final ConversationMemory memory;
  final SystemPromptBuilder promptBuilder;
  final InputGuard inputGuard;
  final OutputGuard outputGuard;

  /// Null disables the local fast path (every turn goes to the model).
  final LocalRouter? router;

  /// Decides buyer vs seller for look-ups that exist on both sides.
  final AgentSideResolver sides;
  final TurnLimiter limiter;
  final int maxSteps;
  final Duration toolTimeout;

  /// Idle time after which the conversation starts fresh, so an old
  /// request is never silently "refined" hours later.
  final Duration sessionTtl;

  /// Longest tool result fed back to the model (token cost bound).
  final int maxToolContentChars;
  final int maxCards;
  final AgentTracer? tracer;

  DateTime? _lastTurnAt;
  int _localCalls = 0;

  static const _giveUp =
      'I could not finish that. Please try saying it another way.';
  static const _slowDown =
      'You\'re asking very quickly. Please wait a moment and try again.';

  Future<AgentOutcome> run(
    String utterance, {
    required AgentRuntimeContext runtime,
    required Ref ref,
    required CancelToken cancelToken,
    void Function(AgentProgress progress)? onProgress,
  }) async {
    final started = DateTime.now();
    final session = runtime.session;
    final last = _lastTurnAt;
    if (last != null && runtime.now.difference(last) > sessionTtl) {
      memory.clear();
    }
    _lastTurnAt = runtime.now;
    _trace('turn', {'chars': utterance.length, 'memory': memory.length});

    final verdict = inputGuard.check(utterance, session);
    if (verdict != null) {
      _trace('guard', {'blocked': true});
      return AgentReply(verdict.reply, options: verdict.options);
    }

    final history = memory.userUtterances;
    final turnStart = memory.length;
    memory.add(AgentMessage.user(utterance));
    final context = AgentToolContext(
      ref: ref,
      cancelToken: cancelToken,
      userUtterances: memory.userUtterances,
      session: session,
      clock: runtime.now,
    );

    final local = router?.route(utterance, session, history: history);
    if (local != null) {
      _trace('local', {'kind': local.runtimeType.toString()});
      final outcome = await _runLocal(local, context, onProgress);
      if (cancelToken.isCancelled) return _cancel(turnStart);
      if (outcome != null) return _finish(outcome, started);
    }

    if (!limiter.tryAcquire()) {
      memory.truncate(turnStart);
      _trace('guard', {'rate_limited': true});
      return const AgentReply(_slowDown);
    }

    final tools = registry.availableFor(session);
    final specs = [for (final tool in tools) tool.spec];
    final seenCalls = <String, int>{};
    for (var step = 0; step < maxSteps; step++) {
      if (cancelToken.isCancelled) return _cancel(turnStart);
      onProgress?.call(const AgentThinking());

      final llmStarted = DateTime.now();
      final result = await llm.complete(
        LlmRequest(
          systemPrompt: promptBuilder.build(runtime: runtime, tools: tools),
          messages: memory.window(),
          tools: specs,
        ),
        cancelToken: cancelToken,
      );
      if (cancelToken.isCancelled) return _cancel(turnStart);

      final LlmResponse response;
      switch (result) {
        case ResultFailure(failure: final failure):
          _trace('llm', {'ok': false, 'kind': failure.kind.name});
          memory.truncate(turnStart);
          return failure.isCancelled
              ? const AgentCancelled()
              : AgentFailed(failure.message);
        case Success(value: final value):
          response = value;
      }
      _trace('llm', {
        'ok': true,
        'step': step,
        'ms': DateTime.now().difference(llmStarted).inMilliseconds,
        'tool_calls': [for (final c in response.toolCalls) c.name],
      });

      if (response.toolCalls.isEmpty) {
        final text = outputGuard.sanitize(response.text ?? '', session);
        memory.add(AgentMessage.assistant(text));
        return _finish(
          text.isEmpty ? const AgentFailed(_giveUp) : AgentReply(text),
          started,
        );
      }

      // Loop breaker: repeating an identical call within one turn means the
      // model is stuck; stop instead of burning steps and tokens.
      var repeated = false;
      for (final c in response.toolCalls) {
        final key = '${c.name}:${c.rawArguments}';
        final seen = seenCalls[key] = (seenCalls[key] ?? 0) + 1;
        if (seen > 1) repeated = true;
      }
      memory.add(
        AgentMessage.assistant(response.text, toolCalls: response.toolCalls),
      );
      if (repeated) {
        _answerSkipped(response.toolCalls);
        memory.add(AgentMessage.assistant(_giveUp));
        return _finish(const AgentFailed(_giveUp), started);
      }
      final stop = await _runToolCalls(response.toolCalls, context, onProgress);
      if (cancelToken.isCancelled) return _cancel(turnStart);
      if (stop != null) return _finish(stop, started);
    }

    memory.add(AgentMessage.assistant(_giveUp));
    return _finish(const AgentFailed(_giveUp), started);
  }

  /// Applies a router decision. Null hands the turn on to the model.
  Future<AgentOutcome?> _runLocal(
    LocalDecision decision,
    AgentToolContext context,
    void Function(AgentProgress progress)? onProgress,
  ) async {
    switch (decision) {
      case LocalReply(:final text, :final options):
        memory.add(AgentMessage.assistant(text));
        return AgentReply(text, options: options);
      case LocalClarify(:final question, :final options):
        memory.add(AgentMessage.assistant(question));
        return AgentClarification(question, options: options);
      case LocalToolCall(:final tool, :final args):
        final found = registry.find(tool);
        if (found == null) return null;
        if (!found.access.allows(context.session)) {
          final text = found.access.deniedMessage(context.session);
          memory.add(AgentMessage.assistant(text));
          return AgentReply(
            text,
            options: InputGuard.starterOptions(context.session),
          );
        }
        // Recorded as a normal call/result pair so the model can build on
        // it in the next turn ("and yesterday?").
        final call = AgentToolCall(
          id: 'local_${++_localCalls}',
          name: tool,
          rawArguments: jsonEncode(args),
        );
        memory.add(AgentMessage.assistant(null, toolCalls: [call]));
        return _runToolCalls([call], context, onProgress);
    }
  }

  /// Executes every call of one model response, then decides whether the
  /// turn ends. Completed results are combined so a multi-part question
  /// ("cart and wallet?") gets one answer.
  Future<AgentOutcome?> _runToolCalls(
    List<AgentToolCall> calls,
    AgentToolContext context,
    void Function(AgentProgress progress)? onProgress,
  ) async {
    final done = <ToolSuccess>[];
    String? failure;
    for (var i = 0; i < calls.length; i++) {
      final call = calls[i];
      final toolStarted = DateTime.now();
      final result = await _execute(call, context, onProgress);
      _trace('tool', {
        'name': call.name,
        'result': result.runtimeType.toString(),
        'ms': DateTime.now().difference(toolStarted).inMilliseconds,
      });
      memory.add(
        AgentMessage.tool(
          callId: call.id,
          name: call.name,
          content: _capped(result.toModelContent()),
        ),
      );
      if (context.cancelToken.isCancelled) {
        _answerSkipped(calls.skip(i + 1));
        return null;
      }
      switch (result) {
        case ToolNeedsInput(:final question, :final options):
          _answerSkipped(calls.skip(i + 1));
          memory.add(AgentMessage.assistant(question));
          return AgentClarification(question, options: options);
        case final ToolSuccess success when success.completesTurn:
          done.add(success);
        case ToolFailure(recoverable: false, :final message):
          failure ??= message;
        case _:
          break;
      }
    }
    if (done.isEmpty) {
      if (failure == null) return null;
      memory.add(AgentMessage.assistant(failure));
      return AgentFailed(failure);
    }

    final summary = [for (final r in done) r.summary, ?failure].join('\n');
    // One screen can be shown at a time: the first navigating result wins.
    final effects = done
        .map((r) => r.effects)
        .firstWhere((e) => e.isNotEmpty, orElse: () => const <AgentEffect>[]);
    final cards = <AgentCard>[
      for (final r in done) ...r.cards,
    ].take(maxCards).toList();
    memory.add(AgentMessage.assistant(summary));
    return AgentActionCompleted(summary, effects: effects, cards: cards);
  }

  /// Every tool call needs a result, even the ones we skip.
  void _answerSkipped(Iterable<AgentToolCall> calls) {
    for (final skipped in calls) {
      memory.add(
        AgentMessage.tool(
          callId: skipped.id,
          name: skipped.name,
          content: const ToolFailure('Skipped').toModelContent(),
        ),
      );
    }
  }

  Future<ToolResult> _execute(
    AgentToolCall call,
    AgentToolContext context,
    void Function(AgentProgress progress)? onProgress,
  ) async {
    final tool = registry.find(call.name);
    // Tools the user may not use are also unknown to the model; a call to
    // one is treated as unknown, never executed.
    if (tool == null || !tool.access.allows(context.session)) {
      return ToolFailure('Unknown tool "${call.name}".', recoverable: true);
    }
    final args = call.decodeArguments();
    if (args == null) {
      return const ToolFailure(
        'Arguments were not a valid JSON object.',
        recoverable: true,
      );
    }
    var target = tool;
    var runArgs = args;
    switch (_sideFor(tool, args, context)) {
      case final ToolNeedsInput ask:
        return ask;
      case (final AgentTool twin, final Map<String, Object?> twinArgs):
        target = twin;
        runArgs = twinArgs;
    }
    onProgress?.call(
      AgentToolRunning(target.name, target.progressLabel(runArgs)),
    );
    try {
      return await target.execute(runArgs, context).timeout(toolTimeout);
    } on TimeoutException {
      return const ToolFailure('That took too long. Please try again.');
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Gem Agent tool ${target.name} crashed: $error\n$stack');
      }
      return const ToolFailure('Something went wrong. Please try again.');
    }
  }

  /// Orders, offers and auctions exist on both sides. Whatever the model
  /// or router picked, read the side the user means (named, else the screen
  /// they are on), or ask when that can't be known. Returns null to run
  /// [tool] as called, a question, or the twin tool with its arguments.
  Object? _sideFor(
    AgentTool tool,
    Map<String, Object?> args,
    AgentToolContext context,
  ) {
    final calledSide = AgentSideResolver.sideOf(tool.name);
    if (calledSide == null) return null;
    switch (sides.resolve(context.session, context.userUtterances)) {
      case AskSide():
        return AgentSideResolver.question(tool.name);
      case UseSide(:final side) when side != calledSide:
        final twin = registry.find(AgentSideResolver.twinOf(tool.name)!);
        if (twin == null || !twin.access.allows(context.session)) return null;
        _trace('side', {'from': tool.name, 'to': twin.name});
        return (twin, _argsFor(twin, args));
      case _:
        return null;
    }
  }

  /// [args] reduced to what [tool] accepts (same names, allowed values).
  static Map<String, Object?> _argsFor(
    AgentTool tool,
    Map<String, Object?> args,
  ) {
    final properties = tool.parameters['properties'];
    if (properties is! Map) return const {};
    return {
      for (final e in args.entries)
        if (properties[e.key] case final Map<dynamic, dynamic> schema
            when schema['enum'] is! List ||
                (schema['enum'] as List).contains(e.value))
          e.key: e.value,
    };
  }

  String _capped(String content) => content.length <= maxToolContentChars
      ? content
      : '${content.substring(0, maxToolContentChars)}…(truncated)';

  AgentOutcome _cancel(int turnStart) {
    memory.truncate(turnStart);
    return const AgentCancelled();
  }

  AgentOutcome _finish(AgentOutcome outcome, DateTime started) {
    _trace('outcome', {
      'kind': outcome.runtimeType.toString(),
      'ms': DateTime.now().difference(started).inMilliseconds,
    });
    return outcome;
  }

  void _trace(String event, Map<String, Object?> fields) =>
      tracer?.call(event, fields);

  /// Starts a fresh conversation (new chat, sign-out, account switch).
  void reset() {
    memory.clear();
    _lastTurnAt = null;
  }
}

/// Convenience so callers can apply all effects of an outcome.
extension AgentOutcomeEffects on AgentOutcome {
  List<AgentEffect> get effects => switch (this) {
    AgentActionCompleted(:final effects) => effects,
    _ => const [],
  };
}

/// Tools a session may use, in registration order.
extension ToolAccessFilter on ToolRegistry {
  List<AgentTool> availableFor(AgentSession session) => [
    for (final tool in tools)
      if (tool.access.allows(session)) tool,
  ];
}
