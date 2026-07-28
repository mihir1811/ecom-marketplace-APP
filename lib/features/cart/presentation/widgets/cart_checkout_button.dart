import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/cart_provider.dart';
import 'delivery_address_sheet.dart';

/// Checkout CTA; rebuilds only when address presence changes.
class CartCheckoutButton extends ConsumerWidget {
  const CartCheckoutButton({super.key});

  Future<void> _openAddress(BuildContext context, WidgetRef ref) async {
    final current = ref.read(cartAddressProvider);
    final saved = await showDeliveryAddressSheet(context, initial: current);
    if (saved != null) {
      ref.read(cartProvider.notifier).setAddress(saved);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAddress = ref.watch(cartHasAddressProvider);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.charcoal,
          foregroundColor: AppColors.warmWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.r12),
          ),
        ),
        onPressed: hasAddress
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment flow will be available soon.'),
                  ),
                );
              }
            : () => _openAddress(context, ref),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hasAddress ? 'Proceed to payment' : 'Add delivery address',
              style: AppTypography.label.copyWith(
                color: AppColors.warmWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!hasAddress)
              Text(
                'Required before payment',
                style: AppTypography.caption.copyWith(
                  color: AppColors.warmWhite.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
