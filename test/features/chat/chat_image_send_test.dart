import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/auth/auth_controller.dart';
import 'package:gemworld/core/auth/auth_providers.dart';
import 'package:gemworld/core/auth/auth_state.dart';
import 'package:gemworld/core/auth/auth_user.dart';
import 'package:gemworld/core/error/failure.dart';
import 'package:gemworld/core/error/result.dart';
import 'package:gemworld/features/chat/application/chat_providers.dart';
import 'package:gemworld/features/chat/data/mappers/chat_mapper.dart';
import 'package:gemworld/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:gemworld/features/chat/domain/models/chat_message.dart';
import 'package:gemworld/features/chat/domain/models/chat_product_type.dart';
import 'package:gemworld/features/chat/domain/models/chat_send_blocked.dart';
import 'package:gemworld/features/chat/domain/models/chat_thread.dart';
import 'package:gemworld/features/chat/domain/models/product_chat_context.dart';
import 'package:gemworld/features/chat/domain/repositories/chat_repository.dart';
import 'package:image_picker/image_picker.dart';

class _SignedIn extends AuthController {
  @override
  AuthState build() => const AuthState(
    user: AuthUser(
      id: 'me',
      fullName: 'Me',
      username: 'me',
      email: 'me@example.com',
      role: 'seller',
    ),
  );
}

class _Sent {
  _Sent(this.toId, this.message, this.fileUrl, this.type, this.productId);
  final String toId;
  final String message;
  final String? fileUrl;
  final ChatMessageType type;
  final String? productId;
}

class _FakeChatRepository implements ChatRepository {
  final sent = <_Sent>[];
  final uploads = <String>[];
  Result<String, Failure> uploadResult = Result.success(
    'https://cdn.example.com/chat/p.jpg',
  );
  final _incoming = StreamController<ChatMessage>.broadcast();

  @override
  Stream<ChatMessage> get incomingMessages => _incoming.stream;

  final blocked = StreamController<ChatSendBlocked>.broadcast();

  @override
  Stream<ChatSendBlocked> get sendBlocked => blocked.stream;

  @override
  Future<void> connectSocket({required String userId}) async {}

  @override
  Future<void> disconnectSocket() async {}

  @override
  Future<Result<ChatMessageListPage, Failure>> listMessages({
    int page = 1,
    int limit = 50,
    String? productId,
    ChatProductType? productType,
    CancelToken? cancelToken,
  }) async => Result.success(
    const ChatMessageListPage(
      items: [],
      total: 0,
      currentPage: 1,
      lastPage: 1,
      perPage: 50,
      hasMore: false,
    ),
  );

  @override
  Future<Result<List<ChatThread>, Failure>> listThreads({
    int limit = 100,
    CancelToken? cancelToken,
  }) async => Result.success(const []);

  @override
  Future<Result<ProductChatContext, Failure>> getProductContext({
    required String productId,
    required ChatProductType productType,
    CancelToken? cancelToken,
  }) async => Result.failure(const ValidationFailure('none'));

  @override
  Future<Result<List<String>, Failure>> markAsRead({
    required List<String> messageIds,
    CancelToken? cancelToken,
  }) async => Result.success(messageIds);

  @override
  Future<Result<void, Failure>> deleteMessage({
    required String messageId,
    CancelToken? cancelToken,
  }) async => Result.success(null);

  @override
  Future<Result<String, Failure>> uploadImage({
    required XFile file,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    uploads.add(file.name);
    onProgress?.call(0.5);
    onProgress?.call(1);
    return uploadResult;
  }

  @override
  Future<Result<void, Failure>> sendMessage({
    required String fromId,
    required String toId,
    required String message,
    String? productId,
    ChatProductType? productType,
    String? fileUrl,
    ChatMessageType messageType = ChatMessageType.text,
  }) async {
    sent.add(_Sent(toId, message, fileUrl, messageType, productId));
    return Result.success(null);
  }
}

void main() {
  final args = ChatThreadArgs(
    threadId: ChatThread.encodeId(
      productType: ChatProductType.diamond,
      productId: 'p1',
      peerUserId: 'peer',
    ),
    productId: 'p1',
    productTypeApi: 'diamond',
    peerUserId: 'peer',
  );

  late _FakeChatRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeChatRepository();
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_SignedIn.new),
        chatRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    container.listen(chatThreadProvider(args), (_, _) {});
  });

  XFile photo({String name = 'photo.jpg', int bytes = 2048}) => XFile.fromData(
    Uint8List(bytes),
    // On the VM `name` comes from `path`, as for a picked file.
    name: name,
    path: name,
    mimeType: 'image/jpeg',
  );

  ChatThreadNotifier notifier() =>
      container.read(chatThreadProvider(args).notifier);

  test(
    'uploads the photo, then sends it as an IMAGE message to the peer',
    () async {
      final result = await notifier().sendImage(photo());

      expect(result, isA<Success<void, Failure>>());
      expect(repo.uploads, ['photo.jpg']);
      expect(repo.sent, hasLength(1));
      final message = repo.sent.single;
      expect(message.type, ChatMessageType.image);
      expect(message.fileUrl, 'https://cdn.example.com/chat/p.jpg');
      expect(message.toId, 'peer');
      expect(message.productId, 'p1');

      final state = container.read(chatThreadProvider(args));
      expect(state.isSending, isFalse);
      expect(state.pendingImage, isNull);
      expect(state.sendError, isNull);
    },
  );

  test('upload failure shows an error and sends nothing', () async {
    repo.uploadResult = Result.failure(const NetworkFailure('Timed out'));

    final result = await notifier().sendImage(photo());

    expect(result, isA<ResultFailure<void, Failure>>());
    expect(repo.sent, isEmpty);
    final state = container.read(chatThreadProvider(args));
    expect(state.sendError, contains('Photo upload failed'));
    expect(state.isSending, isFalse);
    expect(state.pendingImage, isNull);
  });

  test(
    'photos over 5 MB and unsupported formats are rejected up front',
    () async {
      await notifier().sendImage(photo(bytes: 6 * 1024 * 1024));
      expect(
        container.read(chatThreadProvider(args)).sendError,
        'Photos must be 5 MB or smaller.',
      );

      await notifier().sendImage(photo(name: 'IMG_1.HEIC'));
      expect(
        container.read(chatThreadProvider(args)).sendError,
        contains('JPEG, PNG, WebP and GIF'),
      );
      expect(repo.uploads, isEmpty);
    },
  );

  test('text messages still send as TEXT', () async {
    await notifier().sendText('  Is it available?  ');
    expect(repo.sent.single.type, ChatMessageType.text);
    expect(repo.sent.single.message, 'Is it available?');
    expect(repo.sent.single.fileUrl, isNull);
  });

  test('image messages from the socket keep their file URL and sender', () {
    final message = ChatMapper.messageFromJson({
      'id': 'm1',
      'fromId': 'peer',
      'toId': 'me',
      'message': '',
      'messageType': 'IMAGE',
      'fileUrl': '/uploads/chat/p.jpg',
      'productId': 'p1',
      'productType': 'diamond',
      'createdAt': '2026-10-01T10:00:00.000Z',
    }, myUserId: 'me');

    expect(message.messageType, ChatMessageType.image);
    expect(message.isMine, isFalse);
    expect(message.fileUrl, endsWith('/uploads/chat/p.jpg'));
    expect(Uri.parse(message.fileUrl!).hasScheme, isTrue);
  });

  group('CHAT_SEND_BLOCKED', () {
    const notice =
        'You can send another message after this buyer replies to you.';

    ChatSendBlocked event({String toId = 'peer'}) => ChatSendBlocked(
      code: 'CART_OUTREACH_AWAITING_REPLY',
      message: notice,
      toId: toId,
      productId: 'p1',
    );

    test('shows the notice and hands the text back', () async {
      await notifier().sendText('Still interested?');
      repo.blocked.add(event());
      await Future<void>.delayed(Duration.zero);

      final state = container.read(chatThreadProvider(args));
      expect(state.sendError, notice);
      expect(state.sendBlocked, isTrue);
      expect(state.restoreDraft, 'Still interested?');
      expect(state.restoreSeq, 1);
      expect(state.messages, isEmpty);
    });

    test('ignores events for another chat', () async {
      await notifier().sendText('Hello');
      repo.blocked.add(event(toId: 'someone-else'));
      await Future<void>.delayed(Duration.zero);

      final state = container.read(chatThreadProvider(args));
      expect(state.sendError, isNull);
      expect(state.sendBlocked, isFalse);
    });

    test('a refresh keeps the notice; the buyer writing clears it', () async {
      await notifier().sendText('Hello');
      repo.blocked.add(event());
      await Future<void>.delayed(Duration.zero);
      await notifier().refresh();
      expect(container.read(chatThreadProvider(args)).sendError, notice);

      repo._incoming.add(
        ChatMessage(
          id: 'm1',
          fromId: 'peer',
          toId: 'me',
          body: 'Yes, tell me more',
          messageType: ChatMessageType.text,
          createdAt: DateTime(2026, 11, 24),
          isRead: false,
          isMine: false,
          productId: 'p1',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(chatThreadProvider(args));
      expect(state.sendError, isNull);
      expect(state.sendBlocked, isFalse);
    });

    test('parses the socket payload', () {
      final parsed = ChatSendBlocked.fromJson({
        'code': 'CART_OUTREACH_AWAITING_REPLY',
        'message': notice,
        'toId': 'buyer-1',
        'productId': null,
      });
      expect(parsed?.toId, 'buyer-1');
      expect(parsed?.productId, isNull);
      expect(parsed?.message, notice);
      expect(ChatSendBlocked.fromJson({'message': 'x'}), isNull);
    });
  });
}
