import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/theme_preference_provider.dart';
import '../../../../core/widgets/app_drawer_button.dart';
import '../../../notifications/application/notifications_provider.dart';
import '../theme/home_tokens.dart';

/// Floating home header: transparent over the hero, frosted glass after it.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.scrollOffset,
    required this.solidAfter,
    required this.onSearch,
    super.key,
  });

  static const barHeight = 56.0;

  final ValueListenable<double> scrollOffset;

  /// Scroll offset at which the header has fully become a solid bar.
  final double solidAfter;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return ValueListenableBuilder<double>(
      valueListenable: scrollOffset,
      builder: (context, offset, _) {
        final t = ((offset - (solidAfter - 120)) / 120).clamp(0.0, 1.0);
        final fg = Color.lerp(HomeStage.ink, palette.ink, t)!;
        final lightIcons = t < 0.5 || palette.isDark;

        Widget bar = Container(
          padding: EdgeInsets.only(top: top),
          decoration: BoxDecoration(
            color: palette.canvas.withValues(alpha: 0.82 * t),
            border: Border(
              bottom: BorderSide(
                color: palette.hairline.withValues(alpha: t),
                width: 0.6,
              ),
            ),
          ),
          child: SizedBox(
            height: barHeight,
            child: IconTheme.merge(
              data: IconThemeData(color: fg, size: 22),
              child: _HeaderContent(
                foreground: fg,
                solidity: t,
                onSearch: onSearch,
              ),
            ),
          ),
        );
        if (t > 0.01) {
          bar = ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18 * t, sigmaY: 18 * t),
              child: bar,
            ),
          );
        }
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: lightIcons
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                ),
          child: bar,
        );
      },
    );
  }
}

class _HeaderContent extends ConsumerWidget {
  const _HeaderContent({
    required this.foreground,
    required this.solidity,
    required this.onSearch,
  });

  final Color foreground;

  /// 0 over the hero, 1 once the header has become a solid bar.
  final double solidity;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(
      authProvider.select((s) => (isAuthenticated: s.isAuthenticated)),
    );
    final unread = auth.isAuthenticated
        ? ref.watch(notificationUnreadCountProvider)
        : 0;

    final Widget leading;
    if (auth.isAuthenticated) {
      leading = IconButton(
        tooltip: context.tr(RemainingL10n.menu),
        onPressed: () => openAppDrawer(context),
        icon: const Icon(Icons.menu_rounded),
      );
    } else {
      final dark = ref.watch(themePreferenceProvider);
      leading = IconButton(
        tooltip: context.tr(HomeL10n.appearance),
        onPressed: () =>
            ref.read(themePreferenceProvider.notifier).setDarkMode(!dark),
        icon: Icon(
          dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          size: 20,
        ),
      );
    }

    return Row(
      children: [
        const SizedBox(width: 6),
        leading,
        const SizedBox(width: 4),
        Expanded(
          child: _HeaderSearchField(solidity: solidity, onTap: onSearch),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: context.tr(HomeL10n.notifications),
          // Home is the buyer side, so its bell opens buyer notifications;
          // guests sign in first.
          onPressed: () => auth.isAuthenticated
              ? context.switchToRoute(AppRouteNames.buyerNotifications)
              : context.openRoute(AppRouteNames.login),
          icon: _Dot(
            count: unread,
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}

/// Full-width search entry: looks like an input, opens the spotlight search.
class _HeaderSearchField extends StatelessWidget {
  const _HeaderSearchField({required this.solidity, required this.onTap});

  final double solidity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final t = solidity;
    final hint = context.tr(HomeL10n.searchFieldHint);

    return Semantics(
      button: true,
      textField: true,
      label: hint,
      excludeSemantics: true,
      child: Material(
        color: Color.lerp(HomeStage.glass, palette.surface, t),
        shape: StadiumBorder(
          side: BorderSide(
            color: Color.lerp(HomeStage.glassBorder, palette.hairline, t)!,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeType.body(
                    Color.lerp(HomeStage.inkMuted, palette.inkFaint, t)!,
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal champagne count badge.
class _Dot extends StatelessWidget {
  const _Dot({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Badge(
      backgroundColor: HomeStage.gold,
      textColor: HomeStage.obsidian,
      label: Text(count > 99 ? '99+' : '$count'),
      textStyle: HomeType.figure(HomeStage.obsidian, size: 10),
      child: child,
    );
  }
}
