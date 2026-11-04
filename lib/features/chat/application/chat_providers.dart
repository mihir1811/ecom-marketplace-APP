import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../domain/chat_image_rules.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/chat_thread.dart';
import '../domain/models/product_chat_context.dart';
import '../domain/repositories/chat_repository.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

class ChatInboxState {
  const ChatInboxState({
    this.threads = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ChatThread> threads;
  final bool isLoading;
  final String? errorMessage;

  ChatInboxState copyWith({
    List<ChatThread>? threads,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatInboxState(
      threads: threads ?? this.threads,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ChatInboxNotifier extends Notifier<ChatInboxState>
    with DisposeTolerantNotifier<ChatInboxState> {
  CancelToken? _cancelToken;
  StreamSubscription<ChatMessage>? _socketSub;

  @override
  ChatInboxState build() {
    ref.onDispose(() {
      _cancelToken?.cancel();
      _socketSub?.cancel();
    });

    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId == null || userId.isEmpty) {
      _cancelToken?.cancel('signed-out');
      _socketSub?.cancel();
      _socketSub = null;
      return const ChatInboxState();
    }

    Future.microtask(() async {
      await ref.read(chatRepositoryProvider).connectSocket(userId: userId);
      if (!ref.mounted) return;
      await refresh();
    });
    _socketSub?.cancel();
    _socketSub = ref.read(chatRepositoryProvider).incomingMessages.listen((_) {
      refresh();
    });

    return const ChatInboxState(isLoading: true);
  }

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  Future<void> refresh() async {
    _cancelToken?.cancel('refresh');
    _cancelToken = CancelToken();
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repo.listThreads(cancelToken: _cancelToken);
    if (!ref.mounted) return;
    switch (result) {
      case Success(value: final threads):
        state = ChatInboxState(threads: threads);
      case ResultFailure(failure: final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }
}

final chatInboxProvider = NotifierProvider<ChatInboxNotifier, ChatInboxState>(
  ChatInboxNotifier.new,
);

/// True when any inbox thread has unread messages (app-bar chat dot).
final chatHasUnreadProvider = Provider<bool>((ref) {
  final threads = ref.watch(chatInboxProvider.select((s) => s.threads));
  for (final thread in threads) {
    if (thread.unreadCount > 0) return true;
  }
  return false;
});

class ChatThreadArgs {
  const ChatThreadArgs({
    required this.threadId,
    required this.productId,
    required this.productTypeApi,
    required this.peerUserId,
  });

  final String threadId;
  final String productId;
  final String productTypeApi;
  final String peerUserId;
}

class ChatThreadState {
  const ChatThreadState({
    this.messages = const [],
    this.context,
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
    this.sendError,
    this.pendingImage,
    this.uploadProgress,
  });

  final List<ChatMessage> messages;
  final ProductChatContext? context;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final String? sendError;

  /// Photo being uploaded, shown as a placeholder bubble until it is sent.
  final Uint8List? pendingImage;

  /// Upload progress of [pendingImage], 0–1.
  final double? uploadProgress;

  ChatThreadState copyWith({
    List<ChatMessage>? messages,
    ProductChatContext? context,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    String? sendError,
    Uint8List? pendingImage,
    double? uploadProgress,
    bool clearError = false,
    bool clearSendError = false,
    bool clearContext = false,
    bool clearPendingImage = false,
  }) {
    return ChatThreadState(
      messages: messages ?? this.messages,
      context: clearContext ? null : (context ?? this.context),
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sendError: clearSendError ? null : (sendError ?? this.sendError),
      pendingImage: clearPendingImage
          ? null
          : (pendingImage ?? this.pendingImage),
      uploadProgress: clearPendingImage
          ? null
          : (uploadProgress ?? this.uploadProgress),
    );
  }
}

class ChatThreadNotifier extends Notifier<ChatThreadState>
    with DisposeTolerantNotifier<ChatThreadState> {
  ChatThreadNotifier(this.arg);

  /// The family argument this notifier was created for.
  final ChatThreadArgs arg;

  CancelToken? _cancelToken;
  StreamSubscription<ChatMessage>? _socketSub;

  @override
  ChatThreadState build() {
    ref.onDispose(() {
      _cancelToken?.cancel();
      _socketSub?.cancel();
    });

    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId != null && userId.isNotEmpty) {
      Future.microtask(() async {
        await ref.read(chatRepositoryProvider).connectSocket(userId: userId);
        if (!ref.mounted) return;
        await refresh();
      });
      _socketSub?.cancel();
      _socketSub = ref
          .read(chatRepositoryProvider)
          .incomingMessages
          .listen(_onIncoming);
    }

    return const ChatThreadState(isLoading: true);
  }

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  bool _belongs(ChatMessage msg) {
    final productOk = msg.productId == arg.productId;
    final peerOk = msg.fromId == arg.peerUserId || msg.toId == arg.peerUserId;
    return productOk && peerOk;
  }

  void _onIncoming(ChatMessage msg) {
    if (!_belongs(msg)) return;
    final exists = state.messages.any((m) => m.id == msg.id);
    if (exists) return;
    final next = [...state.messages, msg]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = state.copyWith(messages: next);
    unawaited(_markUnread(next));
  }

  Future<void> refresh() async {
    _cancelToken?.cancel('refresh');
    _cancelToken = CancelToken();
    state = state.copyWith(isLoading: true, clearError: true);

    final type = ChatThread.decodeId(arg.threadId)?.productType;
    final listFuture = _repo.listMessages(
      productId: arg.productId,
      productType: type,
      limit: 100,
      cancelToken: _cancelToken,
    );
    final contextFuture = type == null
        ? null
        : _repo.getProductContext(
            productId: arg.productId,
            productType: type,
            cancelToken: _cancelToken,
          );

    final listResult = await listFuture;
    if (!ref.mounted) return;
    ProductChatContext? context = state.context;
    if (contextFuture != null) {
      final ctxResult = await contextFuture;
      if (!ref.mounted) return;
      if (ctxResult case Success(value: final value)) {
        context = value;
      }
    }

    switch (listResult) {
      case Success(value: final page):
        final filtered = page.items.where(_belongs).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        state = ChatThreadState(
          messages: filtered,
          context: context,
          isSending: state.isSending,
          pendingImage: state.pendingImage,
          uploadProgress: state.uploadProgress,
        );
        await _markUnread(filtered);
        if (!ref.mounted) return;
      case ResultFailure(failure: final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        state = state.copyWith(
          isLoading: false,
          context: context,
          errorMessage: failure.message,
        );
    }
  }

  Future<void> _markUnread(List<ChatMessage> messages) async {
    final unread = messages
        .where((m) => !m.isMine && !m.isRead)
        .map((m) => m.id)
        .toList();
    if (unread.isEmpty) return;
    await _repo.markAsRead(messageIds: unread);
    if (!ref.mounted) return;
    // Refresh inbox so app-bar / list unread dots clear after reading.
    unawaited(ref.read(chatInboxProvider.notifier).refresh());
  }

  Future<Result<void, Failure>> sendText(String text) async {
    final body = text.trim();
    if (body.isEmpty) {
      return Result.failure(const ValidationFailure('Message is empty.'));
    }
    final myId = ref.read(authProvider).user?.id;
    if (myId == null || myId.isEmpty) {
      return Result.failure(const AuthFailure('Please sign in again.'));
    }

    state = state.copyWith(isSending: true, clearSendError: true);
    final type = ChatThread.decodeId(arg.threadId)?.productType;
    final result = await _repo.sendMessage(
      fromId: myId,
      toId: arg.peerUserId,
      message: body,
      productId: arg.productId,
      productType: type,
    );

    switch (result) {
      case Success():
        state = state.copyWith(isSending: false);
        // Fallback refresh in case socket echo is delayed.
        Future<void>.delayed(const Duration(milliseconds: 600), refresh);
      case ResultFailure(failure: final failure):
        state = state.copyWith(isSending: false, sendError: failure.message);
    }
    return result;
  }

  /// Uploads [file] and sends it as an IMAGE message in this thread.
  Future<Result<void, Failure>> sendImage(XFile file) async {
    if (state.isSending) {
      return Result.failure(
        const ValidationFailure('Please wait for the current message.'),
      );
    }
    final myId = ref.read(authProvider).user?.id;
    if (myId == null || myId.isEmpty) {
      return Result.failure(const AuthFailure('Please sign in again.'));
    }

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      return _imageFailed('This photo could not be read.');
    }
    final rejection = chatImageRejection(
      fileName: file.name,
      bytes: bytes.length,
    );
    if (rejection != null) return _imageFailed(rejection);

    state = state.copyWith(
      isSending: true,
      clearSendError: true,
      pendingImage: bytes,
      uploadProgress: 0,
    );
    final uploaded = await _repo.uploadImage(
      file: file,
      onProgress: (progress) {
        if (state.pendingImage == null) return;
        state = state.copyWith(uploadProgress: progress);
      },
    );
    final String url;
    switch (uploaded) {
      case ResultFailure(:final failure):
        return _imageFailed('Photo upload failed: ${failure.message}');
      case Success(:final value):
        url = value;
    }

    final sent = await _repo.sendMessage(
      fromId: myId,
      toId: arg.peerUserId,
      message: '',
      productId: arg.productId,
      productType: ChatThread.decodeId(arg.threadId)?.productType,
      fileUrl: url,
      messageType: ChatMessageType.image,
    );
    switch (sent) {
      case Success():
        state = state.copyWith(isSending: false, clearPendingImage: true);
        // Fallback refresh in case socket echo is delayed.
        Future<void>.delayed(const Duration(milliseconds: 600), refresh);
      case ResultFailure(:final failure):
        return _imageFailed(failure.message);
    }
    return sent;
  }

  Result<void, Failure> _imageFailed(String message) {
    state = state.copyWith(
      isSending: false,
      sendError: message,
      clearPendingImage: true,
    );
    return Result.failure(ValidationFailure(message));
  }
}

final chatThreadProvider =
    NotifierProvider.family<
      ChatThreadNotifier,
      ChatThreadState,
      ChatThreadArgs
    >(ChatThreadNotifier.new);
