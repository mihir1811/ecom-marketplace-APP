import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'buyer_drawer.dart';

void openBuyerDrawer([BuildContext? context]) {
  if (context != null) {
    openAppDrawer(context);
  }
}

/// Authenticated buyer shell.
///
/// When [title] is null, no app bar is shown (for shared screens that already
/// render their own header + menu button).
class BuyerLayout extends ConsumerWidget {
  const BuyerLayout({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    final hasAppBar = title != null;

    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      drawer: const BuyerDrawer(),
      appBar: hasAppBar
          ? AppTopBar(
              title: title!,
              leading: IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu),
                onPressed: () => openBuyerDrawer(context),
              ),
              showDrawerButton: false,
              // Cart → Wallet → Messages → Theme (AppTopBar fixed order)
              showCart: true,
              showWallet: true,
              showMessages: true,
              showThemeToggle: true,
              onSellerWalletTap: () => context.openRoute(AppRouteNames.buyerWallet),
              onSellerMessagesTap: () =>
                  context.openRoute(AppRouteNames.buyerMessages),
            )
          : null,
      body: child,
    );
  }
}
