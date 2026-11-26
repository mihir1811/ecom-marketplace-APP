import 'dart:async';
import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/network/api_config.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/chat_product_type.dart';
import '../domain/models/chat_send_blocked.dart';
import 'mappers/chat_mapper.dart';

/// Thin Socket.IO wrapper for chat send + live MESSAGE events.
class ChatSocketClient {
  io.Socket? _socket;
  String? _userId;
  final _incoming = StreamController<ChatMessage>.broadcast();
  final _blocked = StreamController<ChatSendBlocked>.broadcast();

  Stream<ChatMessage> get incomingMessages => _incoming.stream;

  /// Sends the server dropped (`CHAT_SEND_BLOCKED`), only on this socket.
  Stream<ChatSendBlocked> get sendBlocked => _blocked.stream;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect({required String userId}) async {
    if (_socket != null && _userId == userId && isConnected) {
      _register(userId);
      return;
    }

    await disconnect();
    _userId = userId;

    final socket = io.io(
      ApiConfig.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) => _register(userId));
    socket.on('MESSAGE', _onMessage);
    socket.on('CHAT_SEND_BLOCKED', _onSendBlocked);
    socket.connect();
  }

  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null;
    _userId = null;
    if (socket == null) return;
    socket.off('MESSAGE');
    socket.off('CHAT_SEND_BLOCKED');
    socket.dispose();
  }

  Future<void> sendMessage({
    required String fromId,
    required String toId,
    required String message,
    String? productId,
    ChatProductType? productType,
    String? fileUrl,
    ChatMessageType messageType = ChatMessageType.text,
  }) async {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      throw StateError('Chat socket is not connected.');
    }

    final data = <String, dynamic>{
      'fromId': fromId,
      'toId': toId,
      'message': message,
      'messageType': switch (messageType) {
        ChatMessageType.text => 'TEXT',
        ChatMessageType.image => 'IMAGE',
        ChatMessageType.pdf => 'PDF',
      },
    };
    if (productId != null && productId.isNotEmpty) {
      data['productId'] = productId;
    }
    if (productType != null) {
      data['productType'] = productType.apiValue;
    }
    if (fileUrl != null && fileUrl.isNotEmpty) {
      data['fileUrl'] = fileUrl;
    }

    socket.emit(
      'CHAT_EVENT',
      jsonEncode({'type': 'SEND_MESSAGE', 'data': data}),
    );
  }

  void _register(String userId) {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emit(
      'CHAT_EVENT',
      jsonEncode({
        'type': 'REGISTER_SOCKET',
        'data': {'userId': userId},
      }),
    );
  }

  static Map<String, dynamic>? _decode(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _onSendBlocked(dynamic raw) {
    final map = _decode(raw);
    if (map == null) return;
    final event = ChatSendBlocked.fromJson(map);
    if (event != null && !_blocked.isClosed) _blocked.add(event);
  }

  void _onMessage(dynamic raw) {
    final myUserId = _userId;
    if (myUserId == null || myUserId.isEmpty) return;

    final map = _decode(raw);
    if (map == null) return;

    // Ignore ack / error envelopes without message id.
    if (map['id'] == null) return;
    if (map['fromId'] == null || map['toId'] == null) return;

    final message = ChatMapper.messageFromJson(map, myUserId: myUserId);
    if (message.id.isEmpty) return;
    if (!_incoming.isClosed) {
      _incoming.add(message);
    }
  }

  void dispose() {
    unawaited(disconnect());
    if (!_incoming.isClosed) {
      _incoming.close();
    }
    if (!_blocked.isClosed) {
      _blocked.close();
    }
  }
}
