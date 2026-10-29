import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/home/presentation/widgets/home_search_overlay.dart';
import '../../../auth/auth_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_navigation.dart';
import '../../../router/route_names.dart';
import '../../../theme/luxe_tokens.dart';
import '../../app_drawer_button.dart';
import 'top_bar_actions.dart';
import 'top_bar_registry.dart';

/// The app's one top bar for the marketplace, jewellery, buyer and seller
/// sections.
///
/// Leading: back, menu, or sign-in for guests. Middle: the global search
/// field on sections that have search. Trailing: the section's shortcuts.
/// What it carries comes from [TopBarRegistry] — screens only say whether
/// they show back.
///
/// The bar holds still while pages change: it flies as a [Hero] between
/// routes that both show it, and [AppBottomNavHost] lays a copy over tab
/// switches. Only its icons change when the section does.
class SectionTopBar extends StatelessWidget implements PreferredSizeWidget {
  const SectionTopBar({
    super.key,
    this.location,
    this.showBack = false,
    this.onBack,
    this.backgroundColor,
  });

  static const double height = 60;

  /// Shared by every instance so route transitions keep one bar on screen.
  static const heroTag = 'gw.sectionTopBar';

  /// Defaults to the enclosing route's location. Pass it where there is no
  /// route (overlays outside the navigator).
  final String? location;
  final bool showBack;

  /// Defaults to [AppNavigation.back].
  final VoidCallback? onBack;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final body = _SectionTopBarBody(
      location: location ?? GoRouterState.of(context).uri.path,
      showBack: showBack,
      onBack: onBack,
      backgroundColor: backgroundColor,
    );
    return Hero(
      tag: heroTag,
      transitionOnUserGestures: true,
      // Fly the destination's bar: its icons are the ones that stay.
      flightShuttleBuilder: (_, _, _, _, toContext) =>
          IgnorePointer(child: (toContext.widget as Hero).child),
      child: body,
    );
  }
}

class _SectionTopBarBody extends ConsumerWidget {
  const _SectionTopBarBody({
    required this.location,
    required this.showBack,
    required this.onBack,
    required this.backgroundColor,
  });

  final String location;
  final bool showBack;
  final VoidCallback? onBack;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
    final spec = TopBarRegistry.specFor(location);

    final Widget leading;
    if (showBack) {
      leading = IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onBack ?? () => context.goBack(),
        icon: const Icon(Icons.arrow_back_rounded),
      );
    } else if (signedIn) {
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
        color: backgroundColor ?? p.canvas,
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.hairline, width: 0.6)),
          ),
          child: SizedBox(
            height: SectionTopBar.height,
            child: IconTheme.merge(
              data: IconThemeData(color: p.ink, size: 22),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  leading,
                  const SizedBox(width: 4),
                  if (spec.search)
                    Expanded(
                      child: _SearchEntry(onTap: () => showHomeSearch(context)),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 4),
                  TopBarActions(
                    location: location,
                    look: TopBarActionLook.plain,
                    includeSearch: false,
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
