import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../domain/agent_message.dart';
import '../domain/llm_client.dart';
import 'gem_agent_config.dart';

/// [LlmClient] over OpenAI Chat Completions with function calling.
///
/// Uses its own Dio so the app's auth interceptor never sends GemWorld
/// tokens to the model provider.
class OpenAiChatClient implements LlmClient {
  OpenAiChatClient(this._config, {Dio? dio, this.readSessionToken})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _config.baseUrl,
              connectTimeout: GemAgentConfig.connectTimeout,
              receiveTimeout: GemAgentConfig.receiveTimeout,
              contentType: Headers.jsonContentType,
            ),
          );

  final GemAgentConfig _config;
  final Dio _dio;

  /// The signed-in user's GemWorld token, sent instead of the provider key
  /// when [GemAgentConfig.proxyAuth] is on.
  final Future<String?> Function()? readSessionToken;

  @override
  Future<Result<LlmResponse, LlmFailure>> complete(
    LlmRequest request, {
    CancelToken? cancelToken,
  }) async {
    if (!_config.isConfigured) {
      return const ResultFailure(
        LlmFailure(
          LlmFailureKind.notConfigured,
          kDebugMode
              ? 'Gem Agent is not set up yet. Add OPENAI_API_KEY (or '
                    'GEM_AGENT_PROXY_AUTH) to .env.'
              : 'Gem Agent is unavailable right now. Please try again later.',
        ),
      );
    }
    final String bearer;
    if (_config.proxyAuth) {
      final token = (await readSessionToken?.call())?.trim() ?? '';
      if (token.isEmpty) {
        return const ResultFailure(
          LlmFailure(
            LlmFailureKind.unauthorized,
            'Please sign in to use Gem Agent.',
          ),
        );
      }
      bearer = token;
    } else {
      bearer = _config.apiKey;
    }

    for (var attempt = 0; ; attempt++) {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          '/chat/completions',
          data: _body(request),
          options: Options(headers: {'Authorization': 'Bearer $bearer'}),
          cancelToken: cancelToken,
        );
        final parsed = _parse(response.data);
        return parsed == null
            ? const ResultFailure(
                LlmFailure(
                  LlmFailureKind.invalidResponse,
                  'I did not get a usable answer. Please try again.',
                ),
              )
            : Success(parsed);
      } on DioException catch (e) {
        final failure = _failureFor(e);
        final transient =
            failure.kind == LlmFailureKind.rateLimited ||
            (failure.kind == LlmFailureKind.server &&
                (e.response?.statusCode ?? 500) >= 500);
        if (!transient ||
            attempt >= GemAgentConfig.retries ||
            (cancelToken?.isCancelled ?? false)) {
          return ResultFailure(failure);
        }
        await Future<void>.delayed(Duration(milliseconds: 700 * (attempt + 1)));
        if (cancelToken?.isCancelled ?? false) {
          return const ResultFailure(
            LlmFailure(LlmFailureKind.cancelled, 'Cancelled.'),
          );
        }
      }
    }
  }

  Map<String, Object?> _body(LlmRequest request) => {
    'model': _config.model,
    if (_config.reasoningEffort.isNotEmpty)
      'reasoning_effort': _config.reasoningEffort,
    if (_config.maxOutputTokens > 0)
      'max_completion_tokens': _config.maxOutputTokens,
    'messages': [
      {'role': 'system', 'content': request.systemPrompt},
      for (final message in request.messages) _encode(message),
    ],
    if (request.tools.isNotEmpty) ...{
      'tools': [
        for (final tool in request.tools)
          {
            'type': 'function',
            'function': {
              'name': tool.name,
              'description': tool.description,
              'parameters': tool.parameters,
            },
          },
      ],
      'tool_choice': 'auto',
      // Independent questions ("cart and wallet?") resolve in one round.
      'parallel_tool_calls': true,
    },
  };

  static Map<String, Object?> _encode(AgentMessage message) =>
      switch (message.role) {
        AgentRole.user => {'role': 'user', 'content': message.content ?? ''},
        AgentRole.assistant => {
          'role': 'assistant',
          'content': message.content,
          if (message.toolCalls.isNotEmpty)
            'tool_calls': [
              for (final call in message.toolCalls)
                {
                  'id': call.id,
                  'type': 'function',
                  'function': {
                    'name': call.name,
                    'arguments': call.rawArguments,
                  },
                },
            ],
        },
        AgentRole.tool => {
          'role': 'tool',
          'tool_call_id': message.toolCallId,
          'content': message.content ?? '',
        },
      };

  static LlmResponse? _parse(Map<String, dynamic>? json) {
    final choices = json?['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final message = (choices.first as Map?)?['message'];
    if (message is! Map) return null;

    final calls = <AgentToolCall>[];
    final rawCalls = message['tool_calls'];
    if (rawCalls is List) {
      for (final raw in rawCalls) {
        if (raw is! Map) continue;
        final function = raw['function'];
        if (function is! Map) continue;
        final name = function['name'];
        if (name is! String || name.isEmpty) continue;
        calls.add(
          AgentToolCall(
            id: raw['id']?.toString() ?? 'call_${calls.length}',
            name: name,
            rawArguments: function['arguments']?.toString() ?? '{}',
          ),
        );
      }
    }
    final content = message['content'];
    return LlmResponse(
      text: content is String ? content : null,
      toolCalls: calls,
    );
  }

  LlmFailure _failureFor(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return const LlmFailure(LlmFailureKind.cancelled, 'Cancelled.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const LlmFailure(
        LlmFailureKind.offline,
        'You appear to be offline. Check your connection and try again.',
      );
    }
    final status = e.response?.statusCode;
    // Provider detail stays in debug logs only.
    if (kDebugMode) {
      debugPrint(
        'Gem Agent LLM error $status: ${e.response?.data ?? e.message}',
      );
    }
    return switch (status) {
      401 || 403 => const LlmFailure(
        LlmFailureKind.unauthorized,
        'Gem Agent could not sign in to its AI service.',
      ),
      404 => LlmFailure(
        LlmFailureKind.modelUnavailable,
        kDebugMode
            ? 'The AI model "${_config.model}" is not available.'
            : 'Gem Agent is unavailable right now. Please try again later.',
      ),
      429 => const LlmFailure(
        LlmFailureKind.rateLimited,
        'Gem Agent is busy right now. Please try again in a moment.',
      ),
      _
          when e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout =>
        const LlmFailure(
          LlmFailureKind.server,
          'This is taking longer than expected. Please try again.',
        ),
      _ => const LlmFailure(
        LlmFailureKind.server,
        'Gem Agent ran into a problem. Please try again.',
      ),
    };
  }
}
