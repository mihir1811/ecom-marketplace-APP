/// Buyer-side Live Shows models (`/live/*`). Money is rupees end to end.
library;

/// Streaming service a show plays on; read per show.
enum LiveProvider {
  livekit,
  awsIvsRealtime,
  awsIvs,
  cloudflare,
  unknown;

  /// Tolerates case and separators (`LiveKit`, `aws-ivs-realtime`,
  /// `IVS_REAL_TIME`, `cloudflare_stream`).
  static LiveProvider fromApi(Object? raw) {
    final key = (raw?.toString() ?? '').toUpperCase().replaceAll(
      RegExp('[^A-Z0-9]'),
      '',
    );
    if (key.isEmpty) return LiveProvider.unknown;
    if (key.contains('LIVEKIT')) return LiveProvider.livekit;
    if (key.contains('IVS')) {
      return key.contains('REALTIME') || key.contains('STAGE')
          ? LiveProvider.awsIvsRealtime
          : LiveProvider.awsIvs;
    }
    if (key.contains('CLOUDFLARE')) return LiveProvider.cloudflare;
    return LiveProvider.unknown;
  }

  /// [fromApi], falling back to what [playbackUrl] looks like when the
  /// provider is missing or new.
  static LiveProvider resolve(Object? raw, String? playbackUrl) {
    final named = fromApi(raw);
    if (named != LiveProvider.unknown) return named;
    final url = (playbackUrl ?? '').toLowerCase();
    if (url.isEmpty) return LiveProvider.unknown;
    if (url.contains('livekit') ||
        url.startsWith('wss://') ||
        url.startsWith('ws://')) {
      return LiveProvider.livekit;
    }
    if (url.contains('.m3u8')) return LiveProvider.awsIvs;
    if (url.contains('cloudflarestream') || url.contains('videodelivery')) {
      return LiveProvider.cloudflare;
    }
    return LiveProvider.unknown;
  }
}

class LiveSeller {
  const LiveSeller({required this.id, required this.companyName, this.logo});

  final String id;
  final String companyName;
  final String? logo;
}

class LiveShow {
  const LiveShow({
    required this.id,
    required this.provider,
    required this.title,
    required this.isLive,
    required this.isStreaming,
    required this.viewerCount,
    required this.seller,
    this.description,
    this.thumbnailUrl,
    this.peakViewerCount = 0,
    this.startedAt,
    this.endedAt,
    this.playbackUrl,
  });

  final String id;
  final LiveProvider provider;
  final String title;
  final String? description;
  final String? thumbnailUrl;

  /// `status == LIVE`; otherwise the show has ended.
  final bool isLive;

  /// Video is arriving right now. A LIVE show can briefly be `false`.
  final bool isStreaming;
  final int viewerCount;
  final int peakViewerCount;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? playbackUrl;
  final LiveSeller seller;

  bool get hasEnded => !isLive;

  /// Card image and player poster: cover, then seller logo.
  String? get posterUrl {
    final thumb = thumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) return thumb;
    final logo = seller.logo?.trim();
    if (logo != null && logo.isNotEmpty) return logo;
    return null;
  }
}

enum LotStatus {
  queued,
  running,
  sold,
  unsold,
  cancelled;

  static LotStatus fromApi(Object? raw) =>
      switch (raw?.toString().trim().toUpperCase()) {
        'RUNNING' => LotStatus.running,
        'SOLD' => LotStatus.sold,
        'UNSOLD' => LotStatus.unsold,
        'CANCELLED' => LotStatus.cancelled,
        _ => LotStatus.queued,
      };

  bool get isFinal =>
      this == LotStatus.sold ||
      this == LotStatus.unsold ||
      this == LotStatus.cancelled;
}

class LiveBid {
  const LiveBid({required this.amount, required this.bidderName, this.at});

  final double amount;
  final String bidderName;
  final DateTime? at;
}

class LiveAuctionLot {
  const LiveAuctionLot({
    required this.id,
    required this.status,
    required this.title,
    required this.productType,
    required this.productId,
    required this.startingBid,
    required this.bidStep,
    required this.minNextBid,
    this.position = 0,
    this.image,
    this.stockNumber,
    this.durationSeconds = 0,
    this.currentBid,
    this.bidCount = 0,
    this.leaderName,
    this.startedAt,
    this.endsAt,
    this.endedAt,
    this.recentBids = const [],
  });

  final String id;
  final LotStatus status;
  final int position;
  final String productType;
  final String productId;
  final String title;
  final String? image;
  final String? stockNumber;
  final double startingBid;
  final double bidStep;
  final int durationSeconds;
  final double? currentBid;
  final int bidCount;
  final String? leaderName;
  final double minNextBid;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final DateTime? endedAt;
  final List<LiveBid> recentBids;

  bool get hasBids => bidCount > 0 && currentBid != null;
}

/// `GET /live/shows/:id/auction`.
class ShowAuction {
  const ShowAuction({
    required this.serverTime,
    this.current,
    this.upNext = const [],
    this.results = const [],
  });

  final DateTime serverTime;
  final LiveAuctionLot? current;
  final List<LiveAuctionLot> upNext;
  final List<LiveAuctionLot> results;
}

class LiveWallet {
  const LiveWallet({
    required this.balance,
    required this.heldAmount,
    required this.availableBalance,
  });

  final double balance;
  final double heldAmount;

  /// "Free to bid": balance minus holds for other lots the buyer leads.
  final double availableBalance;
}

class LiveLeading {
  const LiveLeading({required this.lotId, required this.amount});

  final String lotId;
  final double amount;
}

class LiveWin {
  const LiveWin({
    required this.lotId,
    required this.orderId,
    required this.amount,
    required this.title,
  });

  final String lotId;
  final String orderId;
  final double amount;
  final String title;
}

/// `GET /live/shows/:id/auction/me`.
class MyShowState {
  const MyShowState({
    required this.wallet,
    this.leading = const [],
    this.wins = const [],
    this.hasDeliveryAddress = false,
    this.isSeller = false,
    this.chatMuted = false,
  });

  final LiveWallet wallet;
  final List<LiveLeading> leading;
  final List<LiveWin> wins;
  final bool hasDeliveryAddress;
  final bool isSeller;
  final bool chatMuted;

  double? leadingAmount(String lotId) {
    for (final l in leading) {
      if (l.lotId == lotId) return l.amount;
    }
    return null;
  }

  LiveWin? winFor(String lotId) {
    for (final w in wins) {
      if (w.lotId == lotId) return w;
    }
    return null;
  }

  MyShowState copyWith({LiveWallet? wallet, List<LiveLeading>? leading}) {
    return MyShowState(
      wallet: wallet ?? this.wallet,
      leading: leading ?? this.leading,
      wins: wins,
      hasDeliveryAddress: hasDeliveryAddress,
      isSeller: isSeller,
      chatMuted: chatMuted,
    );
  }
}

class LiveChatMessage {
  const LiveChatMessage({
    required this.id,
    required this.body,
    required this.authorName,
    this.isSeller = false,
    this.createdAt,
  });

  final String id;
  final String body;
  final String authorName;
  final bool isSeller;
  final DateTime? createdAt;
}

/// `POST /live/shows/:id/viewer-token`.
class LiveViewerToken {
  const LiveViewerToken({required this.token, this.serverUrl, this.expiresAt});

  final String token;
  final String? serverUrl;
  final DateTime? expiresAt;
}

/// `POST /live/auction/lots/:lotId/bids` success.
class LiveBidResult {
  const LiveBidResult({required this.lot, required this.wallet});

  final LiveAuctionLot lot;
  final LiveWallet? wallet;
}

/// Bid failure codes; branch on these, never on the message.
enum LiveBidErrorCode {
  bidTooLow,
  insufficientWallet,
  addressRequired,
  lotClosed,
  alreadyLeading,
  forbidden,
  invalid,
  signInRequired,
  network;

  static LiveBidErrorCode? fromApi(Object? raw) =>
      switch (raw?.toString().trim().toUpperCase()) {
        'BID_TOO_LOW' => LiveBidErrorCode.bidTooLow,
        'INSUFFICIENT_WALLET' => LiveBidErrorCode.insufficientWallet,
        'ADDRESS_REQUIRED' => LiveBidErrorCode.addressRequired,
        'LOT_CLOSED' => LiveBidErrorCode.lotClosed,
        'ALREADY_LEADING' => LiveBidErrorCode.alreadyLeading,
        _ => null,
      };
}

/// A chat or like request the server refused, with its HTTP status.
class LiveActionError {
  const LiveActionError({required this.message, this.status});

  final String message;
  final int? status;

  bool get unauthorized => status == 401;
  bool get forbidden => status == 403;
}

class LiveBidError {
  const LiveBidError({
    required this.code,
    required this.message,
    this.minBid,
    this.available,
    this.required,
    this.shortfall,
  });

  final LiveBidErrorCode code;
  final String message;
  final double? minBid;
  final double? available;
  final double? required;
  final double? shortfall;
}
