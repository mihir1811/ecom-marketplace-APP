import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../application/jewelry_bag_provider.dart';

/// Shopping-bag control with the piece count; opens the jewellery bag.
/// Hidden while signed out, like the cart.
class JewelryBagButton extends ConsumerWidget {
  const JewelryBagButton({super.key, this.glass = false});

  /// Translucent treatment for use over imagery.
  final bool glass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
    if (!signedIn) return const SizedBox.shrink();
    final count = ref.watch(jewelryBagCountProvider);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: LuxeIconButton(
        icon: Icons.shopping_bag_outlined,
        tooltip: context.tr(JewelryMarketL10n.bagTitle),
        glass: glass,
        size: 42,
        badge: count > 0 ? count : null,
        onPressed: () => context.push(AppRouteNames.jewelryBag),
      ),
    );
  }
}
