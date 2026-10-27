import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/auction/data/mappers/auction_mapper.dart';

void main() {
  test('maps live auction page envelope', () {
    // Relative to now, so the auction stays live whenever the test runs.
    final now = DateTime.now().toUtc();
    final page = AuctionMapper.pageFromEnvelope(
      {
        'success': true,
        'message': 'Live and upcoming auctions fetched successfully.',
        'data': {
          'data': [
            {
              'id': 'f16cbdf4-9630-4b9b-92d2-0e608fa35f80',
              'productType': 'diamond',
              'productId': '003d45fe-f856-4918-bb3f-23d14ea4495e',
              'sellerId': '528f3eb5-1367-48ca-89d5-4fd98046e499',
              'startTime': now
                  .subtract(const Duration(days: 1))
                  .toIso8601String(),
              'endTime': now.add(const Duration(days: 5)).toIso8601String(),
              'minimumBid': 237.07,
              'reservePrice': null,
              'winnerId': null,
              'isActive': true,
              'isSold': false,
              'awaitingSellerDecision': false,
              'closureStatus': 'ACTIVE',
              'bids': [],
              'highestBid': null,
              'isReserveMet': true,
              'seller': {'companyName': 'SRK'},
              'product': {
                'stockNumber': '1101868',
                'shape': 'round',
                'caratWeight': '0.38',
                'totalPrice': '237.07',
                'image1':
                    'https://s3media.s3.ap-southeast-1.amazonaws.com/vision360/mb/img_1101868.jpg',
              },
            },
          ],
          'meta': {
            'total': 4,
            'lastPage': 2,
            'currentPage': 1,
            'perPage': 2,
            'prev': null,
            'next': 2,
          },
        },
      },
      page: 1,
      limit: 2,
    );

    expect(page.total, 4);
    expect(page.nextPage, 2);
    expect(page.hasMore, isTrue);
    final auction = page.items.single;
    expect(auction.title, '0.38 ct Round');
    expect(auction.minimumBid, 237.07);
    expect(auction.currentBid, 237.07);
    expect(auction.sellerName, 'SRK');
    expect(auction.imageUrl, contains('img_1101868'));
    expect(auction.isLive, isTrue);
  });

  test('maps settings and bid mutation', () {
    final settings = AuctionMapper.settingsFromEnvelope({
      'success': true,
      'data': {
        'maxDays': 11,
        'allowedPresets': [7, 10, 15, 30],
        'allowCustomDays': true,
        'winnerRejectWarningLimit': 2,
        'winnerRejectBlacklistDays': 30,
      },
    });
    expect(settings.presetsWithinMax(), [7, 10]);

    final mutation = AuctionMapper.mutationFromEnvelope({
      'success': true,
      'message': 'Bid placed successfully.',
      'data': {
        'id': 'bid-1',
        'auctionId': 'auction-1',
        'buyerId': 'buyer-1',
        'amount': 250,
        'createdAt': '2026-09-29T06:00:00.000Z',
      },
    });
    expect(mutation.bidId, 'bid-1');
    expect(mutation.auction, isNull);
  });

  test('uses the numeric highest bid and the buyer username', () {
    final auction = AuctionMapper.listingFromJson({
      'id': 'auction-1',
      'productType': 'diamond',
      'productId': 'product-1',
      'sellerId': 'seller-1',
      'minimumBid': 80,
      'isActive': true,
      'isSold': false,
      'highestBid': 120,
      'bids': [
        {
          'id': 'bid-1',
          'auctionId': 'auction-1',
          'buyerId': 'buyer-1',
          'amount': 120,
          'createdAt': '2026-09-29T11:48:06.209Z',
          'buyer': {'userName': 'abdshc', 'name': 'Chelsa'},
        },
      ],
    });
    expect(auction.highestBidAmount, 120);
    expect(auction.bids.single.buyerName, 'abdshc');
  });

  test('maps activity summary and the signed-in user outcome', () {
    final page = AuctionMapper.pageFromEnvelope(
      {
        'success': true,
        'data': {
          'summary': {
            'participated': 4,
            'participating': 2,
            'won': 1,
            'lost': 1,
          },
          'data': [
            {
              'id': 'auction-1',
              'productType': 'diamond',
              'productId': 'product-1',
              'sellerId': 'seller-1',
              'minimumBid': 80,
              'isActive': true,
              'isSold': false,
              'userOutcome': 'participating',
              'myHighestBid': 120.4,
              'myBidCount': 2,
              'bids': [],
            },
          ],
          'meta': {'total': 4, 'lastPage': 1, 'currentPage': 1, 'perPage': 20},
        },
      },
      page: 1,
      limit: 20,
    );

    expect(page.summary?.participated, 4);
    expect(page.summary?.participating, 2);
    expect(page.summary?.won, 1);
    expect(page.summary?.lost, 1);
    expect(page.items.single.userOutcome, 'participating');
    expect(page.items.single.myHighestBid, 120.4);
    expect(page.items.single.myBidCount, 2);
  });
}
