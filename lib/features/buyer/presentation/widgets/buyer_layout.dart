import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/auth/guest_login_redirect.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
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

  /// Stacked detail / flow pages show Back instead of the menu button.
  static bool _isDetailRoute(String route) {
    final parent = AppNavigation.logicalParentOf(route);
    return parent != null && parent.startsWith('/buyer/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return const GuestLoginRedirect();
    }

    final hasAppBar = title != null;
    final canPop = GoRouter.of(context).canPop();
    final location = GoRouterState.of(context).uri.path;
    // With nothing to pop, back goes one level up (detail → its list,
    // any account page → home) and never exits the app silently.
    final backFallback =
        AppNavigation.logicalParentOf(location) ?? AppRouteNames.home;
    void goBack() => context.goBack(fallbackLocation: backFallback);

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!context.mounted) return;
        goBack();
      },
      child: AppScaffold(
        backgroundColor: AppColors.bg(context),
        drawer: const BuyerDrawer(),
        appBar: hasAppBar
            ? AppTopBar(
                title: title!,
                leading: _isDetailRoute(location)
                    ? BackButton(onPressed: goBack)
                    : const AppDrawerButton(),
                showDrawerButton: false,
              )
            : null,
        body: child,
      ),
    );
  }
}
