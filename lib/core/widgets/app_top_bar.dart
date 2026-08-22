import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'theme_toggle_button.dart';

/// Reusable top app bar with standardized actions including global theme toggle.
///
/// Provides consistent app bar across all screens with:
/// - Optional leading action (back/menu)
/// - Title
/// - Standard trailing actions (theme toggle, compare, cart, etc.)
/// - Role-based actions for sellers
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onBack,
    this.showThemeToggle = true,
    this.showCompare = false,
    this.showCart = false,
    this.cartCount = 0,
    this.showSellerTools = false,
    this.onSellerWalletTap,
    this.onSellerMessagesTap,
    this.extraActions = const [],
    this.centerTitle = false,
    this.backgroundColor,
    this.elevation = 0,
    this.scrolledUnderElevation = 0,
  });

  final String title;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBack;
  final bool showThemeToggle;
  final bool showCompare;
  final bool showCart;
  final int cartCount;
  final bool showSellerTools;
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
        (s) => (isAuthenticated: s.isAuthenticated, isSeller: s.isSeller, canTransact: s.canTransact),
      ),
    );

    final effectiveShowSellerTools = showSellerTools &&
        authState.isAuthenticated &&
        authState.isSeller &&
        authState.canTransact;

    final actions = <Widget>[];

    if (showCompare) {
      actions.add(
        IconButton(
          tooltip: 'Compare',
          onPressed: () => context.push(AppRouteNames.comparison),
          icon: const Icon(Icons.compare_arrows_rounded),
        ),
      );
    }

    if (showCart) {
      actions.add(
        IconButton(
          tooltip: 'Cart',
          onPressed: () => context.push(AppRouteNames.cart),
          icon: Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            backgroundColor: AppColors.bronze,
            child: const Icon(Icons.shopping_bag_outlined),
          ),
        ),
      );
    }

    if (effectiveShowSellerTools) {
      if (onSellerWalletTap != null) {
        actions.add(
          IconButton(
            tooltip: 'Wallet',
            onPressed: onSellerWalletTap,
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
        );
      }
      if (onSellerMessagesTap != null) {
        actions.add(
          IconButton(
            tooltip: 'Messages',
            onPressed: onSellerMessagesTap,
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        );
      }
    }

    actions.addAll(extraActions);

    if (showThemeToggle) {
      actions.add(const ThemeToggleButton());
      actions.add(const SizedBox(width: AppSpacing.s8));
    }

    final leadingWidget = leading ??
        (automaticallyImplyLeading && onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null);

    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.bg(context),
      surfaceTintColor: Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      centerTitle: centerTitle,
      title: Text(
        title,
        style: AppTypography.headline.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
      leading: leadingWidget,
      actions: actions,
    );
  }
}

/// Simplified app bar for screens that just need a title and theme toggle.
class SimpleAppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const SimpleAppTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.leading,
    this.showThemeToggle = true,
    this.backgroundColor,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? leading;
  final bool showThemeToggle;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppTopBar(
      title: title,
      onBack: onBack,
      leading: leading,
      showThemeToggle: showThemeToggle,
      backgroundColor: backgroundColor,
      showCompare: false,
      showCart: false,
      showSellerTools: false,
    );
  }
}