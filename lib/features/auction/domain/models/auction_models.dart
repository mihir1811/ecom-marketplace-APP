/// One bid on an auction.
class AuctionBid {
  const AuctionBid({
    required this.id,
    required this.auctionId,
    required this.buyerId,
    required this.amount,
    required this.createdAt,
    this.buyerName,
  });

  final String id;
  final String auctionId;
  final String buyerId;
  final double amount;
  final DateTime? createdAt;
  final String? buyerName;
}

/// Auction row used by lists and the detail screen.
class AuctionListing {
  const AuctionListing({
    required this.id,
    required this.productType,
    required this.productId,
    required this.sellerId,
    required this.title,
    required this.minimumBid,
    required this.isActive,
    required this.isSold,
    required this.awaitingSellerDecision,
    required this.closureStatus,
    required this.isReserveMet,
    required this.bids,
    required this.declinedWinnerIds,
    required this.product,
    required this.seller,
    this.sellerName,
    this.imageUrl,
    this.startTime,
    this.endTime,
    this.reservePrice,
    this.winnerId,
    this.winningAmount,
    this.winnerStatus,
    this.highestBidAmount,
    this.catalogPrice,
    this.stockNumber,
  });

  final String id;
  final String productType;
  final String productId;
  final String sellerId;
  final String title;
  final String? imageUrl;
  final String? sellerName;
  final String? stockNumber;
  final DateTime? startTime;
  final DateTime? endTime;
  final double minimumBid;
  final double? reservePrice;
  final double? catalogPrice;
  final double? highestBidAmount;
  final double? winningAmount;
  final String? winnerId;
  final String? winnerStatus;
  final bool isActive;
  final bool isSold;
  final bool awaitingSellerDecision;
  final String closureStatus;
  final bool isReserveMet;
  final List<String> declinedWinnerIds;
  final List<AuctionBid> bids;

  /// Catalog product payload used to build the product-detail layout.
  final Map<String, dynamic> product;

  /// Seller payload used to build the product-detail seller panel.
  final Map<String, dynamic> seller;

  double get currentBid => highestBidAmount ?? minimumBid;

  /// Inserts a socket bid into history and raises the current price in place.
  AuctionListing applyLiveBid(double amount, {AuctionBid? bid}) {
    final incoming = bid ??
        AuctionBid(
          id: 'live:$id:${amount.toStringAsFixed(2)}',
          auctionId: id,
          buyerId: '',
          amount: amount,
          createdAt: DateTime.now().toUtc(),
        );
    final already = bids.any(
      (row) =>
          row.id == incoming.id || (row.amount - incoming.amount).abs() < 0.001,
    );
    final nextBids = already ? bids : [...bids, incoming];
    final previous = highestBidAmount;
    final highest = previous == null || amount > previous ? amount : previous;
    if (already && highest == previous) return this;
    return _copy(
      bids: nextBids,
      highestBidAmount: highest,
      isReserveMet: reservePrice == null || highest >= reservePrice!,
    );
  }

  /// Keeps a socket bid that the following refresh has not returned yet.
  AuctionListing keepingPendingBids(AuctionListing fresh) {
    final pending = bids.where((bid) {
      if (!bid.id.startsWith('live:')) return false;
      return !fresh.bids.any((row) => (row.amount - bid.amount).abs() < 0.001);
    });
    if (pending.isEmpty) return fresh;
    final merged = [...fresh.bids, ...pending];
    var highest = fresh.highestBidAmount;
    for (final bid in pending) {
      if (highest == null || bid.amount > highest) highest = bid.amount;
    }
    final reserve = fresh.reservePrice;
    return fresh._copy(
      bids: merged,
      highestBidAmount: highest,
      isReserveMet: reserve == null || (highest != null && highest >= reserve),
    );
  }

  AuctionListing _copy({
    List<AuctionBid>? bids,
    double? highestBidAmount,
    bool? isReserveMet,
  }) {
    return AuctionListing(
      id: id,
      productType: productType,
      productId: productId,
      sellerId: sellerId,
      title: title,
      sellerName: sellerName,
      imageUrl: imageUrl,
      startTime: startTime,
      endTime: endTime,
      reservePrice: reservePrice,
      winnerId: winnerId,
      winningAmount: winningAmount,
      winnerStatus: winnerStatus,
      catalogPrice: catalogPrice,
      stockNumber: stockNumber,
      minimumBid: minimumBid,
      isActive: isActive,
      isSold: isSold,
      awaitingSellerDecision: awaitingSellerDecision,
      closureStatus: closureStatus,
      isReserveMet: isReserveMet ?? this.isReserveMet,
      bids: bids ?? this.bids,
      declinedWinnerIds: declinedWinnerIds,
      product: product,
      seller: seller,
      highestBidAmount: highestBidAmount ?? this.highestBidAmount,
    );
  }

  bool get isUpcoming {
    final start = startTime;
    return start != null && start.isAfter(DateTime.now());
  }

  bool get isEnded {
    final end = endTime;
    return isSold || (end != null && !end.isAfter(DateTime.now()));
  }

  bool get isLive => isActive && !isSold && !isUpcoming && !isEnded;

  String get phaseLabel {
    if (isSold) return 'Sold';
    if (awaitingSellerDecision) return 'Awaiting decision';
    if (isUpcoming) return 'Upcoming';
    if (isEnded) return 'Ended';
    if (isLive) return 'Live';
    if (closureStatus.isEmpty) return 'Auction';
    return closureStatus;
  }
}

/// Paginated auction list.
class AuctionPage {
  const AuctionPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    this.nextPage,
  });

  final List<AuctionListing> items;
  final int total;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int? nextPage;

  bool get hasMore => nextPage != null;
}

/// `GET /auction/settings`.
class AuctionSettings {
  const AuctionSettings({
    required this.maxDays,
    required this.allowedPresets,
    required this.allowCustomDays,
    required this.winnerRejectWarningLimit,
    required this.winnerRejectBlacklistDays,
    this.description,
    this.updatedAt,
  });

  final int maxDays;
  final List<int> allowedPresets;
  final bool allowCustomDays;
  final int winnerRejectWarningLimit;
  final int winnerRejectBlacklistDays;
  final String? description;
  final DateTime? updatedAt;

  List<int> presetsWithinMax() {
    return allowedPresets.where((d) => d > 0 && d <= maxDays).toList();
  }
}

/// Winner decline warnings for the signed-in user.
class AuctionPenalty {
  const AuctionPenalty({
    required this.warningCount,
    required this.isBlacklisted,
    this.warningLimit,
    this.blacklistDays,
  });

  final int warningCount;
  final bool isBlacklisted;
  final int? warningLimit;
  final int? blacklistDays;
}

/// Message returned by auction mutations, plus the updated auction when present.
class AuctionMutation {
  const AuctionMutation({required this.message, this.auction, this.bidId});

  final String message;
  final AuctionListing? auction;
  final String? bidId;
}

/// Bulk-create summary.
class AuctionBulkResult {
  const AuctionBulkResult({
    required this.message,
    required this.created,
    required this.failed,
    required this.results,
  });

  final String message;
  final int created;
  final int failed;
  final List<AuctionBulkItem> results;
}

class AuctionBulkItem {
  const AuctionBulkItem({
    required this.productId,
    required this.productType,
    required this.success,
    this.auctionId,
    this.error,
  });

  final String productId;
  final String productType;
  final bool success;
  final String? auctionId;
  final String? error;
}

/// One line in a bulk-create request.
class AuctionBulkDraft {
  const AuctionBulkDraft({
    required this.productId,
    required this.productType,
    required this.minimumBid,
    this.reservePrice,
  });

  final String productId;
  final String productType;
  final double minimumBid;
  final double? reservePrice;
}
