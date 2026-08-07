import 'dart:async';
import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/network/api_config.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/chat_product_type.dart';
import 'mappers/chat_mapper.dart';

/// Thin Socket.IO wrapper for chat send + live MESSAGE events.
class ChatSocketClient {
  io.Socket? _socket;
  String? _userId;
  final _incoming = StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get incomingMessages => _incoming.stream;

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
    socket.connect();
  }

  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null;
    _userId = null;
    if (socket == null) return;
    socket.off('MESSAGE');
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

  void _onMessage(dynamic raw) {
    final myUserId = _userId;
    if (myUserId == null || myUserId.isEmpty) return;

    Map<String, dynamic>? map;
    if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    } else if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) map = Map<String, dynamic>.from(decoded);
      } catch (_) {
        return;
      }
    }
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
  }
}
