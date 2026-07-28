import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/cart_provider.dart';
import '../widgets/cart_address_section.dart';
import '../widgets/cart_checkout_button.dart';
import '../widgets/cart_items_section.dart';
import '../widgets/cart_promo_section.dart';
import '../widgets/cart_totals_section.dart';

/// Buyer cart — shell only; sections watch their own cart slices.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEmpty = ref.watch(cartIsEmptyProvider);

    return AppScaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: const _CartAppBarTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: isEmpty
          ? const _CartEmptyState()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              children: const [
                CartItemsSection(),
                CartAddressSection(),
                SizedBox(height: AppSpacing.s12),
                CartPromoSection(),
                SizedBox(height: AppSpacing.s16),
                CartTotalsSection(),
                SizedBox(height: AppSpacing.s24),
                CartCheckoutButton(),
                SizedBox(height: AppSpacing.s24),
              ],
            ),
    );
  }
}

class _CartAppBarTitle extends ConsumerWidget {
  const _CartAppBarTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartItemCountProvider);

    return Row(
      children: [
        Text(
          'Your Cart',
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: AppSpacing.s8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.bronze,
            borderRadius: BorderRadius.circular(AppSpacing.circular),
          ),
          child: Text(
            '$count',
            style: AppTypography.caption.copyWith(
              color: AppColors.warmWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CartEmptyState extends StatelessWidget {
  const _CartEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 56,
            color: AppColors.textMutedLight,
          ),
          const SizedBox(height: AppSpacing.s16),
          Text('Your cart is empty', style: AppTypography.body),
          const SizedBox(height: AppSpacing.s16),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Continue shopping'),
          ),
        ],
      ),
    );
  }
}
