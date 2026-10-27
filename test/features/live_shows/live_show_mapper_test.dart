import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/live_shows/data/live_show_socket.dart';
import 'package:gemstone/features/live_shows/data/mappers/live_show_mapper.dart';
import 'package:gemstone/features/live_shows/domain/live_format.dart';
import 'package:gemstone/features/live_shows/domain/models/live_show_models.dart';

const _showId = '5f35e130-7e0c-4809-a300-9640a586665d';

Map<String, dynamic> _lot({
  String status = 'RUNNING',
  num? currentBid = 152000,
  int bidCount = 3,
}) => {
  'id': 'lot-1',
  'status': status,
  'position': 1,
  'productType': 'diamond',
  'productId': 'p-1',
  'title': '1.50ct Oval G VS1',
  'image': null,
  'stockNumber': 'OV-150',
  'startingBid': 140000,
  'bidStep': 2000,
  'durationSeconds': 600,
  'currentBid': currentBid,
  'bidCount': bidCount,
  'leaderName': 'Rahul M.',
  'minNextBid': 154000,
  'startedAt': '2026-10-22T11:21:00.000Z',
  'endsAt': '2026-10-22T11:31:00.000Z',
  'endedAt': null,
  'recentBids': [
    {
      'amount': 152000,
      'bidderName': 'Rahul M.',
      'at': '2026-10-22T11:24:10.000Z',
    },
  ],
};

void main() {
  group('LiveShowMapper', () {
    test('reads a show from the envelope', () {
      final show = LiveShowMapper.showFromEnvelope({
        'success': true,
        'message': 'ok',
        'data': {
          'id': _showId,
          'provider': 'LIVEKIT',
          'title': 'Friday ovals',
          'thumbnailUrl': null,
          'status': 'LIVE',
          'isStreaming': true,
          'viewerCount': 128,
          'peakViewerCount': 140,
          'startedAt': '2026-10-22T11:20:00.000Z',
          'playbackUrl': 'wss://x.livekit.cloud',
          'seller': {
            'id': 's1',
            'companyName': 'Shree Gems',
            'companyLogo': 'https://cdn/logo.png',
          },
        },
      })!;
      expect(show.provider, LiveProvider.livekit);
      expect(show.isLive, isTrue);
      expect(show.viewerCount, 128);
      // No thumbnail: fall back to the seller's logo.
      expect(show.posterUrl, 'https://cdn/logo.png');
    });

    test('ENDED shows are not live', () {
      final show = LiveShowMapper.showFromJson({
        'id': _showId,
        'provider': 'CLOUDFLARE',
        'status': 'ENDED',
        'seller': {'id': 's1', 'companyName': 'Shree Gems'},
      });
      expect(show.hasEnded, isTrue);
      expect(show.provider, LiveProvider.cloudflare);
    });

    test('reads the auction and lots', () {
      final auction = LiveShowMapper.auctionFromEnvelope({
        'data': {
          'showId': _showId,
          'serverTime': '2026-10-22T11:24:12.000Z',
          'current': _lot(),
          'upNext': [
            {
              ..._lot(status: 'QUEUED', currentBid: null, bidCount: 0),
              'id': 'lot-2',
            },
          ],
          'results': <Object>[],
        },
      });
      final lot = auction.current!;
      expect(lot.status, LotStatus.running);
      expect(lot.minNextBid, 154000);
      expect(lot.recentBids.single.bidderName, 'Rahul M.');
      expect(auction.upNext.single.status, LotStatus.queued);
      expect(auction.serverTime, DateTime.utc(2026, 10, 22, 11, 24, 12));
    });

    test('reads my state', () {
      final me = LiveShowMapper.meFromEnvelope({
        'data': {
          'wallet': {
            'balance': 500000,
            'heldAmount': 152000,
            'availableBalance': 348000,
          },
          'leading': [
            {'lotId': 'lot-1', 'amount': 152000},
          ],
          'wins': [
            {
              'lotId': 'lot-0',
              'orderId': 'o-1',
              'amount': 53000,
              'title': '1.1ct Round',
            },
          ],
          'hasDeliveryAddress': true,
          'isSeller': false,
          'chatMuted': false,
        },
      });
      expect(me.wallet.availableBalance, 348000);
      expect(me.leadingAmount('lot-1'), 152000);
      expect(me.winFor('lot-0')!.orderId, 'o-1');
    });

    test('bid errors branch on code, not message', () {
      final e = LiveShowMapper.bidErrorFromBody({
        'statusCode': 400,
        'message': 'Not enough in wallet',
        'error': 'Bad Request',
        'code': 'INSUFFICIENT_WALLET',
        'available': 60000,
        'required': 61000,
        'shortfall': 1000,
      }, 400);
      expect(e.code, LiveBidErrorCode.insufficientWallet);
      expect(e.shortfall, 1000);

      final validation = LiveShowMapper.bidErrorFromBody({
        'statusCode': 400,
        'message': ['amount must not be less than 1'],
      }, 400);
      expect(validation.code, LiveBidErrorCode.invalid);
      expect(validation.message, 'amount must not be less than 1');

      final banned = LiveShowMapper.bidErrorFromBody({
        'statusCode': 403,
        'message': 'Auction ban until 2026-11-01',
      }, 403);
      expect(banned.code, LiveBidErrorCode.forbidden);
    });
  });

  group('liveShowEventFromRaw', () {
    test('parses a lot push for the open show', () {
      final event = liveShowEventFromRaw('LIVE_AUCTION_LOT', {
        'showId': _showId,
        'lot': _lot(),
      }, showId: _showId);
      expect(event, isA<LiveLotEvent>());
      expect((event! as LiveLotEvent).lot.currentBid, 152000);
    });

    test('accepts a JSON string payload', () {
      final event = liveShowEventFromRaw(
        'LIVE_SHOW_LIKES',
        '{"showId":"$_showId","delta":30}',
        showId: _showId,
      );
      expect((event! as LiveLikesEvent).delta, 30);
    });

    test('ignores another show', () {
      final event = liveShowEventFromRaw('LIVE_CHAT_DELETED', {
        'showId': 'other',
        'messageId': 'm1',
      }, showId: _showId);
      expect(event, isNull);
    });
  });

  group('liveInr', () {
    test('uses Indian grouping', () {
      expect(liveInr(152000), '₹1,52,000');
      expect(liveInr(999), '₹999');
      expect(liveInr(100000000), '₹10,00,00,000');
      expect(liveInr(53000.5), '₹53,000.50');
    });

    test('formats a countdown', () {
      expect(liveClock(const Duration(minutes: 9, seconds: 41)), '09:41');
      expect(liveClock(const Duration(seconds: -3)), '00:00');
    });
  });
}
