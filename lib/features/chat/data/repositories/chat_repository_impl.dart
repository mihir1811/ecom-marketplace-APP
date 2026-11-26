import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/chat_image_rules.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_product_type.dart';
import '../../domain/models/chat_send_blocked.dart';
import '../../domain/models/chat_thread.dart';
import '../../domain/models/product_chat_context.dart';
import '../../domain/repositories/chat_repository.dart';
import '../chat_socket_client.dart';
import '../mappers/chat_mapper.dart';

final chatSocketClientProvider = Provider<ChatSocketClient>((ref) {
  final client = ChatSocketClient();
  ref.onDispose(client.dispose);
  return client;
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(chatSocketClientProvider),
    () => ref.read(authProvider).user?.id ?? '',
  );
});

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._dio, this._socket, this._currentUserId);

  final Dio _dio;
  final ChatSocketClient _socket;
  final String Function() _currentUserId;

  @override
  Stream<ChatMessage> get incomingMessages => _socket.incomingMessages;

  @override
  Stream<ChatSendBlocked> get sendBlocked => _socket.sendBlocked;

  @override
  Future<void> connectSocket({required String userId}) =>
      _socket.connect(userId: userId);

  @override
  Future<void> disconnectSocket() => _socket.disconnect();

  @override
  Future<Result<ChatMessageListPage, Failure>> listMessages({
    int page = 1,
    int limit = 50,
    String? productId,
    ChatProductType? productType,
    CancelToken? cancelToken,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page < 1 ? 1 : page,
        'limit': limit < 1 ? 10 : limit,
      };
      if (productId != null && productId.isNotEmpty) {
        query['productId'] = productId;
      }
      if (productType != null) {
        query['productType'] = productType.apiValue;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.chat,
        queryParameters: query,
        cancelToken: cancelToken,
      );

      return Result.success(
        _parseListPage(response.data, page, limit, _currentUserId()),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ChatThread>, Failure>> listThreads({
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    final result = await listMessages(
      page: 1,
      limit: limit,
      cancelToken: cancelToken,
    );
    return switch (result) {
      Success(value: final page) => Result.success(
        ChatMapper.threadsFromMessages(
          messages: page.items,
          myUserId: _currentUserId(),
        ),
      ),
      ResultFailure(failure: final failure) => Result.failure(failure),
    };
  }

  @override
  Future<Result<ProductChatContext, Failure>> getProductContext({
    required String productId,
    required ChatProductType productType,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.chatProductContext,
        queryParameters: {
          'productId': productId,
          'productType': productType.apiValue,
        },
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map) {
        return Result.failure(
          const ValidationFailure('Product context not found.'),
        );
      }
      return Result.success(
        ChatMapper.contextFromJson(Map<String, dynamic>.from(data)),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<String>, Failure>> markAsRead({
    required List<String> messageIds,
    CancelToken? cancelToken,
  }) async {
    if (messageIds.isEmpty) {
      return Result.success(const <String>[]);
    }
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.chatRead,
        data: {'messageIds': messageIds},
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is Map && data['messageIds'] is List) {
        final ids = (data['messageIds'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
        return Result.success(ids);
      }
      return Result.success(const <String>[]);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteMessage({
    required String messageId,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.chatMessageById(messageId),
        cancelToken: cancelToken,
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<String, Failure>> uploadImage({
    required XFile file,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // Bytes (not a path) so the same upload works on web.
      final bytes = await file.readAsBytes();
      final filename = file.name.trim().isEmpty ? 'chat-image.jpg' : file.name;
      final form = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          // The backend accepts JPEG/PNG/WebP/GIF by MIME type; without it
          // Dio would send application/octet-stream for unknown extensions.
          contentType: DioMediaType.parse(chatImageMimeType(file)),
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.chatUploadImage,
        data: form,
        cancelToken: cancelToken,
        onSendProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onProgress(sent / total);
              },
      );
      final data = response.data?['data'];
      final url = data is Map ? data['url']?.toString() : null;
      if (url == null || url.isEmpty) {
        return Result.failure(
          const UnknownFailure('Unexpected upload response.'),
        );
      }
      return Result.success(url);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
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
    try {
      if (!_socket.isConnected) {
        await _socket.connect(userId: fromId);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      await _socket.sendMessage(
        fromId: fromId,
        toId: toId,
        message: message,
        productId: productId,
        productType: productType,
        fileUrl: fileUrl,
        messageType: messageType,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        const NetworkFailure('Could not send message. Check your connection.'),
      );
    }
  }

  ChatMessageListPage _parseListPage(
    Map<String, dynamic>? root,
    int page,
    int limit,
    String myUserId,
  ) {
    final dataNode = root?['data'];
    final payload = dataNode is Map
        ? Map<String, dynamic>.from(dataNode)
        : const {};
    final itemsJson = payload['data'];
    final metaJson = payload['meta'];
    final meta = metaJson is Map
        ? Map<String, dynamic>.from(metaJson)
        : const {};

    final list = itemsJson is List ? itemsJson : const [];
    final items = <ChatMessage>[];
    for (final item in list) {
      if (item is! Map) continue;
      final message = ChatMapper.messageFromJson(
        Map<String, dynamic>.from(item),
        myUserId: myUserId,
      );
      if (message.id.isEmpty) continue;
      items.add(message);
    }

    final total = _asInt(meta['total']) ?? items.length;
    final currentPage = _asInt(meta['currentPage']) ?? page;
    final lastPage = _asInt(meta['lastPage']) ?? currentPage;
    final perPage = _asInt(meta['perPage']) ?? limit;
    final hasMore = meta.containsKey('next')
        ? meta['next'] != null
        : currentPage < lastPage;

    return ChatMessageListPage(
      items: items,
      total: total,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      hasMore: hasMore,
    );
  }

  int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
