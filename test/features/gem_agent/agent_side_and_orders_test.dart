import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/error/failure.dart';
import 'package:gemstone/core/error/result.dart';
import 'package:gemstone/features/gem_agent/domain/agent_message.dart';
import 'package:gemstone/features/gem_agent/domain/agent_outcome.dart';
import 'package:gemstone/features/gem_agent/domain/agent_session.dart';
import 'package:gemstone/features/gem_agent/domain/agent_tool.dart';
import 'package:gemstone/features/gem_agent/domain/llm_client.dart';
import 'package:gemstone/features/gem_agent/domain/tool_result.dart';
import 'package:gemstone/features/gem_agent/engine/agent_engine.dart';
import 'package:gemstone/features/gem_agent/engine/conversation_memory.dart';
import 'package:gemstone/features/gem_agent/engine/local_router.dart';
import 'package:gemstone/features/gem_agent/engine/side_resolver.dart';
import 'package:gemstone/features/gem_agent/engine/system_prompt_builder.dart';
import 'package:gemstone/features/gem_agent/engine/tool_registry.dart';
import 'package:gemstone/features/gem_agent/tools/buyer/my_orders_tool.dart';
import 'package:gemstone/features/jewelry_checkout/data/repositories/jewelry_checkout_repository_impl.dart';
import 'package:gemstone/features/jewelry_checkout/domain/models/marketplace_order.dart';
import 'package:gemstone/features/jewelry_checkout/domain/repositories/jewelry_checkout_repository.dart';
import 'package:gemstone/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:gemstone/features/payment/domain/models/payment_models.dart';
import 'package:gemstone/features/payment/domain/repositories/payment_repository.dart';

const _buyer = AgentSession(signedIn: true);

AgentSession _seller(AgentWorkspace on) =>
    AgentSession(signedIn: true, isSeller: true, workspace: on);

final _refProvider = Provider<Ref>((ref) => ref);

class _FakePayments implements PaymentRepository {
  _FakePayments([this.orders = const []]);
  final List<PaymentOrder> orders;

  @override
  Future<Result<PaymentOrdersPage, Failure>> listOrders({
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async => Success(
    PaymentOrdersPage(
      orders: orders,
      page: 1,
      limit: limit,
      total: orders.length,
      totalPages: 1,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeJewelry implements JewelryCheckoutRepository {
  _FakeJewelry(this.list);
  final List<MarketplaceOrder> list;

  @override
  Future<Result<List<MarketplaceOrder>, Failure>> orders() async =>
      Success(list);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MarketplaceOrder _jewelryOrder(String step, DateTime at) => MarketplaceOrder(
  id: 'j1',
  orderNumber: 'GW-1001',
  status: MarketplaceOrderStatus.paid,
  subtotal: 50000,
  shippingTotal: 0,
  total: 50000,
  refundedTotal: 0,
  createdAt: at,
  items: const [
    MarketplaceOrderItem(
      id: 'i1',
      title: 'Solitaire ring',
      shopName: 'Maison',
      unitPrice: 50000,
      quantity: 1,
      lineTotal: 50000,
      status: MarketplaceStepStatus.accepted,
    ),
  ],
  shipments: [
    MarketplaceShipment(
      shopName: 'Maison',
      status: step,
      courierName: 'BlueDart',
      expectedDeliveryAt: '2026-11-05',
    ),
  ],
);

/// Reports which tool ran.
class _NamedTool extends AgentTool {
  const _NamedTool(this.name);

  @override
  final String name;

  @override
  String get description => 'test';

  @override
  Map<String, Object?> get parameters => const {
    'type': 'object',
    'properties': {
      'period': {'type': 'string'},
    },
  };

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async => ToolSuccess(
    summary: '$name ran${args.isEmpty ? '' : ' $args'}',
    completesTurn: true,
  );
}

class _ScriptedLlm implements LlmClient {
  _ScriptedLlm(this.tool);
  final String tool;
  int calls = 0;

  @override
  Future<Result<LlmResponse, LlmFailure>> complete(
    LlmRequest request, {
    CancelToken? cancelToken,
  }) async {
    calls++;
    return Success(
      LlmResponse(
        toolCalls: [
          AgentToolCall(id: 'c$calls', name: tool, rawArguments: '{}'),
        ],
      ),
    );
  }
}

void main() {
  group('MyOrdersTool', () {
    Future<ToolResult> run(
      Map<String, Object?> args, {
      List<PaymentOrder> catalog = const [],
      List<MarketplaceOrder> jewelry = const [],
    }) {
      final container = ProviderContainer(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(_FakePayments(catalog)),
          jewelryCheckoutRepositoryProvider.overrideWithValue(
            _FakeJewelry(jewelry),
          ),
        ],
      );
      addTearDown(container.dispose);
      return const MyOrdersTool().execute(
        args,
        AgentToolContext(
          ref: container.read(_refProvider),
          cancelToken: CancelToken(),
          userUtterances: const ['status of my recent jewelry order'],
          session: _buyer,
          clock: DateTime(2026, 11, 2),
        ),
      );
    }

    test('finds jewelry marketplace orders', () async {
      final result = await run(
        {'kind': 'jewelry'},
        jewelry: [
          _jewelryOrder(MarketplaceStepStatus.shipped, DateTime(2026, 11)),
        ],
      );
      result as ToolSuccess;
      expect(result.summary, contains('1 jewelry order'));
      expect(result.summary, contains('Solitaire ring'));
      expect(result.summary, contains('shipped'));
      expect(result.data['total'], 1);
    });

    test('jewelry orders count with no kind too', () async {
      final result = await run(
        const {},
        jewelry: [
          _jewelryOrder(MarketplaceStepStatus.accepted, DateTime(2026, 11)),
        ],
      );
      expect((result as ToolSuccess).summary, contains('order confirmed'));
    });

    test('in-progress filter keeps an undelivered jewelry order', () async {
      final result = await run(
        {'status': 'in_progress'},
        jewelry: [
          _jewelryOrder(MarketplaceStepStatus.shipped, DateTime(2026, 11)),
        ],
      );
      expect((result as ToolSuccess).data['total'], 1);
    });
  });

  group('AgentSideResolver', () {
    const sides = AgentSideResolver();
    AgentWorkspace? sideOf(SideDecision d) => d is UseSide ? d.side : null;

    test('buyers always read buyer data', () {
      expect(
        sideOf(sides.resolve(_buyer, const ['orders received today'])),
        AgentWorkspace.buyer,
      );
    });

    test('defaults to the side on screen', () {
      const ask = ['what is the status of my recent jewelry order'];
      expect(
        sideOf(sides.resolve(_seller(AgentWorkspace.buyer), ask)),
        AgentWorkspace.buyer,
      );
      expect(
        sideOf(sides.resolve(_seller(AgentWorkspace.seller), ask)),
        AgentWorkspace.seller,
      );
    });

    test('a named side beats the screen', () {
      expect(
        sideOf(
          sides.resolve(_seller(AgentWorkspace.seller), const [
            'status of the order I bought',
          ]),
        ),
        AgentWorkspace.buyer,
      );
      expect(
        sideOf(
          sides.resolve(_seller(AgentWorkspace.buyer), const [
            'any orders from customers today',
          ]),
        ),
        AgentWorkspace.seller,
      );
    });

    test('asks on shared pages, follow-ups keep the answer', () {
      final shared = _seller(AgentWorkspace.shared);
      expect(sides.resolve(shared, const ['my orders']), isA<AskSide>());
      expect(
        sideOf(sides.resolve(shared, const ['my orders', 'Seller side'])),
        AgentWorkspace.seller,
      );
      expect(
        sideOf(
          sides.resolve(shared, const [
            'my orders',
            'Seller side',
            'and yesterday?',
          ]),
        ),
        AgentWorkspace.seller,
      );
      // A new request starts over.
      expect(
        sides.resolve(shared, const ['seller side orders', 'my offers']),
        isA<AskSide>(),
      );
    });
  });

  group('AgentEngine side check', () {
    late ProviderContainer container;
    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    Future<AgentOutcome> say(
      String text,
      AgentSession session, {
      required String modelPicks,
      AgentEngine? engine,
    }) {
      final e =
          engine ??
          AgentEngine(
            llm: _ScriptedLlm(modelPicks),
            registry: ToolRegistry(const [
              _NamedTool('my_orders'),
              _NamedTool('seller_orders'),
            ]),
            memory: ConversationMemory(),
            router: null,
          );
      return e.run(
        text,
        runtime: AgentRuntimeContext(
          route: '/',
          languageCode: 'en',
          now: DateTime(2026, 11, 2),
          session: session,
        ),
        ref: container.read(_refProvider),
        cancelToken: CancelToken(),
      );
    }

    String ran(AgentOutcome o) => (o as AgentActionCompleted).summary;

    test('buyer screen: a wrong seller pick reads buyer orders', () async {
      final o = await say(
        'what is the current status of my recent jewelry order',
        _seller(AgentWorkspace.buyer),
        modelPicks: 'seller_orders',
      );
      expect(ran(o), startsWith('my_orders ran'));
    });

    test('seller workspace reads seller orders by default', () async {
      final o = await say(
        'show my orders',
        _seller(AgentWorkspace.seller),
        modelPicks: 'my_orders',
      );
      expect(ran(o), startsWith('seller_orders ran'));
    });

    test('shared page asks which side', () async {
      final o = await say(
        'show my orders',
        _seller(AgentWorkspace.shared),
        modelPicks: 'my_orders',
      );
      expect(o, isA<AgentClarification>());
      expect((o as AgentClarification).options, ['Buyer side', 'Seller side']);
    });

    test('router fast path is checked too', () async {
      final engine = AgentEngine(
        llm: _ScriptedLlm('my_orders'),
        registry: ToolRegistry(const [
          _NamedTool('my_orders'),
          _NamedTool('seller_orders'),
        ]),
        memory: ConversationMemory(),
        router: const LocalRouter(),
      );
      final o = await say(
        'orders received today',
        _seller(AgentWorkspace.buyer),
        modelPicks: 'my_orders',
        engine: engine,
      );
      expect(ran(o), 'seller_orders ran {period: today}');
    });
  });
}
