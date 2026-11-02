import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/auction/data/mappers/auction_mapper.dart';
import 'package:gemstone/features/auction/domain/models/auction_models.dart';
import 'package:gemstone/features/auction/presentation/auction_seller_outcome.dart';

/// Seller decides once bidding closes: accept the highest eligible bidder,
/// pick another one, or reject.
void main() {
  AuctionListing auction(Map<String, dynamic> fields) =>
      AuctionMapper.listingFromJson({
        'id': 'au-1',
        'productType': 'diamond',
        'productId': 'p-1',
        'sellerId': 's-1',
        'bids': [
          {
            'id': 'b-1',
            'buyerId': 'u-1',
            'amount': 500,
            'buyer': {'name': 'Asha'},
          },
          {
            'id': 'b-2',
            'buyerId': 'u-2',
            'amount': 450,
            'buyer': {'userName': 'ravi'},
          },
          {'id': 'b-3', 'buyerId': 'u-3', 'amount': 300},
        ],
        ...fields,
      });

  test('eligible bids are highest first', () {
    final a = auction({'awaitingSellerDecision': true});
    expect(a.eligibleBids().map((b) => b.id), ['b-1', 'b-2', 'b-3']);
    expect(a.eligibleBids().first.buyerName, 'Asha');
  });

  test('a declined winner is skipped for the next bidder', () {
    final a = auction({
      'awaitingSellerDecision': true,
      'declinedWinnerIds': ['u-1'],
    });
    expect(a.hasDeclined('u-1'), isTrue);
    expect(a.eligibleBids().map((b) => b.id), ['b-2', 'b-3']);
    final line = auctionSellerOutcome(a)!;
    expect(line.text, contains('next bidder'));
    expect(line.text, contains(r'$450'));
  });

  test('socket placeholder bids cannot be accepted', () {
    final a = auction({'awaitingSellerDecision': true}).applyLiveBid(900);
    expect(a.highestBidAmount, 900);
    expect(a.eligibleBids().first.id, 'b-1');
  });

  test('no eligible bidders left', () {
    final a = auction({
      'awaitingSellerDecision': true,
      'declinedWinnerIds': ['u-1', 'u-2', 'u-3'],
    });
    expect(a.eligibleBids(), isEmpty);
    expect(auctionSellerOutcome(a)!.text, contains('no other bidders'));
  });

  test('below reserve still offers the decision', () {
    final a = auction({
      'awaitingSellerDecision': true,
      'reservePrice': 1000,
      'isReserveMet': false,
    });
    expect(auctionSellerOutcome(a)!.text, contains('below your reserve'));
  });

  test('accepted winner name and payment line', () {
    final a = auction({
      'isSold': true,
      'winnerId': 'u-1',
      'winner': {'id': 'u-1', 'name': 'Asha'},
      'winnerStatus': 'PENDING',
      'paymentDueAt': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 20))
          .toIso8601String(),
    });
    expect(a.winnerName, 'Asha');
    expect(a.winPayment, AuctionWinPayment.due);
    expect(auctionSellerOutcome(a)!.text, startsWith('Awaiting payment'));

    final gemworld = auction({
      'winnerStatus': 'PENDING',
      'paymentWithGemworld': true,
    });
    expect(auctionSellerOutcome(gemworld)!.text, contains('GemWorld'));

    final paid = auction({'winnerStatus': 'PAID'});
    expect(auctionSellerOutcome(paid)!.done, isTrue);
  });

  test('nothing to report while live', () {
    expect(auctionSellerOutcome(auction({'isActive': true})), isNull);
  });
}
