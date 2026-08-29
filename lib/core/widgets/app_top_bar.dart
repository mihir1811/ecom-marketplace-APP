import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import '../l10n/app_localizations.dart';
import '../router/app_navigation.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/cart/application/cart_provider.dart';
import '../../features/chat/application/chat_providers.dart';
import 'app_bar_actions.dart';
import 'app_drawer_button.dart';

/// Reusable top app bar with a fixed trailing action order:
/// **Cart → Wallet → Messages → Theme** (when signed in).
///
/// [extraActions] always render *before* that standard set.
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.leading,
    this.showDrawerButton = true,
    this.showThemeToggle = true,
    this.transparent = false,
    this.showCart = true,
    this.cartCount,
    this.showWallet = true,
    this.showMessages = true,
    @Deprecated('Use showWallet / showMessages') this.showSellerTools,
    this.onSellerWalletTap,
    this.onSellerMessagesTap,
    this.extraActions = const [],
    this.centerTitle = false,
    this.backgroundColor,
    this.elevation = 0,
    this.scrolledUnderElevation = 0,
  });

  final String title;
  final Widget? titleWidget;
  final Widget? leading;
  final bool showDrawerButton;
  final bool showThemeToggle;
  final bool transparent;
  final bool showCart;

  /// When null, live cart count is read from [cartItemCountProvider].
  final int? cartCount;
  final bool showWallet;
  final bool showMessages;

  /// Legacy alias — when non-null, overrides [showWallet] and [showMessages].
  @Deprecated('Use showWallet / showMessages')
  final bool? showSellerTools;
  final VoidCallback? onSellerWalletTap;
  final VoidCallback? onSellerMessagesTap;
  final List<Widget> extraActions;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final double scrolledUnderElevation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(
      authProvider.select(
        (s) => (
          isAuthenticated: s.isAuthenticated,
          isSeller: s.isSeller,
          canTransact: s.canTransact,
        ),
      ),
    );

    // ignore: deprecated_member_use_from_same_package
    final legacyTools = showSellerTools;
    final walletEnabled = legacyTools ?? showWallet;
    final messagesEnabled = legacyTools ?? showMessages;

    final liveCartCount =
        showCart && authState.isAuthenticated && cartCount == null
        ? ref.watch(cartItemCountProvider)
        : (cartCount ?? 0);

    final actions = <Widget>[...extraActions];

    if (authState.isAuthenticated) {
      // Fixed order: Cart → Wallet → Messages → Theme
      if (showCart) {
        actions.add(
          IconButton(
            tooltip: context.tr(CoreL10n.cart),
            onPressed: () => context.openRoute(AppRouteNames.cart),
            icon: Badge(
              isLabelVisible: liveCartCount > 0,
              label: Text('$liveCartCount'),
              backgroundColor: AppColors.bronze,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        );
      }

      if (walletEnabled) {
        actions.add(
          IconButton(
            tooltip: context.tr(CoreL10n.wallet),
            onPressed:
                onSellerWalletTap ??
                () => context.openRoute(
                  authState.isSeller && authState.canTransact
                      ? AppRouteNames.sellerWallet
                      : AppRouteNames.buyerWallet,
                ),
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
        );
      }

      if (messagesEnabled) {
        final hasUnread = ref.watch(chatHasUnreadProvider);
        actions.add(
          IconButton(
            tooltip: context.tr(CoreL10n.messages),
            onPressed:
                onSellerMessagesTap ??
                () => context.openRoute(
                  authState.isSeller && authState.canTransact
                      ? AppRouteNames.sellerChat
                      : AppRouteNames.buyerMessages,
                ),
            icon: Badge(
              isLabelVisible: hasUnread,
              smallSize: 8,
              backgroundColor: AppColors.bronze,
              child: const Icon(Icons.chat_bubble_outline),
            ),
          ),
        );
      }
    }

    // Theme stays last. Drawer is leading-only so it never breaks this order.
    actions.addAll(
      buildAppBarActions(
        showDrawerButton: false,
        showThemeToggle: showThemeToggle,
      ),
    );

    final location = GoRouterState.of(context).uri.path;
    final showBack =
        leading == null &&
        (GoRouter.of(context).canPop() || location != AppRouteNames.home);
    final effectiveLeading =
        leading ??
        (showBack
            ? BackButton(onPressed: () => context.goBack())
            : (showDrawerButton && authState.isAuthenticated
                  ? const AppDrawerButton()
                  : null));

    final hasBackButton = showBack || leading is BackButton;

    return AppBar(
      backgroundColor: transparent
          ? Colors.transparent
          : (backgroundColor ?? AppColors.bg(context)),
      surfaceTintColor: Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      centerTitle: hasBackButton ? false : centerTitle,
      titleSpacing: hasBackButton ? 0 : null,
      title:
          titleWidget ??
          Text(
            title,
            style: AppTypography.headline.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
      leading: effectiveLeading,
      automaticallyImplyLeading: false,
      actions: actions,
    );
  }
}

/// Simplified app bar — same trailing order as [AppTopBar] when signed in.
class SimpleAppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const SimpleAppTopBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.leading,
    this.showDrawerButton = true,
    this.showThemeToggle = true,
    this.showCart = true,
    this.showWallet = true,
    this.showMessages = true,
    this.transparent = false,
    this.centerTitle = false,
    this.backgroundColor,
  });

  final String title;
  final Widget? titleWidget;
  final Widget? leading;
  final bool showDrawerButton;
  final bool showThemeToggle;
  final bool showCart;
  final bool showWallet;
  final bool showMessages;
  final bool transparent;
  final bool centerTitle;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppTopBar(
      title: title,
      titleWidget: titleWidget,
      leading: leading,
      showDrawerButton: showDrawerButton,
      showThemeToggle: showThemeToggle,
      showCart: showCart,
      showWallet: showWallet,
      showMessages: showMessages,
      transparent: transparent,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
    );
  }
}
