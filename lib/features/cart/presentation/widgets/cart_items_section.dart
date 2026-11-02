import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../application/cart_provider.dart';
import 'cart_item_card.dart';

/// Line items; rebuilds only when items change. Lines stagger in on first
/// show and the list eases its height as lines are removed.
class CartItemsSection extends ConsumerWidget {
  const CartItemsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartItemsProvider);
    final still = MediaQuery.disableAnimationsOf(context);

    return AnimatedSize(
      duration: LuxeMotion.medium,
      curve: LuxeMotion.settle,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              key: ValueKey(items[i].cartId),
              padding: const EdgeInsets.only(bottom: 8),
              child: still
                  ? CartItemCard(item: items[i])
                  : CartItemCard(item: items[i])
                        .animate()
                        .fadeIn(delay: (60 * i).ms, duration: 360.ms)
                        .moveY(
                          begin: 14,
                          end: 0,
                          delay: (60 * i).ms,
                          duration: 600.ms,
                          curve: LuxeMotion.settle,
                        ),
            ),
        ],
      ),
    );
  }
}
