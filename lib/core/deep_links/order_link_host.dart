import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import '../router/route_names.dart';
import 'order_link.dart';
import 'order_links.dart';

/// Opens a WhatsApp order link once it can: after the saved session is read
/// and the navigator exists (cold start), and after sign-in when the person
/// is signed out. The order screen is pushed on top of what is open (home on
/// a cold start), so Back stays in the app.
class OrderLinkHost extends ConsumerStatefulWidget {
  const OrderLinkHost({required this.router, super.key});

  final GoRouter router;

  @override
  ConsumerState<OrderLinkHost> createState() => _OrderLinkHostState();
}

class _OrderLinkHostState extends ConsumerState<OrderLinkHost> {
  static const _authRoutes = <String>{
    AppRouteNames.login,
    AppRouteNames.register,
    AppRouteNames.forgotPassword,
    AppRouteNames.verifyOtp,
    AppRouteNames.resetPassword,
    AppRouteNames.recoverAccount,
  };

  var _scheduled = false;

  @override
  void initState() {
    super.initState();
    OrderLinks.instance.addListener(_schedule);
    widget.router.routerDelegate.addListener(_schedule);
    ref.listenManual(
      authProvider.select((s) => (s.isBootstrapping, s.isAuthenticated)),
      (_, _) => _schedule(),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    OrderLinks.instance.removeListener(_schedule);
    widget.router.routerDelegate.removeListener(_schedule);
    super.dispose();
  }

  /// Decides after the frame, so route changes in flight (the sign-in
  /// screen going home) land first.
  void _schedule() {
    if (_scheduled || OrderLinks.instance.pending == null) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _tryOpen();
    });
  }

  void _tryOpen() {
    final links = OrderLinks.instance;
    if (links.pending == null) return;
    final auth = ref.read(authProvider);
    if (auth.isBootstrapping) return;
    final router = widget.router;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path.isEmpty) return; // navigator not built yet

    if (!auth.isAuthenticated) {
      if (links.signInRequested) return;
      links.signInRequested = true;
      if (!_authRoutes.contains(path)) router.push(AppRouteNames.login);
      return;
    }
    // Wait for the sign-in flow to finish and leave its screens.
    if (_authRoutes.contains(path)) return;

    final link = links.take();
    final location = switch (link) {
      BuyerOrderLink(:final orderId) => AppRouteNames.jewelryOrderDetailPath(
        orderId,
      ),
      ShopOrderLink(:final orderId) => AppRouteNames.jewelryShopOrdersPath(
        openOrderId: orderId,
      ),
      null => null,
    };
    if (location == null) return;
    router.push(location);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
