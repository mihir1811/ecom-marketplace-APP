import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../application/cart_provider.dart';
import '../widgets/cart_address_section.dart';
import '../widgets/cart_checkout_button.dart';
import '../widgets/cart_items_section.dart';
import '../widgets/cart_promo_section.dart';
import '../widgets/cart_totals_section.dart';

/// Buyer cart — loads full cart+delivery once on open; sections watch slices.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Microtask (not post-frame): runs before CartNotifier's light bootstrap
    // microtask joins this full load — avoids cancel+retry of the same APIs.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(cartProvider.notifier).refresh(mode: CartLoadMode.full);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(cartIsLoadingProvider);
    final isEmpty = ref.watch(cartIsEmptyProvider);
    final error = ref.watch(cartErrorProvider);

    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppTopBar(
        title: '',
        titleWidget: const _CartAppBarTitle(),
        extraActions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref
                .read(cartProvider.notifier)
                .refresh(mode: CartLoadMode.full, force: true),
          ),
        ],
      ),
      body: isLoading && isEmpty
          ? const Center(child: CircularProgressIndicator())
          : error != null && isEmpty
              ? _CartErrorState(
                  message: error,
                  onRetry: () => ref
                      .read(cartProvider.notifier)
                      .refresh(mode: CartLoadMode.full, force: true),
                )
              : isEmpty
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
          Icon(
            Icons.shopping_bag_outlined,
            size: 56,
            color: AppColors.textMuted(context),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text('Your cart is empty', style: AppTypography.body),
          const SizedBox(height: AppSpacing.s16),
          FilledButton(
            onPressed: () => context.goBack(),
            child: const Text('Continue shopping'),
          ),
        ],
      ),
    );
  }
}

class _CartErrorState extends StatelessWidget {
  const _CartErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: AppTypography.body),
            const SizedBox(height: AppSpacing.s16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
