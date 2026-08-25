import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_navigation.dart';
import '../router/route_names.dart';
import 'auth_providers.dart';

/// Renders [child] only for seller accounts; otherwise redirects away.
class SellerOnlyGate extends ConsumerWidget {
  const SellerOnlyGate({
    super.key,
    required this.child,
    this.fallbackRoute = AppRouteNames.home,
  });

  final Widget child;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSeller = ref.watch(authProvider.select((s) => s.isSeller));
    if (!isSeller) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.resetTo(fallbackRoute);
      });
      return const SizedBox.shrink();
    }
    return child;
  }
}
