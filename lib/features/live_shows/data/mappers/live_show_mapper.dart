import '../../domain/models/live_show_models.dart';

/// JSON → Live Shows models. Unknown fields are ignored.
abstract final class LiveShowMapper {
  /// `data` out of `{ success, message, data }`, or the root itself.
  static Object? data(Object? root) {
    if (root is Map && root.containsKey('data')) return root['data'];
    return root;
  }

  static List<Map<String, dynamic>> _maps(Object? raw) {
    if (raw is Map) {
      raw = raw['shows'] ?? raw['items'] ?? raw['messages'] ?? raw['data'];
    }
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  static Map<String, dynamic>? _map(Object? raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : null;

  static List<LiveShow> showsFromEnvelope(Object? root) => [
    for (final m in _maps(data(root))) showFromJson(m),
  ];

  static LiveShow? showFromEnvelope(Object? root) {
    final m = _map(data(root));
    return m == null ? null : showFromJson(m);
  }

  static LiveShow showFromJson(Map<String, dynamic> json) {
    final seller = _map(json['seller']) ?? const {};
    return LiveShow(
      id: _str(json['id']) ?? '',
      provider: LiveProvider.fromApi(json['provider']),
      title: _str(json['title']) ?? 'Live show',
      description: _str(json['description']),
      thumbnailUrl: _str(json['thumbnailUrl']),
      isLive: (_str(json['status']) ?? 'LIVE').toUpperCase() == 'LIVE',
      isStreaming: json['isStreaming'] == true,
      viewerCount: _int(json['viewerCount']) ?? 0,
      peakViewerCount: _int(json['peakViewerCount']) ?? 0,
      startedAt: _date(json['startedAt']),
      endedAt: _date(json['endedAt']),
      playbackUrl: _str(json['playbackUrl']),
      seller: LiveSeller(
        id: _str(seller['id']) ?? '',
        companyName: _str(seller['companyName']) ?? 'Seller',
        logo: _str(seller['companyLogo']),
      ),
    );
  }

  static LiveAuctionLot? lotFromJson(Object? raw) {
    final json = _map(raw);
    if (json == null) return null;
    final id = _str(json['id']);
    if (id == null) return null;
    final startingBid = _num(json['startingBid']) ?? 0;
    return LiveAuctionLot(
      id: id,
      status: LotStatus.fromApi(json['status']),
      position: _int(json['position']) ?? 0,
      productType: _str(json['productType']) ?? '',
      productId: _str(json['productId']) ?? '',
      title: _str(json['title']) ?? 'Lot',
      image: _str(json['image']),
      stockNumber: _str(json['stockNumber']),
      startingBid: startingBid,
      bidStep: _num(json['bidStep']) ?? 0,
      durationSeconds: _int(json['durationSeconds']) ?? 0,
      currentBid: _num(json['currentBid']),
      bidCount: _int(json['bidCount']) ?? 0,
      leaderName: _str(json['leaderName']),
      minNextBid: _num(json['minNextBid']) ?? startingBid,
      startedAt: _date(json['startedAt']),
      endsAt: _date(json['endsAt']),
      endedAt: _date(json['endedAt']),
      recentBids: [
        for (final b in _maps(json['recentBids']))
          LiveBid(
            amount: _num(b['amount']) ?? 0,
            bidderName: _str(b['bidderName']) ?? 'Bidder',
            at: _date(b['at']),
          ),
      ],
    );
  }

  static List<LiveAuctionLot> _lots(Object? raw) => [
    for (final m in _maps(raw)) ?lotFromJson(m),
  ];

  static ShowAuction auctionFromEnvelope(Object? root) {
    final json = _map(data(root)) ?? const {};
    return ShowAuction(
      serverTime: _date(json['serverTime']) ?? DateTime.now().toUtc(),
      current: lotFromJson(json['current']),
      upNext: _lots(json['upNext']),
      results: _lots(json['results']),
    );
  }

  static LiveWallet? walletFromJson(Object? raw) {
    final json = _map(raw);
    if (json == null) return null;
    final balance = _num(json['balance']) ?? 0;
    final held = _num(json['heldAmount']) ?? 0;
    return LiveWallet(
      balance: balance,
      heldAmount: held,
      availableBalance: _num(json['availableBalance']) ?? (balance - held),
    );
  }

  static MyShowState meFromEnvelope(Object? root) {
    final json = _map(data(root)) ?? const {};
    return MyShowState(
      wallet:
          walletFromJson(json['wallet']) ??
          const LiveWallet(balance: 0, heldAmount: 0, availableBalance: 0),
      leading: [
        for (final l in _maps(json['leading']))
          if (_str(l['lotId']) case final lotId?)
            LiveLeading(lotId: lotId, amount: _num(l['amount']) ?? 0),
      ],
      wins: [
        for (final w in _maps(json['wins']))
          if (_str(w['lotId']) case final lotId?)
            LiveWin(
              lotId: lotId,
              orderId: _str(w['orderId']) ?? '',
              amount: _num(w['amount']) ?? 0,
              title: _str(w['title']) ?? 'Lot',
            ),
      ],
      hasDeliveryAddress: json['hasDeliveryAddress'] == true,
      isSeller: json['isSeller'] == true,
      chatMuted: json['chatMuted'] == true,
    );
  }

  static LiveChatMessage? messageFromJson(Object? raw) {
    final json = _map(raw);
    if (json == null) return null;
    final id = _str(json['id']);
    if (id == null) return null;
    return LiveChatMessage(
      id: id,
      body: _str(json['body']) ?? '',
      authorName: _str(json['authorName']) ?? 'Guest',
      isSeller: json['isSeller'] == true,
      createdAt: _date(json['createdAt']),
    );
  }

  static List<LiveChatMessage> chatFromEnvelope(Object? root) => [
    for (final m in _maps(data(root))) ?messageFromJson(m),
  ];

  static LiveViewerToken? tokenFromEnvelope(Object? root) {
    final json = _map(data(root));
    final token = json == null ? null : _str(json['token']);
    if (token == null) return null;
    return LiveViewerToken(
      token: token,
      serverUrl: _str(json!['serverUrl']),
      expiresAt: _date(json['expiresAt']),
    );
  }

  static LiveBidResult? bidFromEnvelope(Object? root) {
    final json = _map(data(root));
    final lot = json == null ? null : lotFromJson(json['lot']);
    if (lot == null) return null;
    return LiveBidResult(lot: lot, wallet: walletFromJson(json!['wallet']));
  }

  /// Error body `{ statusCode, message, code?, minBid?, shortfall? ... }`.
  static LiveBidError bidErrorFromBody(Object? body, int? status) {
    final json = _map(body) ?? const {};
    final message = switch (json['message']) {
      final String m when m.trim().isNotEmpty => m.trim(),
      final List<dynamic> parts when parts.isNotEmpty => parts.join('\n'),
      _ => 'Your bid could not be placed. Please try again.',
    };
    final code =
        LiveBidErrorCode.fromApi(json['code']) ??
        switch (status) {
          401 => LiveBidErrorCode.signInRequired,
          403 => LiveBidErrorCode.forbidden,
          null => LiveBidErrorCode.network,
          _ => LiveBidErrorCode.invalid,
        };
    return LiveBidError(
      code: code,
      message: message,
      minBid: _num(json['minBid']),
      available: _num(json['available']),
      required: _num(json['required']),
      shortfall: _num(json['shortfall']),
    );
  }

  static String? _str(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty || s == 'null' ? null : s;
  }

  static double? _num(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  static int? _int(Object? v) => _num(v)?.round();

  static DateTime? _date(Object? v) {
    final s = _str(v);
    return s == null ? null : DateTime.tryParse(s)?.toUtc();
  }
}
