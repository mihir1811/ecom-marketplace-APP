import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/cart/application/cart_provider.dart';
import '../../../features/home/presentation/widgets/home_search_overlay.dart';
import '../../../features/notifications/application/notifications_provider.dart';
import '../../auth/auth_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_navigation.dart';
import '../../router/route_names.dart';
import '../../theme/luxe_tokens.dart';
import '../app_drawer_button.dart';

/// Shared top bar of the bottom-nav tabs (Home, Wishlist, Auctions, Profile).
///
/// The same pinned bar on every tab: menu (login for guests), the
/// search entry, notifications and cart. Screens opened from a tab keep their own
/// bars. During a tab switch [AppBottomNavHost] lays a copy over the page so
/// the bar holds still while the page changes underneath.
class AppTabTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTabTopBar({super.key});

  static const double height = 60;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
    final unread = signedIn ? ref.watch(notificationUnreadCountProvider) : 0;
    final bag = signedIn ? ref.watch(cartItemCountProvider) : 0;

    final Widget leading;
    if (signedIn) {
      leading = IconButton(
        tooltip: context.tr(RemainingL10n.menu),
        onPressed: () => openAppDrawer(context),
        icon: const Icon(Icons.menu_rounded),
      );
    } else {
      leading = TextButton(
        onPressed: () => context.openRoute(AppRouteNames.login),
        style: TextButton.styleFrom(
          foregroundColor: p.ink,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 40),
        ),
        child: Text(
          context.tr(RemainingL10n.login),
          style: LuxeType.body(
            p.ink,
            size: 14,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Material(
        color: p.canvas,
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.hairline, width: 0.6)),
          ),
          child: SizedBox(
            height: height,
            child: IconTheme.merge(
              data: IconThemeData(color: p.ink, size: 22),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  leading,
                  const SizedBox(width: 4),
                  Expanded(
                    child: _SearchEntry(onTap: () => showHomeSearch(context)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: context.tr(HomeL10n.notifications),
                    // Tabs are the buyer side; guests sign in first.
                    onPressed: () => signedIn
                        ? context.switchToRoute(
                            AppRouteNames.buyerNotifications,
                          )
                        : context.openRoute(AppRouteNames.login),
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      backgroundColor: p.accent,
                      textColor: p.onAccent,
                      label: Text(unread > 99 ? '99+' : '$unread'),
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                  if (signedIn)
                    IconButton(
                      tooltip: context.tr(CoreL10n.cart),
                      onPressed: () => context.openRoute(AppRouteNames.cart),
                      icon: Badge(
                        isLabelVisible: bag > 0,
                        backgroundColor: p.accent,
                        textColor: p.onAccent,
                        label: Text(bag > 99 ? '99+' : '$bag'),
                        child: const Icon(Icons.shopping_cart_outlined),
                      ),
                    ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Looks like an input; opens the spotlight search.
class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final hint = context.tr(HomeL10n.searchFieldHint);

    return Semantics(
      button: true,
      textField: true,
      label: hint,
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        shape: StadiumBorder(side: BorderSide(color: p.hairline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: p.inkFaint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.body(p.inkFaint, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
