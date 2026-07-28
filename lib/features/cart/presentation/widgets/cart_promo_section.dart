import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/cart_provider.dart';
import 'cart_section_card.dart';

/// Promo code field; rebuilds only when promo state changes.
class CartPromoSection extends ConsumerStatefulWidget {
  const CartPromoSection({super.key});

  @override
  ConsumerState<CartPromoSection> createState() => _CartPromoSectionState();
}

class _CartPromoSectionState extends ConsumerState<CartPromoSection> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promo = ref.watch(cartPromoProvider);

    return CartSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 20,
                color: AppColors.bronze,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'Promo code',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: 'Enter code',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.textMutedLight,
                  foregroundColor: AppColors.warmWhite,
                ),
                onPressed: () {
                  final ok = ref
                      .read(cartProvider.notifier)
                      .applyPromo(_promoController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Promo applied (5% off)'
                            : 'Invalid promo code. Try GEM5',
                      ),
                    ),
                  );
                },
                child: const Text('Apply'),
              ),
            ],
          ),
          if (promo.applied)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s8),
              child: Text(
                'Code ${promo.code} applied',
                style: AppTypography.caption.copyWith(
                  color: AppColors.bronze,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
