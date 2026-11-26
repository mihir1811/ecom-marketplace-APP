import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/auth/auth_controller.dart';
import 'package:gemworld/core/auth/auth_providers.dart';
import 'package:gemworld/core/auth/auth_state.dart';
import 'package:gemworld/core/auth/auth_user.dart';
import 'package:gemworld/core/error/failure.dart';
import 'package:gemworld/core/error/result.dart';
import 'package:gemworld/core/router/route_names.dart';
import 'package:gemworld/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:gemworld/features/chat/domain/models/chat_message.dart';
import 'package:gemworld/features/chat/domain/models/chat_product_type.dart';
import 'package:gemworld/features/chat/domain/models/chat_send_blocked.dart';
import 'package:gemworld/features/chat/domain/models/chat_thread.dart';
import 'package:gemworld/features/chat/domain/repositories/chat_repository.dart';
import 'package:gemworld/features/notifications/application/chat_message_alerts.dart';
import 'package:gemworld/features/notifications/application/in_app_notification_provider.dart';
import 'package:gemworld/features/notifications/data/mappers/notification_mapper.dart';
import 'package:gemworld/features/notifications/domain/notification_open_target.dart';

class _SignedIn extends AuthController {
  @override
  AuthState build() => const AuthState(
    user: AuthUser(
      id: 'me',
      fullName: 'Me',
      username: 'me',
      email: 'me@example.com',
      role: 'buyer',
    ),
  );
}

/// Only what the session needs: the socket stream and an empty inbox.
class _SocketOnlyChatRepository implements ChatRepository {
  final socket = StreamController<ChatMessage>.broadcast();
  var connects = 0;
  var listCalls = 0;

  @override
  Stream<ChatMessage> get incomingMessages => socket.stream;

  @override
  Stream<ChatSendBlocked> get sendBlocked => const Stream.empty();

  @override
  Future<void> connectSocket({required String userId}) async => connects++;

  @override
  Future<Result<List<ChatThread>, Failure>> listThreads({
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    listCalls++;
    return Result.success(const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ChatMessage _message({
  String id = 'm1',
  String from = 'peer',
  String to = 'me',
  String body = 'Is the 1.02ct still available?',
  ChatMessageType type = ChatMessageType.text,
}) {
  return ChatMessage(
    id: id,
    fromId: from,
    toId: to,
    body: body,
    messageType: type,
    createdAt: DateTime(2026, 10, 1, 10),
    isRead: false,
    isMine: from == 'me',
    productId: 'p1',
    productType: ChatProductType.diamond,
    from: ChatParticipant(id: from, name: 'Shree Gems', role: 'seller'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('chat socket → in-app banner', () {
    late _SocketOnlyChatRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = _SocketOnlyChatRepository();
      container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_SignedIn.new),
          chatRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(chatMessageAlertsProvider, (_, _) {});
    });

    Future<void> deliver(ChatMessage message) async {
      repo.socket.add(message);
      await Future<void>.delayed(Duration.zero);
    }

    test('connects the chat socket for the session, without polling', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.connects, 1);
      final listCallsAtStart = repo.listCalls;

      // Nothing else is fetched while no event arrives.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(repo.listCalls, listCallsAtStart);
    });

    test('a message to me shows a banner immediately', () async {
      await deliver(_message());
      final banner = container.read(inAppNotificationProvider).current;
      expect(banner, isNotNull);
      expect(banner!.type, 'CHAT_MESSAGE');
      expect(banner.title, 'Shree Gems');
      expect(banner.body, 'Is the 1.02ct still available?');
      expect(banner.data['senderId'], 'peer');
    });

    test(
      'my own echoed messages and other users\' messages are ignored',
      () async {
        await deliver(_message(from: 'me', to: 'peer'));
        await deliver(_message(id: 'm2', to: 'someone-else'));
        expect(container.read(inAppNotificationProvider).current, isNull);
      },
    );

    test('a photo message says so', () async {
      await deliver(_message(body: '', type: ChatMessageType.image));
      expect(
        container.read(inAppNotificationProvider).current!.body,
        'Sent you a photo',
      );
    });

    test('several messages queue instead of overlapping', () async {
      await deliver(_message(id: 'a', from: 'p1'));
      await deliver(_message(id: 'b', from: 'p2'));
      final state = container.read(inAppNotificationProvider);
      expect(state.current!.data['messageId'], 'a');
      expect(state.queue.map((n) => n.data['messageId']), ['b']);
    });
  });

  group('InAppNotificationController de-duplication', () {
    test('the push copy of a socket message is not shown again', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(inAppNotificationProvider.notifier);

      controller.show(NotificationMapper.fromChatMessage(_message()));
      controller.dismiss();

      // Same message delivered later by FCM, after the banner was closed.
      controller.show(
        NotificationMapper.fromPush(
          {'type': 'CHAT_MESSAGE', 'senderId': 'peer', 'messageId': 'm1'},
          title: 'Shree Gems',
          body: 'Is the 1.02ct still available?',
        ),
      );
      expect(container.read(inAppNotificationProvider).current, isNull);
    });
  });

  group('chat routing helpers', () {
    final threadId = ChatThread.encodeId(
      productType: ChatProductType.diamond,
      productId: 'p1',
      peerUserId: 'peer',
    );

    test('reads the open conversation from a chat detail path', () {
      expect(activeChatThread(AppRouteNames.sellerChatDetailPath(threadId)), (
        productId: 'p1',
        peerUserId: 'peer',
      ));
      expect(activeChatThread(AppRouteNames.buyerChatDetailPath(threadId)), (
        productId: 'p1',
        peerUserId: 'peer',
      ));
      expect(activeChatThread(AppRouteNames.sellerChat), isNull);
      expect(activeChatThread('/auctions/a1'), isNull);
    });

    test('tapping a chat banner opens that conversation', () {
      final target = notificationOpenTarget(
        NotificationMapper.fromChatMessage(_message()),
        isSeller: true,
      );
      expect(
        (target as NotificationInApp).route,
        AppRouteNames.sellerChatDetailPath(threadId),
      );

      final noProduct = notificationOpenTarget(
        NotificationMapper.fromPush({'type': 'CHAT_MESSAGE'}, title: 'Hi'),
        isSeller: false,
      );
      expect(
        (noProduct as NotificationInApp).route,
        AppRouteNames.buyerMessages,
      );
    });
  });
}
