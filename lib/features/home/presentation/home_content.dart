import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/route_names.dart';
import 'home_network_images.dart';

/// One catalogue world shown in the collections bento.
class HomeCollection {
  const HomeCollection({
    required this.titleKey,
    required this.route,
    required this.imageUrl,
  });

  final String titleKey;
  final String route;
  final String imageUrl;
}

/// Static, curated entry points for the home screen (no API).
abstract final class HomeContent {
  /// Order matters: it maps onto the bento layout slots.
  static const collections = <HomeCollection>[
    HomeCollection(
      titleKey: RemainingL10n.naturalDiamonds,
      route: AppRouteNames.diamonds,
      imageUrl: HomeNetworkImages.naturalDiamonds,
    ),
    HomeCollection(
      titleKey: RemainingL10n.labGrown,
      route: AppRouteNames.labGrownDiamonds,
      imageUrl: HomeNetworkImages.labGrown,
    ),
    HomeCollection(
      titleKey: RemainingL10n.gemstones,
      route: AppRouteNames.gemstones,
      imageUrl: HomeNetworkImages.gemstones,
    ),
    HomeCollection(
      titleKey: RemainingL10n.jewelry,
      route: AppRouteNames.jewelry,
      imageUrl: HomeNetworkImages.jewelry,
    ),
    HomeCollection(
      titleKey: RemainingL10n.watches,
      route: AppRouteNames.watches,
      imageUrl: HomeNetworkImages.watches,
    ),
    HomeCollection(
      titleKey: RemainingL10n.bullion,
      route: AppRouteNames.bullions,
      imageUrl: HomeNetworkImages.bullion,
    ),
  ];

  /// Shapes offered in the diamond atelier carousel.
  static const shapes = <({String name, String image})>[
    (name: 'Round', image: 'public/images/round.png'),
    (name: 'Oval', image: 'public/images/Oval.png'),
    (name: 'Cushion', image: 'public/images/Cushion.png'),
    (name: 'Emerald', image: 'public/images/Emerald.png'),
    (name: 'Pear', image: 'public/images/Pear.png'),
    (name: 'Princess', image: 'public/images/princess.png'),
    (name: 'Radiant', image: 'public/images/Radiant.png'),
    (name: 'Marquise', image: 'public/images/Marquise.png'),
    (name: 'Heart', image: 'public/images/Heart.png'),
    (name: 'Asscher', image: 'public/images/Asscher.png'),
  ];
}
