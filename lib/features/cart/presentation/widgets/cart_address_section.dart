import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/cart_provider.dart';
import 'cart_section_card.dart';
import 'delivery_address_sheet.dart';

/// Delivery address block; rebuilds only when address changes.
class CartAddressSection extends ConsumerWidget {
  const CartAddressSection({super.key});

  Future<void> _openAddress(BuildContext context, WidgetRef ref) async {
    final current = ref.read(cartAddressProvider);
    final saved = await showDeliveryAddressSheet(context, initial: current);
    if (saved != null) {
      ref.read(cartProvider.notifier).setAddress(saved);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(cartAddressProvider);
    final hasAddress = address != null;
    final muted = AppColors.textMutedLight;

    return CartSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.bronze,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'Deliver to',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _openAddress(context, ref),
                child: Text(
                  hasAddress ? 'Edit' : 'Add address',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Text(
            hasAddress
                ? '${address.fullName}\n${address.summaryLine}'
                : 'Add a delivery address to proceed to payment.',
            style: AppTypography.caption.copyWith(
              color: muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
