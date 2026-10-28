import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/live_shows/data/mappers/live_show_mapper.dart';
import 'package:gemstone/features/live_shows/domain/models/live_show_models.dart';

void main() {
  test('provider names parse whatever their spelling', () {
    for (final (raw, want) in [
      ('LIVEKIT', LiveProvider.livekit),
      ('LiveKit', LiveProvider.livekit),
      ('live_kit', LiveProvider.livekit),
      ('AWS_IVS_REALTIME', LiveProvider.awsIvsRealtime),
      ('aws-ivs-real-time', LiveProvider.awsIvsRealtime),
      ('IVS_STAGE', LiveProvider.awsIvsRealtime),
      ('AWS_IVS', LiveProvider.awsIvs),
      ('CLOUDFLARE_STREAM', LiveProvider.cloudflare),
      ('', LiveProvider.unknown),
      (null, LiveProvider.unknown),
    ]) {
      expect(LiveProvider.fromApi(raw), want, reason: '$raw');
    }
  });

  test('a missing provider is inferred from the playback URL', () {
    expect(
      LiveProvider.resolve(null, 'wss://shop.livekit.cloud'),
      LiveProvider.livekit,
    );
    expect(
      LiveProvider.resolve(null, 'https://x.live-video.net/a.m3u8'),
      LiveProvider.awsIvs,
    );
    expect(
      LiveProvider.resolve('', 'https://customer.cloudflarestream.com/i'),
      LiveProvider.cloudflare,
    );
    expect(LiveProvider.resolve(null, null), LiveProvider.unknown);
    // A named provider wins over the URL.
    expect(
      LiveProvider.resolve('AWS_IVS_REALTIME', 'wss://x'),
      LiveProvider.awsIvsRealtime,
    );
  });

  test('mapper reads alternate provider keys', () {
    final show = LiveShowMapper.showFromJson({
      'id': 's1',
      'streamProvider': 'LiveKit',
      'status': 'LIVE',
      'seller': {'id': 'x', 'companyName': 'Shree Gems'},
    });
    expect(show.provider, LiveProvider.livekit);
  });
}
