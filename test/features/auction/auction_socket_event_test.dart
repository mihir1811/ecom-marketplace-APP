import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/features/auction/data/auction_socket_client.dart';
import 'package:gemworld/features/auction/data/mappers/auction_mapper.dart';
import 'package:gemworld/features/auction/domain/models/auction_models.dart';

void main() {
  test('parses AUCTION_BID payload with a uuid auction id', () {
    final event = auctionSocketEventFromRaw({
      'auctionId': 'f16cbdf4-9630-4b9b-92d2-0e608fa35f80',
      'amount': 400,
    }, kind: AuctionSocketKind.bid);

    expect(event?.auctionId, 'f16cbdf4-9630-4b9b-92d2-0e608fa35f80');
    expect(event?.amount, 400);
    expect(event?.kind, AuctionSocketKind.bid);
  });

  test('parses numeric auctionId from a JSON string', () {
    final event = auctionSocketEventFromRaw(
      '{"auctionId":12,"amount":80.5}',
      kind: AuctionSocketKind.updated,
    );

    expect(event?.auctionId, '12');
    expect(event?.amount, 80.5);
    expect(event?.kind, AuctionSocketKind.updated);
  });

  test('parses a string bid amount', () {
    final event = auctionSocketEventFromRaw({
      'auctionId': 'abc',
      'amount': '910.50',
    }, kind: AuctionSocketKind.bid);
    expect(event?.amount, 910.5);
  });

  test('live bid updates the price and appends history', () {
    final listing = AuctionMapper.listingFromJson(const {
      'id': 'f16cbdf4-9630-4b9b-92d2-0e608fa35f80',
      'productType': 'diamond',
      'productId': 'p1',
      'sellerId': 's1',
      'minimumBid': 100,
      'isActive': true,
      'isSold': false,
      'awaitingSellerDecision': false,
      'closureStatus': 'ACTIVE',
      'bids': [],
      'highestBid': 80,
      'isReserveMet': false,
      'reservePrice': 90,
    });

    final raised = listing.applyLiveBid(120);
    expect(raised.highestBidAmount, 120);
    expect(raised.currentBid, 120);
    expect(raised.isReserveMet, isTrue);
    expect(raised.bids, hasLength(1));
    expect(raised.bids.single.amount, 120);
    expect(identical(raised.applyLiveBid(120), raised), isTrue);
  });

  AuctionListing listing({List<Map<String, dynamic>> bids = const []}) {
    return AuctionMapper.listingFromJson({
      'id': 'f16cbdf4-9630-4b9b-92d2-0e608fa35f80',
      'productType': 'diamond',
      'productId': 'p1',
      'sellerId': 's1',
      'minimumBid': 100,
      'isActive': true,
      'isSold': false,
      'awaitingSellerDecision': false,
      'closureStatus': 'ACTIVE',
      'bids': bids,
      'highestBid': bids.isEmpty ? null : bids.last['amount'],
      'isReserveMet': false,
    });
  }

  test('refresh keeps a live bid the server has not returned yet', () {
    final live = listing().applyLiveBid(150);
    final merged = live.keepingPendingBids(listing());
    expect(merged.highestBidAmount, 150);
    expect(merged.bids.map((b) => b.amount), [150]);
  });

  test('refresh replaces the live placeholder with the server bid', () {
    final live = listing().applyLiveBid(150);
    final fresh = listing(
      bids: [
        {'id': 'b1', 'auctionId': 'a', 'buyerId': 'u1', 'amount': 150},
      ],
    );
    final merged = live.keepingPendingBids(fresh);
    expect(merged.bids, hasLength(1));
    expect(merged.bids.single.id, 'b1');
  });

  test('refresh drops a live bid that was cancelled', () {
    final live = listing(
      bids: [
        {'id': 'b1', 'auctionId': 'a', 'buyerId': 'u1', 'amount': 150},
      ],
    ).applyLiveBid(200);
    final fresh = listing(
      bids: [
        {'id': 'b1', 'auctionId': 'a', 'buyerId': 'u1', 'amount': 150},
        {'id': 'b2', 'auctionId': 'a', 'buyerId': 'u2', 'amount': 220},
      ],
    );
    final merged = live.keepingPendingBids(fresh);
    expect(merged.highestBidAmount, 220);
    expect(merged.bids.map((b) => b.id), ['b1', 'b2']);
  });
}
