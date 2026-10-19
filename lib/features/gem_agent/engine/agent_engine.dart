import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../domain/agent_effect.dart';
import '../domain/agent_message.dart';
import '../domain/agent_outcome.dart';
import '../domain/agent_tool.dart';
import '../domain/llm_client.dart';
import '../domain/tool_result.dart';
import 'conversation_memory.dart';
import 'system_prompt_builder.dart';
import 'tool_registry.dart';

/// The reason → act → observe loop.
///
/// Each step asks the model for the next move; tool calls run, their
/// results go back into memory, and the loop continues (chaining) until the
/// model answers, a tool needs user input, an action tool completes the
/// turn, or [maxSteps] is reached.
class AgentEngine {
  AgentEngine({
    required this.llm,
    required this.registry,
    required this.memory,
    this.promptBuilder = const SystemPromptBuilder(),
    this.maxSteps = 6,
    this.toolTimeout = const Duration(seconds: 40),
  });

  final LlmClient llm;
  final ToolRegistry registry;
  final ConversationMemory memory;
  final SystemPromptBuilder promptBuilder;
  final int maxSteps;
  final Duration toolTimeout;

  static const _giveUp =
      'I could not finish that. Please try saying it another way.';

  Future<AgentOutcome> run(
    String utterance, {
    required AgentRuntimeContext runtime,
    required Ref ref,
    required CancelToken cancelToken,
    void Function(AgentProgress progress)? onProgress,
  }) async {
    final turnStart = memory.length;
    memory.add(AgentMessage.user(utterance));
    final context = AgentToolContext(
      ref: ref,
      cancelToken: cancelToken,
      userUtterances: memory.userUtterances,
    );

    for (var step = 0; step < maxSteps; step++) {
      if (cancelToken.isCancelled) return _cancel(turnStart);
      onProgress?.call(const AgentThinking());

      final result = await llm.complete(
        LlmRequest(
          systemPrompt: promptBuilder.build(
            runtime: runtime,
            tools: registry.tools,
          ),
          messages: memory.window(),
          tools: registry.specs,
        ),
        cancelToken: cancelToken,
      );
      if (cancelToken.isCancelled) return _cancel(turnStart);

      final LlmResponse response;
      switch (result) {
        case ResultFailure(failure: final failure):
          memory.truncate(turnStart);
          return failure.isCancelled
              ? const AgentCancelled()
              : AgentFailed(failure.message);
        case Success(value: final value):
          response = value;
      }

      if (response.toolCalls.isEmpty) {
        final text = (response.text ?? '').trim();
        memory.add(AgentMessage.assistant(text));
        return text.isEmpty ? const AgentFailed(_giveUp) : AgentReply(text);
      }

      memory.add(
        AgentMessage.assistant(response.text, toolCalls: response.toolCalls),
      );
      final stop = await _runToolCalls(response.toolCalls, context, onProgress);
      if (cancelToken.isCancelled) return _cancel(turnStart);
      if (stop != null) return stop;
    }

    memory.add(AgentMessage.assistant(_giveUp));
    return const AgentFailed(_giveUp);
  }

  /// Executes calls in order. Returns an outcome when the turn must stop.
  Future<AgentOutcome?> _runToolCalls(
    List<AgentToolCall> calls,
    AgentToolContext context,
    void Function(AgentProgress progress)? onProgress,
  ) async {
    for (var i = 0; i < calls.length; i++) {
      final call = calls[i];
      final result = await _execute(call, context, onProgress);
      memory.add(
        AgentMessage.tool(
          callId: call.id,
          name: call.name,
          content: result.toModelContent(),
        ),
      );

      final AgentOutcome? stop = switch (result) {
        ToolNeedsInput(:final question, :final options) => AgentClarification(
          question,
          options: options,
        ),
        ToolSuccess(completesTurn: true, :final summary, :final effects) =>
          AgentActionCompleted(summary, effects: effects),
        ToolFailure(recoverable: false, :final message) => AgentFailed(message),
        _ => null,
      };
      if (stop == null) continue;

      // Every tool call needs a result, even the ones we skip.
      for (final skipped in calls.skip(i + 1)) {
        memory.add(
          AgentMessage.tool(
            callId: skipped.id,
            name: skipped.name,
            content: const ToolFailure('Skipped').toModelContent(),
          ),
        );
      }
      memory.add(AgentMessage.assistant(_spokenText(stop)));
      return stop;
    }
    return null;
  }

  Future<ToolResult> _execute(
    AgentToolCall call,
    AgentToolContext context,
    void Function(AgentProgress progress)? onProgress,
  ) async {
    final tool = registry.find(call.name);
    if (tool == null) {
      return ToolFailure('Unknown tool "${call.name}".', recoverable: true);
    }
    final args = call.decodeArguments();
    if (args == null) {
      return const ToolFailure(
        'Arguments were not a valid JSON object.',
        recoverable: true,
      );
    }
    onProgress?.call(AgentToolRunning(tool.name, tool.progressLabel(args)));
    try {
      return await tool.execute(args, context).timeout(toolTimeout);
    } on TimeoutException {
      return const ToolFailure('That took too long. Please try again.');
    } catch (error, stack) {
      debugPrint('Gem Agent tool ${tool.name} crashed: $error\n$stack');
      return const ToolFailure('Something went wrong. Please try again.');
    }
  }

  AgentOutcome _cancel(int turnStart) {
    memory.truncate(turnStart);
    return const AgentCancelled();
  }

  static String _spokenText(AgentOutcome outcome) => switch (outcome) {
    AgentClarification(:final question) => question,
    AgentActionCompleted(:final summary) => summary,
    AgentFailed(:final message) => message,
    AgentReply(:final text) => text,
    AgentCancelled() => '',
  };
}

/// Convenience so callers can apply all effects of an outcome.
extension AgentOutcomeEffects on AgentOutcome {
  List<AgentEffect> get effects => switch (this) {
    AgentActionCompleted(:final effects) => effects,
    _ => const [],
  };
}
