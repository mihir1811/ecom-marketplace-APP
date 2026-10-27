import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/network/api_config.dart';
import '../domain/models/live_show_models.dart';
import 'mappers/live_show_mapper.dart';

/// One push from a show's room.
sealed class LiveShowEvent {
  const LiveShowEvent();
}

class LiveLotEvent extends LiveShowEvent {
  const LiveLotEvent(this.lot);
  final LiveAuctionLot lot;
}

class LiveLineupEvent extends LiveShowEvent {
  const LiveLineupEvent();
}

class LiveChatEvent extends LiveShowEvent {
  const LiveChatEvent(this.message);
  final LiveChatMessage message;
}

class LiveChatDeletedEvent extends LiveShowEvent {
  const LiveChatDeletedEvent(this.messageId);
  final String messageId;
}

class LiveLikesEvent extends LiveShowEvent {
  const LiveLikesEvent(this.delta);
  final int delta;
}

/// Parses a room payload (map, list, or JSON string) for [showId].
/// Returns `null` for another show or an unreadable payload.
LiveShowEvent? liveShowEventFromRaw(
  String type,
  dynamic raw, {
  required String showId,
}) {
  if (raw is List && raw.isNotEmpty) {
    return liveShowEventFromRaw(type, raw.first, showId: showId);
  }
  Map<String, dynamic>? map;
  if (raw is Map) {
    map = Map<String, dynamic>.from(raw);
  } else if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) map = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }
  if (map == null) return null;
  if (map['showId'] == null && map['data'] is Map) {
    map = Map<String, dynamic>.from(map['data'] as Map);
  }
  if (map['showId']?.toString() != showId) return null;

  switch (type) {
    case 'LIVE_AUCTION_LOT':
      final lot = LiveShowMapper.lotFromJson(map['lot']);
      return lot == null ? null : LiveLotEvent(lot);
    case 'LIVE_AUCTION_LINEUP':
      return const LiveLineupEvent();
    case 'LIVE_CHAT_MESSAGE':
      final message = LiveShowMapper.messageFromJson(map['message']);
      return message == null ? null : LiveChatEvent(message);
    case 'LIVE_CHAT_DELETED':
      final id = map['messageId']?.toString();
      return id == null || id.isEmpty ? null : LiveChatDeletedEvent(id);
    case 'LIVE_SHOW_LIKES':
      final delta = map['delta'];
      final n = delta is num ? delta.round() : int.tryParse('$delta') ?? 0;
      return n <= 0 ? null : LiveLikesEvent(n);
  }
  return null;
}

/// Builds the room link for a show; overridden in tests.
final liveShowSocketFactoryProvider = Provider<LiveShowSocket Function(String)>(
  (ref) => LiveShowSocket.new,
);

/// Socket.IO link to one show's public room.
///
/// Joins with `CHAT_EVENT` `JOIN_LIVE_SHOW` on every connect. Nothing is
/// replayed after a drop, so [resync] fires on each reconnect and the
/// owner refetches the auction, its own state and the chat.
class LiveShowSocket {
  LiveShowSocket(this.showId);

  final String showId;
  io.Socket? _socket;
  var _connectedOnce = false;
  final _events = StreamController<LiveShowEvent>.broadcast();
  final _resync = StreamController<void>.broadcast();

  static const _types = [
    'LIVE_AUCTION_LOT',
    'LIVE_AUCTION_LINEUP',
    'LIVE_CHAT_MESSAGE',
    'LIVE_CHAT_DELETED',
    'LIVE_SHOW_LIKES',
  ];

  Stream<LiveShowEvent> get events => _events.stream;
  Stream<void> get resync => _resync.stream;

  void connect() {
    if (_socket != null) return;
    // websocket only: see AuctionSocketClient for why polling breaks mobile.
    final socket = io.io(
      ApiConfig.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );
    _socket = socket;
    socket.onConnect((_) {
      _log('connected ${socket.id}');
      _emit('JOIN_LIVE_SHOW');
      if (_connectedOnce && !_resync.isClosed) _resync.add(null);
      _connectedOnce = true;
    });
    socket.onDisconnect((reason) {
      _log('disconnected: $reason');
      if (reason == 'io server disconnect' && identical(_socket, socket)) {
        socket.connect();
      }
    });
    socket.onConnectError((error) => _log('connect error: $error'));
    for (final type in _types) {
      socket.on(type, (raw) {
        final event = liveShowEventFromRaw(type, raw, showId: showId);
        if (event != null && !_events.isClosed) _events.add(event);
      });
    }
    socket.connect();
  }

  /// Leaves the room and closes the link; [connect] opens a fresh one.
  void disconnect() {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    if (socket.connected) _emit('LEAVE_LIVE_SHOW', socket: socket);
    socket.clearListeners();
    socket.dispose();
    _log('closed');
  }

  void dispose() {
    disconnect();
    if (!_events.isClosed) _events.close();
    if (!_resync.isClosed) _resync.close();
  }

  void _emit(String type, {io.Socket? socket}) {
    final s = socket ?? _socket;
    if (s == null || !s.connected) return;
    s.emit('CHAT_EVENT', {
      'type': type,
      'data': {'showId': showId},
    });
    _log('$type $showId');
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint('[LiveShowSocket] $message');
  }
}
