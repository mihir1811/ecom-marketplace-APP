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
import '../../../cart/application/cart_provider.dart';
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
              child: _HeaderContent(foreground: fg, onSearch: onSearch),
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
  const _HeaderContent({required this.foreground, required this.onSearch});

  final Color foreground;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(
      authProvider.select(
        (s) => (isAuthenticated: s.isAuthenticated, isSeller: s.isSeller),
      ),
    );

    final wordmark = Text(
      'GEMWORLD',
      style: HomeType.label(
        foreground,
        size: 15,
      ).copyWith(letterSpacing: 5.5, fontWeight: FontWeight.w500),
    );
    final search = IconButton(
      tooltip: context.tr(HomeL10n.searchPrefix),
      onPressed: onSearch,
      icon: const Icon(Icons.search_rounded),
    );

    if (!auth.isAuthenticated) {
      final dark = ref.watch(themePreferenceProvider);
      return Row(
        children: [
          const SizedBox(width: 6),
          IconButton(
            tooltip: context.tr(HomeL10n.appearance),
            onPressed: () =>
                ref.read(themePreferenceProvider.notifier).setDarkMode(!dark),
            icon: Icon(
              dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
          ),
          Expanded(child: wordmark),
          search,
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _SignInPill(foreground: foreground),
          ),
        ],
      );
    }

    final cartCount = ref.watch(cartItemCountProvider);
    final unread = ref.watch(notificationUnreadCountProvider);
    return Row(
      children: [
        const SizedBox(width: 6),
        IconButton(
          tooltip: context.tr(RemainingL10n.menu),
          onPressed: () => openAppDrawer(context),
          icon: const Icon(Icons.menu_rounded),
        ),
        Expanded(child: wordmark),
        search,
        IconButton(
          tooltip: context.tr(HomeL10n.notifications),
          onPressed: () => context.switchToRoute(
            auth.isSeller
                ? AppRouteNames.sellerNotifications
                : AppRouteNames.buyerNotifications,
          ),
          icon: _Dot(
            count: unread,
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        IconButton(
          tooltip: context.tr(CoreL10n.cart),
          onPressed: () => context.openRoute(AppRouteNames.cart),
          icon: _Dot(
            count: cartCount,
            child: const Icon(Icons.shopping_bag_outlined),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}

class _SignInPill extends StatelessWidget {
  const _SignInPill({required this.foreground});

  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => context.openRoute(AppRouteNames.login),
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        side: BorderSide(color: foreground.withValues(alpha: 0.4)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(
        context.tr(RemainingL10n.login),
        style: HomeType.label(foreground),
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
