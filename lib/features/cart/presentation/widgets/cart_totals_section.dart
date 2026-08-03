import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/cart_provider.dart';
import '../../../payment/application/payment_checkout_provider.dart';

/// Price breakdown from cart summary (no estimated INR row).
class CartTotalsSection extends ConsumerWidget {
  const CartTotalsSection({super.key});

  static const _verificationRate = 0.01;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(exchangeRateProvider);
    final totals = ref.watch(cartTotalsProvider);
    final summary = ref.watch(cartSummaryProvider);
    final wantVerification = ref.watch(
      paymentCheckoutProvider.select((s) => s.wantGemworldVerification),
    );

    final merchandise = totals.discountedSubtotalUsd;
    final verificationFee =
        wantVerification ? merchandise * _verificationRate : 0.0;
    final displayTotal = merchandise + verificationFee;

    return Column(
      children: [
        _priceRow(
          'Subtotal',
          '\$${totals.subtotalUsd.toStringAsFixed(2)}',
        ),
        if (totals.automaticDiscountUsd > 0)
          _priceRow(
            'Automatic discount',
            '-\$${totals.automaticDiscountUsd.toStringAsFixed(2)}',
          ),
        if (totals.promoDiscountUsd > 0)
          _priceRow(
            'Promo discount',
            '-\$${totals.promoDiscountUsd.toStringAsFixed(2)}',
          ),
        if (totals.totalDiscountUsd > 0 &&
            totals.promoDiscountUsd <= 0 &&
            totals.automaticDiscountUsd <= 0)
          _priceRow(
            'Discount',
            '-\$${totals.totalDiscountUsd.toStringAsFixed(2)}',
          ),
        _priceRow(
          'Merchandise total',
          '\$${merchandise.toStringAsFixed(2)}',
        ),
        if (wantVerification)
          _priceRow(
            'GemWorld verification (1%)',
            '\$${verificationFee.toStringAsFixed(2)}',
          ),
        if (summary.appliedPromoCodes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              children: [
                for (final promo in summary.appliedPromoCodes)
                  Chip(
                    label: Text(promo.code),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.sandSurface,
                  ),
              ],
            ),
          ),
        ],
        const Divider(height: 24),
        Row(
          children: [
            Text(
              'Total (USD)',
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              '\$${displayTotal.toStringAsFixed(2)}',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.bronze,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'Final INR (GST & fees) is confirmed at payment.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
