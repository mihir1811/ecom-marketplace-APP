import '../../domain/models/auction_models.dart';

/// Parses auction envelopes into domain models.
abstract final class AuctionMapper {
  static AuctionSettings settingsFromEnvelope(Map<String, dynamic>? body) {
    final data = _map(body?['data']) ?? const {};
    final presets = <int>[];
    final rawPresets = data['allowedPresets'];
    if (rawPresets is List) {
      for (final value in rawPresets) {
        final n = _int(value);
        if (n != null) presets.add(n);
      }
    }
    return AuctionSettings(
      maxDays: _int(data['maxDays']) ?? 0,
      allowedPresets: presets,
      allowCustomDays: data['allowCustomDays'] == true,
      winnerRejectWarningLimit: _int(data['winnerRejectWarningLimit']) ?? 0,
      winnerRejectBlacklistDays: _int(data['winnerRejectBlacklistDays']) ?? 0,
      description: _str(data['description']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  static AuctionPenalty penaltyFromEnvelope(Map<String, dynamic>? body) {
    final data = _map(body?['data']) ?? body ?? const {};
    return AuctionPenalty(
      warningCount:
          _int(data['warningCount']) ??
          _int(data['winnerRejectWarningCount']) ??
          _int(data['rejectCount']) ??
          _int(data['count']) ??
          0,
      isBlacklisted:
          data['isBlacklisted'] == true ||
          data['blacklisted'] == true ||
          data['isBlocked'] == true,
      warningLimit:
          _int(data['warningLimit']) ?? _int(data['winnerRejectWarningLimit']),
      blacklistDays:
          _int(data['blacklistDays']) ??
          _int(data['winnerRejectBlacklistDays']),
    );
  }

  static AuctionPage pageFromEnvelope(
    Map<String, dynamic>? body, {
    required int page,
    required int limit,
  }) {
    final data = body?['data'];
    List<dynamic> rows = const [];
    Map<String, dynamic>? meta;
    AuctionActivitySummary? summary;
    if (data is Map) {
      final nested = data['data'];
      if (nested is List) rows = nested;
      meta = _map(data['meta']);
      summary = _summary(data['summary']);
    } else if (data is List) {
      rows = data;
    }
    final items = <AuctionListing>[];
    for (final row in rows) {
      final map = _map(row);
      if (map == null) continue;
      items.add(listingFromJson(map));
    }
    final current = _int(meta?['currentPage']) ?? page;
    final last = _int(meta?['lastPage']) ?? current;
    final next = _int(meta?['next']);
    return AuctionPage(
      items: items,
      total: _int(meta?['total']) ?? items.length,
      currentPage: current,
      lastPage: last,
      perPage: _int(meta?['perPage']) ?? limit,
      nextPage: next,
      summary: summary,
    );
  }

  static AuctionActivitySummary? _summary(Object? raw) {
    final map = _map(raw);
    if (map == null) return null;
    if (map['participated'] == null &&
        map['participating'] == null &&
        map['won'] == null &&
        map['lost'] == null) {
      return null;
    }
    int count(String key) => _int(map[key]) ?? 0;
    return AuctionActivitySummary(
      participated: count('participated'),
      participating: count('participating'),
      won: count('won'),
      lost: count('lost'),
    );
  }

  static AuctionListing listingFromEnvelope(Map<String, dynamic>? body) {
    final data = _map(body?['data']) ?? body ?? const {};
    return listingFromJson(data);
  }

  static AuctionListing listingFromJson(Map<String, dynamic> json) {
    final product = _map(json['product']) ?? const {};
    final seller = _map(json['seller']) ?? const {};
    final winner = _map(json['winner']) ?? const {};
    final bids = _bids(json['bids']);
    final highest = _highest(json['highestBid'], bids);
    return AuctionListing(
      id: _str(json['id']) ?? '',
      productType: _str(json['productType']) ?? '',
      productId: _str(json['productId']) ?? _str(product['id']) ?? '',
      sellerId: _str(json['sellerId']) ?? _str(seller['id']) ?? '',
      title: _title(product, json),
      imageUrl: _image(product),
      sellerName: _str(seller['companyName']) ?? _str(seller['name']),
      stockNumber: _str(product['stockNumber']),
      startTime: _date(json['startTime']),
      endTime: _date(json['endTime']),
      minimumBid: _num(json['minimumBid']) ?? 0,
      reservePrice: _num(json['reservePrice']),
      catalogPrice: _num(product['totalPrice']) ?? _num(product['price']),
      highestBidAmount: highest,
      winningAmount: _num(json['winningAmount']),
      winnerId: _str(json['winnerId']) ?? _str(winner['id']),
      winnerName: _str(winner['name']) ?? _str(winner['userName']),
      winnerStatus: _str(json['winnerStatus']),
      paymentDueAt: _date(json['paymentDueAt']),
      paymentWithGemworld: json['paymentWithGemworld'] == true,
      isActive: json['isActive'] == true,
      isSold: json['isSold'] == true,
      awaitingSellerDecision: json['awaitingSellerDecision'] == true,
      closureStatus: _str(json['closureStatus']) ?? '',
      isReserveMet: json['isReserveMet'] != false,
      declinedWinnerIds: _strings(json['declinedWinnerIds']),
      bids: bids,
      userOutcome: _str(json['userOutcome']),
      myHighestBid: _num(json['myHighestBid']),
      myBidCount: _int(json['myBidCount']) ?? 0,
      product: product,
      seller: seller,
    );
  }

  static List<AuctionBid> bidsFromEnvelope(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is List) return _bids(data);
    if (data is Map && data['data'] is List) return _bids(data['data']);
    return const [];
  }

  static AuctionMutation mutationFromEnvelope(Map<String, dynamic>? body) {
    final data = _map(body?['data']);
    AuctionListing? auction;
    String? bidId;
    if (data != null &&
        (_str(data['id']) != null || data['productId'] != null)) {
      if (data['startTime'] != null || data['productType'] != null) {
        auction = listingFromJson(data);
      } else if (data['amount'] != null) {
        bidId = _str(data['id']);
      }
    }
    return AuctionMutation(
      message: _str(body?['message']) ?? 'Done',
      auction: auction,
      bidId: bidId,
    );
  }

  static AuctionBulkResult bulkFromEnvelope(Map<String, dynamic>? body) {
    final data = _map(body?['data']);
    final root = data != null && data['results'] is List ? data : (body ?? {});
    final results = <AuctionBulkItem>[];
    final raw = root['results'];
    if (raw is List) {
      for (final row in raw) {
        final map = _map(row);
        if (map == null) continue;
        results.add(
          AuctionBulkItem(
            productId: _str(map['productId']) ?? '',
            productType: _str(map['productType']) ?? '',
            success: map['success'] == true,
            auctionId: _str(map['auctionId']),
            error: _str(map['error']),
          ),
        );
      }
    }
    return AuctionBulkResult(
      message: _str(body?['message']) ?? _str(root['message']) ?? 'Done',
      created: _int(root['created']) ?? results.where((r) => r.success).length,
      failed: _int(root['failed']) ?? results.where((r) => !r.success).length,
      results: results,
    );
  }

  static List<AuctionBid> _bids(Object? raw) {
    if (raw is! List) return const [];
    final bids = <AuctionBid>[];
    for (final row in raw) {
      final map = _map(row);
      if (map == null) continue;
      final buyer = _map(map['buyer']);
      bids.add(
        AuctionBid(
          id: _str(map['id']) ?? '',
          auctionId: _str(map['auctionId']) ?? '',
          buyerId: _str(map['buyerId']) ?? _str(buyer?['id']) ?? '',
          amount: _num(map['amount']) ?? 0,
          createdAt: _date(map['createdAt']),
          buyerName:
              _str(buyer?['userName']) ??
              _str(buyer?['name']) ??
              _str(map['buyerName']),
        ),
      );
    }
    return bids;
  }

  static double? _highest(Object? raw, List<AuctionBid> bids) {
    double? best;
    void take(double? value) {
      if (value == null) return;
      if (best == null || value > best!) best = value;
    }

    if (raw is num) take(raw.toDouble());
    final map = _map(raw);
    if (map != null) take(_num(map['amount']));
    for (final bid in bids) {
      take(bid.amount);
    }
    return best;
  }

  static String _title(
    Map<String, dynamic> product,
    Map<String, dynamic> json,
  ) {
    final name = _str(product['name']);
    if (name != null) return name;
    final carat = _str(product['caratWeight']);
    final shape = _str(product['shape']);
    if (carat != null && shape != null) {
      return '$carat ct ${shape[0].toUpperCase()}${shape.substring(1)}';
    }
    final stock = _str(product['stockNumber']);
    if (stock != null) return 'Stock $stock';
    return _str(json['productType']) ?? 'Auction';
  }

  static String? _image(Map<String, dynamic> product) {
    for (final key in ['image', 'image1', 'image2', 'imageUrl', 'thumbnail']) {
      final value = _str(product[key]);
      if (value != null && value.startsWith('http')) return value;
    }
    return null;
  }

  static List<String> _strings(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final value in raw)
        if (_str(value) != null) _str(value)!,
    ];
  }

  static Map<String, dynamic>? _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _str(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return null;
    return text;
  }

  static double? _num(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _int(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _date(Object? value) {
    final text = _str(value);
    if (text == null) return null;
    return DateTime.tryParse(text);
  }
}
