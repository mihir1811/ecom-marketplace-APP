import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'buyer_drawer.dart';

final GlobalKey<ScaffoldState> buyerScaffoldKey = GlobalKey<ScaffoldState>();

void openBuyerDrawer([BuildContext? context]) {
  final state = buyerScaffoldKey.currentState;
  if (state != null) {
    state.openDrawer();
    return;
  }
  if (context != null) {
    Scaffold.maybeOf(context)?.openDrawer();
  }
}

/// Authenticated buyer shell.
///
/// When [title] is null, no app bar is shown (for shared screens that already
/// render their own header + menu button).
class BuyerLayout extends ConsumerWidget {
  const BuyerLayout({
    super.key,
    required this.child,
    this.title,
  });

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    final hasAppBar = title != null;
    final isSeller = authState.isSeller;

    return AppScaffold(
      scaffoldKey: buyerScaffoldKey,
      backgroundColor: AppColors.creamBg,
      drawer: const BuyerDrawer(),
      appBar: hasAppBar
          ? AppBar(
              backgroundColor: AppColors.creamBg,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu),
                onPressed: () => openBuyerDrawer(context),
              ),
              title: Text(
                title!,
                style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
              ),
              actions: [
                IconButton(
                  tooltip: 'Shop',
                  onPressed: () => context.go(AppRouteNames.home),
                  icon: const Icon(Icons.storefront_outlined),
                ),
                if (isSeller)
                  TextButton.icon(
                    onPressed: () => context.go(AppRouteNames.sellerDashboard),
                    icon: const Icon(Icons.dashboard_outlined, size: 18),
                    label: Text(
                      'Dashboard',
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: child,
    );
  }
}
