import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/seller/presentation/atelier/atelier_components.dart';
import '../../../features/seller/presentation/atelier/atelier_motion.dart';
import '../../../features/seller/presentation/atelier/atelier_theme.dart';
import '../../auth/auth_providers.dart';
import '../../auth/confirm_sign_out.dart';
import '../../l10n/app_localizations.dart';
import '../../router/route_names.dart';
import '../../router/workspace_mode.dart';
import '../profile_avatar.dart';
import 'app_drawer_stage.dart';
import 'workspace_switch.dart';

/// One destination in an [AppNavDrawer].
class AppNavItem {
  const AppNavItem({
    required this.route,
    required this.label,
    required this.icon,
    this.badge = 0,
  });

  final String route;
  final String label;
  final IconData icon;
  final int badge;
}

/// A titled group of [AppNavItem]s.
class AppNavGroup {
  const AppNavGroup({required this.title, required this.items});

  final String title;
  final List<AppNavItem> items;
}

/// The one drawer layout shared by the buyer and seller sides.
///
/// Same anatomy on both sides, top to bottom:
/// 1. Who you are + which side you are on
/// 2. Buyer | Seller switch (or "Start selling" for non-sellers)
/// 3. Grouped destinations with the current page highlighted
/// 4. Home + Sign out
///
/// Laid straight onto the [AppDrawerStage] backdrop (no panel); every row
/// eases in as the stage opens.
class AppNavDrawer extends ConsumerWidget {
  const AppNavDrawer({
    required this.workspace,
    required this.selectedRoute,
    required this.groups,
    required this.displayName,
    this.imageUrl,
    this.showPendingNotice = false,
    super.key,
  });

  final AppWorkspace workspace;
  final String selectedRoute;
  final List<AppNavGroup> groups;
  final String displayName;
  final String? imageUrl;
  final bool showPendingNotice;

  /// The single best-matching destination, so `/auctions/activity` lights up
  /// "My bids" only — not "Live auctions" as well.
  String? _selectedItemRoute() {
    String? best;
    for (final group in groups) {
      for (final item in group.items) {
        final matches =
            selectedRoute == item.route ||
            selectedRoute.startsWith('${item.route}/');
        if (matches && (best == null || item.route.length > best.length)) {
          best = item.route;
        }
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final selected = _selectedItemRoute();
    final overline = context.tr(
      workspace == AppWorkspace.seller
          ? NavL10n.sellerWorkspace
          : NavL10n.buyerAccount,
    );
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    var index = 2;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDrawerReveal(
              index: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 6, 14),
                child: Row(
                  children: [
                    if (hasImage)
                      ProfileAvatar(
                        displayName: displayName,
                        imageUrl: imageUrl,
                        radius: 22,
                      )
                    else
                      AtelierMonogram(name: displayName, size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            overline.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.overline(p.gold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.display(p.ink, size: 21),
                          ),
                        ],
                      ),
                    ),
                    AtelierIconButton(
                      icon: Icons.close_rounded,
                      tooltip: context.tr(CoreL10n.close),
                      onPressed: () => closeAppDrawer(context),
                    ),
                  ],
                ),
              ),
            ),
            AppDrawerReveal(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 12, 14),
                child: WorkspaceSwitcher(current: workspace),
              ),
            ),
            if (showPendingNotice)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: AtelierPill(
                  label: context.tr(NavL10n.pendingLocked),
                  tone: AtelierTone.amber,
                  icon: Icons.lock_clock_outlined,
                ),
              ),
            const AtelierHairline(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                children: [
                  for (final group in groups)
                    if (group.items.isNotEmpty) ...[
                      AppDrawerReveal(
                        index: index++,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                          child: Text(
                            group.title.toUpperCase(),
                            style: AtelierType.overline(p.muted),
                          ),
                        ),
                      ),
                      for (final item in group.items)
                        AppDrawerReveal(
                          index: index++,
                          child: _NavTile(
                            item: item,
                            selected: item.route == selected,
                            onTap: () => _go(context, item.route),
                          ),
                        ),
                    ],
                ],
              ),
            ),
            const AtelierHairline(),
            AppDrawerReveal(
              index: index,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AtelierButton(
                        label: context.tr(NavL10n.home),
                        icon: Icons.home_outlined,
                        variant: AtelierButtonVariant.secondary,
                        compact: true,
                        onPressed: () => _go(context, AppRouteNames.home),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AtelierButton(
                        label: context.tr(AccountCommerceL10n.signOut),
                        icon: Icons.logout_rounded,
                        variant: AtelierButtonVariant.danger,
                        compact: true,
                        onPressed: () => _signOut(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Closes the drawer, then replaces the page — drawer destinations are
  /// peers, so back never walks through a trail of previously opened tools.
  static void _go(BuildContext context, String route) {
    final router = GoRouter.of(context);
    closeAppDrawer(context);
    final current = router.routerDelegate.currentConfiguration.uri.path;
    if (current == route) return;
    router.go(route);
  }

  static Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final auth = ref.read(authProvider.notifier);
    final confirmed = await confirmSignOut(context);
    if (!confirmed || !context.mounted) return;
    // Let the page settle back before the session (and the drawer) goes.
    await closeAppDrawer(context);
    auth.logout();
    router.go(AppRouteNames.home);
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticLabel: item.badge > 0
            ? '${item.label}, ${item.badge}'
            : item.label,
        child: AnimatedContainer(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? p.goldSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AtelierRadius.md),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AtelierMotion.base,
                width: 3,
                height: 18,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: selected ? p.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(item.icon, size: 20, color: selected ? p.gold : p.inkSoft),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.label(
                    selected ? p.ink : p.inkSoft,
                    size: 14,
                    weight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (item.badge > 0) CountBubble(count: item.badge),
            ],
          ),
        ),
      ),
    );
  }
}
