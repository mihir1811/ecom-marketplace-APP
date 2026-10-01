import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
///
/// Rooms are per connection on the server, so they are rejoined on every
/// connect. Events sent while disconnected are not replayed; [resync] fires
/// after a reconnect so watchers can fetch once to catch up.
class AuctionSocketClient {
  io.Socket? _socket;
  AppLifecycleListener? _lifecycle;
  final _events = StreamController<AuctionSocketEvent>.broadcast();
  final _resync = StreamController<void>.broadcast();
  final _auctionRooms = <String, int>{};
  final _sellerRooms = <String, int>{};
  var _liveCount = 0;
  var _missedEvents = false;

  Stream<AuctionSocketEvent> get events => _events.stream;

  /// Fires after the connection comes back from a drop.
  Stream<void> get resync => _resync.stream;

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
    if (_socket != null) return;
    // websocket only: on Android/iOS socket_io_client has no HTTP polling
    // transport, so listing `polling` first sends a websocket handshake with
    // `transport=polling`, which the server rejects and the app never connects.
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
      _rejoin();
      if (_missedEvents) {
        _missedEvents = false;
        if (!_resync.isClosed) _resync.add(null);
      }
    });
    socket.onDisconnect((reason) {
      _log('disconnected: $reason');
      _missedEvents = true;
      // The client does not auto-reconnect after a server-side disconnect.
      if (reason == 'io server disconnect' && identical(_socket, socket)) {
        socket.connect();
      }
    });
    socket.onConnectError((error) => _log('connect error: $error'));
    socket.on('AUCTION_BID', (raw) => _dispatch(raw, AuctionSocketKind.bid));
    socket.on(
      'AUCTION_UPDATED',
      (raw) => _dispatch(raw, AuctionSocketKind.updated),
    );
    // The server replies on MESSAGE when it rejects a CHAT_EVENT payload.
    socket.on('MESSAGE', (raw) => _log('server message: $raw'));
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    socket.connect();
  }

  void _dispatch(dynamic raw, AuctionSocketKind kind) {
    final event = auctionSocketEventFromRaw(raw, kind: kind);
    if (event == null) {
      _log('ignored ${kind.name} payload: $raw');
      return;
    }
    _log('${kind.name} ${event.auctionId} amount=${event.amount}');
    if (!_events.isClosed) _events.add(event);
  }

  /// Back from background: skip the reconnect backoff if the link dropped.
  /// A successful reconnect then fires [resync].
  void _onResume() {
    final socket = _socket;
    if (socket == null || socket.connected) return;
    _log('resumed while disconnected; reconnecting');
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

  /// Before the first connect this is a no-op; [_rejoin] sends it on connect.
  void _emit(String type, Map<String, dynamic> data) {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emit('CHAT_EVENT', jsonEncode({'type': type, 'data': data}));
    _log('$type $data');
  }

  void _maybeDisconnect() {
    if (_auctionRooms.isNotEmpty || _liveCount > 0 || _sellerRooms.isNotEmpty) {
      return;
    }
    _lifecycle?.dispose();
    _lifecycle = null;
    _missedEvents = false;
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    socket.clearListeners();
    socket.dispose();
    _log('closed (no rooms watched)');
  }

  void dispose() {
    _auctionRooms.clear();
    _sellerRooms.clear();
    _liveCount = 0;
    _maybeDisconnect();
    if (!_events.isClosed) _events.close();
    if (!_resync.isClosed) _resync.close();
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint('[AuctionSocket] $message');
  }
}

final auctionSocketProvider = Provider<AuctionSocketClient>((ref) {
  final client = AuctionSocketClient();
  ref.onDispose(client.dispose);
  return client;
});
