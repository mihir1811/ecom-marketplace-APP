import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../home/presentation/widgets/home_search_overlay.dart';
import '../../../notifications/application/notifications_provider.dart';

/// Trailing top-bar actions shared by the luxe catalog flows (diamonds,
/// gemstones): catalog search and notifications (when signed in). The cart
/// lives in the app's bottom navigation bar.
class CatalogFlowActions extends ConsumerWidget {
  const CatalogFlowActions({
    super.key,
    this.showSearch = true,
    this.glass = false,
  });

  final bool showSearch;

  /// Frosted treatment for use over imagery or a dark stage.
  final bool glass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(
      authProvider.select((s) => (signedIn: s.isAuthenticated)),
    );
    final unread = auth.signedIn
        ? ref.watch(notificationUnreadCountProvider)
        : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSearch)
          LuxeIconButton(
            icon: Icons.search_rounded,
            tooltip: context.tr(HomeL10n.searchPrefix),
            size: 40,
            glass: glass,
            onPressed: () => showHomeSearch(context),
          ),
        if (auth.signedIn) ...[
          const SizedBox(width: 6),
          LuxeIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: context.tr(HomeL10n.notifications),
            size: 40,
            glass: glass,
            badge: unread,
            // Catalog pages are the buyer side; stay on it.
            onPressed: () =>
                context.switchToRoute(AppRouteNames.buyerNotifications),
          ),
        ],
      ],
    );
  }
}
