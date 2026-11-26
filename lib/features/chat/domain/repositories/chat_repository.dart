import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/chat_message.dart';
import '../models/chat_product_type.dart';
import '../models/chat_send_blocked.dart';
import '../models/chat_thread.dart';
import '../models/product_chat_context.dart';

abstract class ChatRepository {
  Future<Result<ChatMessageListPage, Failure>> listMessages({
    int page = 1,
    int limit = 50,
    String? productId,
    ChatProductType? productType,
    CancelToken? cancelToken,
  });

  Future<Result<List<ChatThread>, Failure>> listThreads({
    int limit = 100,
    CancelToken? cancelToken,
  });

  Future<Result<ProductChatContext, Failure>> getProductContext({
    required String productId,
    required ChatProductType productType,
    CancelToken? cancelToken,
  });

  Future<Result<List<String>, Failure>> markAsRead({
    required List<String> messageIds,
    CancelToken? cancelToken,
  });

  Future<Result<void, Failure>> deleteMessage({
    required String messageId,
    CancelToken? cancelToken,
  });

  /// Uploads a picked photo and returns its public URL.
  Future<Result<String, Failure>> uploadImage({
    required XFile file,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  });

  Future<Result<void, Failure>> sendMessage({
    required String fromId,
    required String toId,
    required String message,
    String? productId,
    ChatProductType? productType,
    String? fileUrl,
    ChatMessageType messageType = ChatMessageType.text,
  });

  Future<void> connectSocket({required String userId});

  Future<void> disconnectSocket();

  Stream<ChatMessage> get incomingMessages;

  /// The server dropped one of this user's sends (`CHAT_SEND_BLOCKED`).
  Stream<ChatSendBlocked> get sendBlocked;
}
