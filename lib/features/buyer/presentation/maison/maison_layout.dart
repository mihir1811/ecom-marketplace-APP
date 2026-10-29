import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/navigation/top_bar/section_top_bar.dart';
import '../../../../core/widgets/navigation/bottom_nav/app_bottom_nav_destinations.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../widgets/buyer_drawer.dart';

/// Buyer account shell: the shared [SectionTopBar], buyer drawer and the
/// "back goes one level up" rule. [detail] pages get Back; bottom-nav tabs
/// (Wishlist, Profile) never do.
class MaisonLayout extends ConsumerWidget {
  const MaisonLayout({
    required this.child,
    this.detail = false,
    this.scrollsBehindDock = false,
    super.key,
  });

  final Widget child;
  final bool detail;

  /// [child] runs under the floating bottom dock and ends its own scroll
  /// with the bottom padding, instead of being inset above the dock.
  final bool scrollsBehindDock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(
      authProvider.select((s) => (signedIn: s.isAuthenticated)),
    );
    if (!auth.signedIn) return const LoginScreen();

    final p = context.atelier;
    final location = GoRouterState.of(context).uri.path;
    final backFallback =
        AppNavigation.logicalParentOf(location) ?? AppRouteNames.home;
    void goBack() => context.goBack(fallbackLocation: backFallback);
    final isTab = AppBottomNav.isVisibleOn(location);

    return PopScope(
      canPop: GoRouter.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !context.mounted) return;
        goBack();
      },
      child: AppScaffold(
        drawer: const BuyerDrawer(),
        backgroundColor: p.canvas,
        safeBottom: !scrollsBehindDock,
        appBar: SectionTopBar(
          location: location,
          showBack: detail && !isTab,
          onBack: goBack,
          backgroundColor: isTab ? null : p.canvas,
        ),
        body: child,
      ),
    );
  }
}
