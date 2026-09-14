import '../../../../core/router/route_names.dart';
import 'home_network_images.dart';

/// Editorial banner slide for the luxury home carousel.
class HomeBannerItem {
  const HomeBannerItem({
    required this.titleKey,
    required this.subtitleKey,
    required this.ctaKey,
    required this.imageUrl,
    required this.route,
  });

  final String titleKey;
  final String subtitleKey;
  final String ctaKey;
  final String imageUrl;
  final String route;
}

/// Circular category entry on the home strip.
class HomeCategoryItem {
  const HomeCategoryItem({
    required this.titleKey,
    required this.imageUrl,
    required this.route,
  });

  final String titleKey;
  final String imageUrl;
  final String route;
}

/// Curated product card used on rails and editors' grid.
class HomeProductItem {
  const HomeProductItem({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.imageUrl,
    required this.route,
  });

  final String id;
  final String title;
  final String priceLabel;
  final String imageUrl;
  final String route;
}

/// Compact brand / house chip.
class HomeBrandItem {
  const HomeBrandItem({
    required this.name,
    required this.imageUrl,
    required this.route,
  });

  final String name;
  final String imageUrl;
  final String route;
}

/// Static luxury-home feed (no API). Copy keys resolve via RemainingL10n.
abstract final class HomeFeedData {
  static List<HomeBannerItem> banners({
    required String diamondsTitle,
    required String diamondsSubtitle,
    required String jewelryTitle,
    required String jewelrySubtitle,
    required String watchesTitle,
    required String watchesSubtitle,
    required String shopTheEdit,
  }) {
    // Title/subtitle/cta keys are passed as resolved strings from the screen
    // so widgets stay free of BuildContext for data construction.
    return [
      HomeBannerItem(
        titleKey: diamondsTitle,
        subtitleKey: diamondsSubtitle,
        ctaKey: shopTheEdit,
        imageUrl: HomeNetworkImages.forSeed(0),
        route: AppRouteNames.diamonds,
      ),
      HomeBannerItem(
        titleKey: jewelryTitle,
        subtitleKey: jewelrySubtitle,
        ctaKey: shopTheEdit,
        imageUrl: HomeNetworkImages.forSeed(1),
        route: AppRouteNames.jewelry,
      ),
      HomeBannerItem(
        titleKey: watchesTitle,
        subtitleKey: watchesSubtitle,
        ctaKey: shopTheEdit,
        imageUrl: HomeNetworkImages.forSeed(11),
        route: AppRouteNames.watches,
      ),
    ];
  }

  static List<HomeCategoryItem> categories({
    required String naturalDiamonds,
    required String labGrown,
    required String gemstones,
    required String watches,
    required String jewelry,
    required String bullion,
  }) =>
      [
        HomeCategoryItem(
          titleKey: naturalDiamonds,
          imageUrl: HomeNetworkImages.forSeed(4),
          route: AppRouteNames.diamonds,
        ),
        HomeCategoryItem(
          titleKey: labGrown,
          imageUrl: HomeNetworkImages.forSeed(2),
          route: AppRouteNames.labGrownDiamonds,
        ),
        HomeCategoryItem(
          titleKey: gemstones,
          imageUrl: HomeNetworkImages.forSeed(8),
          route: AppRouteNames.gemstones,
        ),
        HomeCategoryItem(
          titleKey: watches,
          imageUrl: HomeNetworkImages.forSeed(12),
          route: AppRouteNames.watches,
        ),
        HomeCategoryItem(
          titleKey: jewelry,
          imageUrl: HomeNetworkImages.forSeed(5),
          route: AppRouteNames.jewelry,
        ),
        HomeCategoryItem(
          titleKey: bullion,
          imageUrl: HomeNetworkImages.forSeed(14),
          route: AppRouteNames.bullions,
        ),
      ];

  static const newArrivals = <HomeProductItem>[
    HomeProductItem(
      id: 'na-1',
      title: 'Oval solitaire 1.52 ct',
      priceLabel: 'From \$8,400',
      imageUrl: 'seed:6',
      route: AppRouteNames.diamonds,
    ),
    HomeProductItem(
      id: 'na-2',
      title: 'Emerald cut tennis bracelet',
      priceLabel: 'From \$12,200',
      imageUrl: 'seed:7',
      route: AppRouteNames.jewelry,
    ),
    HomeProductItem(
      id: 'na-3',
      title: 'Sapphire cabochon ring',
      priceLabel: 'From \$3,150',
      imageUrl: 'seed:9',
      route: AppRouteNames.gemstones,
    ),
    HomeProductItem(
      id: 'na-4',
      title: 'Automatic chronograph',
      priceLabel: 'From \$6,900',
      imageUrl: 'seed:13',
      route: AppRouteNames.watches,
    ),
    HomeProductItem(
      id: 'na-5',
      title: '24K gold bar 10 g',
      priceLabel: 'Spot + premium',
      imageUrl: 'seed:15',
      route: AppRouteNames.bullions,
    ),
  ];

  static const editorsPicks = <HomeProductItem>[
    HomeProductItem(
      id: 'ed-1',
      title: 'Cushion halo engagement set',
      priceLabel: 'From \$11,800',
      imageUrl: 'seed:16',
      route: AppRouteNames.jewelry,
    ),
    HomeProductItem(
      id: 'ed-2',
      title: 'Fancy yellow radiant 2.01 ct',
      priceLabel: 'From \$18,500',
      imageUrl: 'seed:17',
      route: AppRouteNames.diamonds,
    ),
    HomeProductItem(
      id: 'ed-3',
      title: 'Pearl and diamond drop earrings',
      priceLabel: 'From \$2,450',
      imageUrl: 'seed:18',
      route: AppRouteNames.jewelry,
    ),
    HomeProductItem(
      id: 'ed-4',
      title: 'Dress watch, rose gold',
      priceLabel: 'From \$9,200',
      imageUrl: 'seed:19',
      route: AppRouteNames.watches,
    ),
  ];

  static const brands = <HomeBrandItem>[
    HomeBrandItem(
      name: 'Maison Luxe',
      imageUrl: 'seed:20',
      route: AppRouteNames.jewelry,
    ),
    HomeBrandItem(
      name: 'Atelier Stone',
      imageUrl: 'seed:21',
      route: AppRouteNames.diamonds,
    ),
    HomeBrandItem(
      name: 'Chrono House',
      imageUrl: 'seed:12',
      route: AppRouteNames.watches,
    ),
    HomeBrandItem(
      name: 'Aurum Mint',
      imageUrl: 'seed:14',
      route: AppRouteNames.bullions,
    ),
    HomeBrandItem(
      name: 'Gem Atelier',
      imageUrl: 'seed:10',
      route: AppRouteNames.gemstones,
    ),
  ];

  static String resolveImage(String raw) {
    if (raw.startsWith('seed:')) {
      final seed = int.tryParse(raw.substring(5)) ?? 0;
      return HomeNetworkImages.forSeed(seed);
    }
    return raw;
  }
}
