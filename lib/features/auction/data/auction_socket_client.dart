import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/network/api_config.dart';

enum AuctionSocketKind { bid, updated }

/// Server push for `AUCTION_BID` / `AUCTION_UPDATED`.
class AuctionSocketEvent {
  const AuctionSocketEvent({
    required this.kind,
    required this.auctionId,
    this.amount,
  });

  final AuctionSocketKind kind;
  final String auctionId;
  final double? amount;
}

/// Parses a Socket.IO auction payload (map, list, or JSON string).
AuctionSocketEvent? auctionSocketEventFromRaw(
  dynamic raw, {
  required AuctionSocketKind kind,
}) {
  if (raw is List && raw.isNotEmpty) {
    return auctionSocketEventFromRaw(raw.first, kind: kind);
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

  final nested = map['data'];
  if (map['auctionId'] == null && nested is Map) {
    map = Map<String, dynamic>.from(nested);
  }

  final id = map['auctionId'] ?? map['auction_id'];
  if (id == null) return null;
  final auctionId = id.toString().trim();
  if (auctionId.isEmpty || auctionId == 'null' || auctionId == 'NaN') {
    return null;
  }

  final rawAmount = map['amount'] ?? map['bidAmount'] ?? map['highestBid'];
  return AuctionSocketEvent(
    kind: kind,
    auctionId: auctionId,
    amount: _socketAmount(rawAmount),
  );
}

double? _socketAmount(Object? raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw.trim());
  if (raw is Map) {
    return _socketAmount(raw['amount'] ?? raw['highestBid']);
  }
  return null;
}

/// Shared Socket.IO client for live auction rooms.
///
/// Joins through `CHAT_EVENT` (`JOIN_AUCTION_ROOM`, `JOIN_LIVE_AUCTIONS`,
/// `JOIN_SELLER_AUCTIONS`) and listens for `AUCTION_BID` / `AUCTION_UPDATED`.
class AuctionSocketClient {
  io.Socket? _socket;
  final _events = StreamController<AuctionSocketEvent>.broadcast();
  final _auctionRooms = <String, int>{};
  final _sellerRooms = <String, int>{};
  var _liveCount = 0;

  Stream<AuctionSocketEvent> get events => _events.stream;

  void watchAuction(String auctionId) {
    if (auctionId.isEmpty) return;
    _auctionRooms.update(auctionId, (count) => count + 1, ifAbsent: () => 1);
    _ensureConnected();
    _emit('JOIN_AUCTION_ROOM', {'auctionId': auctionId});
  }

  void unwatchAuction(String auctionId) {
    final next = (_auctionRooms[auctionId] ?? 0) - 1;
    if (next <= 0) {
      _auctionRooms.remove(auctionId);
      _emit('LEAVE_AUCTION_ROOM', {'auctionId': auctionId});
    } else {
      _auctionRooms[auctionId] = next;
    }
    _maybeDisconnect();
  }

  void watchLive() {
    _liveCount += 1;
    _ensureConnected();
    _emit('JOIN_LIVE_AUCTIONS', {'scope': 'live'});
  }

  void unwatchLive() {
    if (_liveCount > 0) _liveCount -= 1;
    if (_liveCount == 0) {
      _emit('LEAVE_LIVE_AUCTIONS', {'scope': 'live'});
    }
    _maybeDisconnect();
  }

  void watchSeller(String sellerId) {
    if (sellerId.isEmpty) return;
    _sellerRooms.update(sellerId, (count) => count + 1, ifAbsent: () => 1);
    _ensureConnected();
    _emit('JOIN_SELLER_AUCTIONS', {'sellerId': sellerId});
  }

  void unwatchSeller(String sellerId) {
    final next = (_sellerRooms[sellerId] ?? 0) - 1;
    if (next <= 0) {
      _sellerRooms.remove(sellerId);
      _emit('LEAVE_SELLER_AUCTIONS', {'sellerId': sellerId});
    } else {
      _sellerRooms[sellerId] = next;
    }
    _maybeDisconnect();
  }

  void _ensureConnected() {
    final existing = _socket;
    if (existing != null) {
      if (existing.connected) _rejoin();
      return;
    }
    final socket = io.io(
      ApiConfig.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['polling', 'websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );
    _socket = socket;
    socket.onConnect((_) => _rejoin());
    socket.on('AUCTION_BID', (raw) {
      final event = auctionSocketEventFromRaw(raw, kind: AuctionSocketKind.bid);
      if (event != null && !_events.isClosed) _events.add(event);
    });
    socket.on('AUCTION_UPDATED', (raw) {
      final event = auctionSocketEventFromRaw(
        raw,
        kind: AuctionSocketKind.updated,
      );
      if (event != null && !_events.isClosed) _events.add(event);
    });
    socket.connect();
  }

  void _rejoin() {
    for (final auctionId in _auctionRooms.keys) {
      _emit('JOIN_AUCTION_ROOM', {'auctionId': auctionId});
    }
    if (_liveCount > 0) {
      _emit('JOIN_LIVE_AUCTIONS', {'scope': 'live'});
    }
    for (final sellerId in _sellerRooms.keys) {
      _emit('JOIN_SELLER_AUCTIONS', {'sellerId': sellerId});
    }
  }

  void _emit(String type, Map<String, dynamic> data) {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emit('CHAT_EVENT', jsonEncode({'type': type, 'data': data}));
  }

  void _maybeDisconnect() {
    if (_auctionRooms.isNotEmpty || _liveCount > 0 || _sellerRooms.isNotEmpty) {
      return;
    }
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    socket.off('AUCTION_BID');
    socket.off('AUCTION_UPDATED');
    socket.dispose();
  }

  void dispose() {
    _auctionRooms.clear();
    _sellerRooms.clear();
    _liveCount = 0;
    _maybeDisconnect();
    if (!_events.isClosed) _events.close();
  }
}

final auctionSocketProvider = Provider<AuctionSocketClient>((ref) {
  final client = AuctionSocketClient();
  ref.onDispose(client.dispose);
  return client;
});
