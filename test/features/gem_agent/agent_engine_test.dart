import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/error/failure.dart';
import 'package:gemstone/core/error/result.dart';
import 'package:gemstone/features/diamonds/data/repositories/diamond_repository_impl.dart';
import 'package:gemstone/features/diamonds/domain/models/diamond.dart';
import 'package:gemstone/features/diamonds/domain/models/diamond_catalog_type.dart';
import 'package:gemstone/features/diamonds/domain/models/diamond_filter_state.dart';
import 'package:gemstone/features/diamonds/domain/models/sorting_criteria.dart';
import 'package:gemstone/features/diamonds/domain/repositories/diamond_repository.dart';
import 'package:gemstone/features/gem_agent/domain/agent_message.dart';
import 'package:gemstone/features/gem_agent/domain/agent_outcome.dart';
import 'package:gemstone/features/gem_agent/domain/llm_client.dart';
import 'package:gemstone/features/gem_agent/engine/agent_engine.dart';
import 'package:gemstone/features/gem_agent/engine/conversation_memory.dart';
import 'package:gemstone/features/gem_agent/engine/system_prompt_builder.dart';
import 'package:gemstone/features/gem_agent/engine/tool_registry.dart';
import 'package:gemstone/features/gem_agent/tools/gem_agent_tools.dart';

/// Replays scripted model turns and records what it was sent.
class _ScriptedLlm implements LlmClient {
  _ScriptedLlm(this._turns);

  final List<LlmResponse> _turns;
  final requests = <LlmRequest>[];

  @override
  Future<Result<LlmResponse, LlmFailure>> complete(
    LlmRequest request, {
    CancelToken? cancelToken,
  }) async {
    requests.add(request);
    return Success(_turns.removeAt(0));
  }
}

class _FakeRepo implements DiamondRepository {
  final calls = <(DiamondFilterState, DiamondCatalogType)>[];

  @override
  Future<Result<DiamondListResponse, Failure>> getDiamonds({
    required DiamondFilterState filters,
    required DiamondCatalogType catalog,
    required int page,
    int pageSize = DiamondPageSize.defaultSize,
    List<SortingCriteria> sorting = const [],
    String? sellerId,
    CancelToken? cancelToken,
  }) async {
    calls.add((filters, catalog));
    return const Success(
      DiamondListResponse(diamonds: [], totalCount: 42, hasMore: true, page: 1),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LlmResponse _call(String name, String args) => LlmResponse(
  toolCalls: [AgentToolCall(id: 'c_$name', name: name, rawArguments: args)],
);

final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  late _FakeRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepo();
    container = ProviderContainer(
      overrides: [diamondRepositoryProvider.overrideWithValue(repo)],
    );
  });
  tearDown(() => container.dispose());

  AgentEngine engine(_ScriptedLlm llm, ConversationMemory memory) =>
      AgentEngine(
        llm: llm,
        registry: ToolRegistry(gemAgentTools),
        memory: memory,
      );

  Future<AgentOutcome> say(AgentEngine e, String text) => e.run(
    text,
    runtime: AgentRuntimeContext(
      route: '/',
      languageCode: 'en',
      now: DateTime(2026, 10, 19),
    ),
    ref: container.read(_refProvider),
    cancelToken: CancelToken(),
  );

  test('holds a search missing origin, then searches once answered', () async {
    final memory = ConversationMemory();
    final llm = _ScriptedLlm([
      _call(
        'ask_user',
        '{"question":"Natural or lab-grown diamond?","options":["Natural","Lab-grown"]}',
      ),
      _call(
        'search_diamonds',
        '{"origin":"natural","shapes":["Round"],"carat":2}',
      ),
    ]);
    final e = engine(llm, memory);

    final first = await say(e, 'find me 2 carat round diamond');
    expect(first, isA<AgentClarification>());
    expect((first as AgentClarification).options, ['Natural', 'Lab-grown']);
    expect(repo.calls, isEmpty);

    final second = await say(e, 'natural');
    expect(second, isA<AgentActionCompleted>());
    expect((second as AgentActionCompleted).effects, hasLength(1));
    expect(second.summary, contains('42'));

    final (filters, catalog) = repo.calls.single;
    expect(catalog, DiamondCatalogType.natural);
    expect(filters.shapes, ['Round']);
    expect(filters.minCarat, 2.0);
    expect(filters.maxCarat, 2.09);

    // Model saw the full history, with every tool call answered.
    final history = llm.requests.last.messages;
    expect(history.where((m) => m.role == AgentRole.tool), hasLength(1));
    expect(history.last.content, 'natural');
  });

  test('refuses a guessed origin the user never stated', () async {
    final llm = _ScriptedLlm([
      _call('search_diamonds', '{"origin":"natural","shapes":["Oval"]}'),
    ]);
    final outcome = await say(
      engine(llm, ConversationMemory()),
      'show me oval diamonds',
    );
    expect(outcome, isA<AgentClarification>());
    expect(repo.calls, isEmpty);
  });

  test('feeds recoverable tool errors back to the model', () async {
    final llm = _ScriptedLlm([
      _call('no_such_tool', '{}'),
      const LlmResponse(text: 'I can search diamonds for you.'),
    ]);
    final outcome = await say(engine(llm, ConversationMemory()), 'hello');
    expect(outcome, isA<AgentReply>());
    expect(llm.requests, hasLength(2));
  });

  test('system prompt carries tool guidance and runtime context', () {
    final prompt = const SystemPromptBuilder().build(
      runtime: AgentRuntimeContext(
        route: '/diamonds/results',
        languageCode: 'hi',
        now: DateTime(2026, 10, 19),
      ),
      tools: gemAgentTools,
    );
    expect(prompt, contains('## Tool: search_diamonds'));
    expect(prompt, contains('Never assume natural'));
    expect(prompt.indexOf('# Context'), greaterThan(prompt.indexOf('# Tools')));
    expect(prompt, contains('/diamonds/results'));
  });
}
