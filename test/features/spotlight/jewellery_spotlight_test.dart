import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/router/route_names.dart';
import 'package:gemworld/features/jewelry/domain/models/jewelry_filter_state.dart';
import 'package:gemworld/features/notifications/domain/models/app_notification.dart';
import 'package:gemworld/features/notifications/domain/notification_open_target.dart';
import 'package:gemworld/features/spotlight/application/sponsored_jewellery_provider.dart';
import 'package:gemworld/features/spotlight/data/spotlight_repository.dart';
import 'package:gemworld/features/spotlight/domain/spotlight_models.dart';

AppNotification _push(String link, Map<String, String> data) => AppNotification(
  id: 'n1',
  type: 'AD_APPROVED',
  title: 'Your ad is approved',
  body: '',
  link: link,
  data: data,
  isRead: false,
  createdAt: DateTime(2026, 11, 4),
);

void main() {
  test('jewellery placements need no category and size sponsored rows', () {
    for (final p in [
      SpotlightPlacement.jewelleryHomeBanner,
      SpotlightPlacement.jewelleryFeaturedShop,
      SpotlightPlacement.jewelleryListingSponsored,
      SpotlightPlacement.jewelleryProductSponsored,
    ]) {
      expect(p.needsCategory, isFalse);
      expect(p.isJewellery, isTrue);
      expect(SpotlightPlacement.fromApi(p.api), p);
    }
    expect(
      SpotlightPlacement.jewelleryListingSponsored.isSponsoredProducts,
      isTrue,
    );
    expect(SpotlightPlacement.jewelleryHomeBanner.isSponsoredProducts, isFalse);
  });

  test('parses a jewellery banner with a LISTING link', () {
    final item = SpotlightRepository.parseItem({
      'adId': '9f7afd42',
      'kind': 'BANNER',
      'title': 'Hoops for every day',
      'subtitle': null,
      'imageUrl': 'https://cdn/wide.png',
      'mobileImageUrl': 'https://cdn/phone.png',
      'link': {
        'kind': 'LISTING',
        'listingId': '771bda62',
        'slug': 'classic-tube-hoops',
        'shopSlug': 'pinksjewel',
      },
      'seller': {'id': '584615ca', 'name': 'pinksjewel'},
    });
    expect(item, isA<SpotlightBanner>());
    final banner = item! as SpotlightBanner;
    expect(banner.link.opensListing, isTrue);
    expect(banner.link.slug, 'classic-tube-hoops');
    expect(banner.link.shopSlug, 'pinksjewel');
    expect(banner.subtitle, isNull);
    expect(banner.mobileImageUrl, 'https://cdn/phone.png');
  });

  test('a SHOP link opens the shop, not a piece', () {
    final banner =
        SpotlightRepository.parseItem({
              'adId': 'a1',
              'kind': 'BANNER',
              'title': 't',
              'imageUrl': 'https://cdn/wide.png',
              'link': {'kind': 'SHOP', 'shopSlug': 'pinksjewel'},
            })!
            as SpotlightBanner;
    expect(banner.link.opensListing, isFalse);
    expect(banner.link.isJewellery, isTrue);
    expect(banner.link.kind, SpotlightLinkKind.shop);
  });

  test('parses a featured shop; a null tagline falls back to the headline', () {
    final item = SpotlightRepository.parseItem({
      'adId': 'da46b3ea',
      'kind': 'FEATURED_SHOP',
      'tagline': null,
      'shop': {
        'id': 's1',
        'slug': 'pinksjewel',
        'name': 'pinksjewel',
        'headline': 'Kundan, made to order',
        'isVerified': true,
        'location': 'surat',
        'listingCount': 20,
      },
    });
    expect(item, isA<SpotlightFeaturedShop>());
    final ad = item! as SpotlightFeaturedShop;
    expect(ad.shop.slug, 'pinksjewel');
    expect(ad.shop.isVerified, isTrue);
    expect(ad.shop.location, 'surat');
    expect(ad.shop.listingCount, 20);
    expect(ad.line, 'Kundan, made to order');
  });

  test('parses a sponsored listing as a marketplace piece', () {
    final item = SpotlightRepository.parseItem({
      'adId': '1f648701',
      'kind': 'SPONSORED_LISTING',
      'listing': {
        'id': 'a38e1f8e',
        'slug': 'oval-lab-grown-ring',
        'title': 'Oval lab-grown diamond engagement ring',
        'minPrice': '98610',
        'maxPrice': '98610',
        'totalStock': 2,
      },
      'seller': {'id': '584615ca', 'name': 'pinksjewel'},
    });
    expect(item, isA<SpotlightSponsoredListing>());
    final ad = item! as SpotlightSponsoredListing;
    expect(ad.listingId, 'a38e1f8e');
    expect(ad.piece.id, 'oval-lab-grown-ring');
    expect(ad.piece.isMarketplace, isTrue);
    expect(ad.seller?.name, 'pinksjewel');
  });

  test('items without an adId or of unknown kind are skipped', () {
    expect(SpotlightRepository.parseItem({'kind': 'FEATURED_SHOP'}), isNull);
    expect(
      SpotlightRepository.parseItem({'adId': 'x', 'kind': 'SOMETHING'}),
      isNull,
    );
  });

  test('equal listing filters share one sponsored lookup', () {
    final a = SponsoredJewelleryKey(
      const JewelryFilterState(category: 'rings', searchQuery: 'oval'),
    );
    final b = SponsoredJewelleryKey(
      const JewelryFilterState(category: 'rings', searchQuery: 'oval'),
    );
    final c = SponsoredJewelleryKey(
      const JewelryFilterState(category: 'earrings'),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
  });

  test('jewellery ad pushes open the full studio link in the app browser', () {
    final target = notificationOpenTarget(
      _push('https://jewelry.gemworld.in/seller/advertising/ad-1', {
        'entityType': 'AD',
        'adId': 'ad-1',
      }),
      isSeller: true,
    );
    expect(target, isA<NotificationExternal>());
    final external = target as NotificationExternal;
    expect(external.inApp, isTrue);
    expect(external.url.path, '/seller/advertising/ad-1');
  });

  test('diamond-site ad pushes keep the native ad screen', () {
    final target = notificationOpenTarget(
      _push('/seller/spotlight/ad-2', {'entityType': 'AD', 'adId': 'ad-2'}),
      isSeller: true,
    );
    expect(target, isA<NotificationInApp>());
    expect(
      (target as NotificationInApp).route,
      AppRouteNames.sellerSpotlightDetailPath('ad-2'),
    );
  });
}
