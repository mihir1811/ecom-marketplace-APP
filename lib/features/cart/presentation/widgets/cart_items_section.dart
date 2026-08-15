import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/cart_provider.dart';
import 'cart_item_card.dart';

/// Line items + count caption; rebuilds only when items change.
class CartItemsSection extends ConsumerWidget {
  const CartItemsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartItemsProvider);
    final count = items.length;
    const muted = AppColors.textMutedLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count item${count == 1 ? '' : 's'} in your cart',
          style: AppTypography.caption.copyWith(
            color: muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        for (final item in items) ...[
          CartItemCard(item: item),
          const SizedBox(height: AppSpacing.s12),
        ],
      ],
    );
  }
}
