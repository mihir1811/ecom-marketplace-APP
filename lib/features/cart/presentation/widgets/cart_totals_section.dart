import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/cart_provider.dart';
import '../../../../core/utils/app_currency.dart';

/// Price breakdown; rebuilds only when totals change.
class CartTotalsSection extends ConsumerWidget {
  const CartTotalsSection({super.key});

  String _inr(double v) => AppCurrency.format(v.toStringAsFixed(0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(cartTotalsProvider);

    return Column(
      children: [
        _priceRow(
          'Subtotal',
          '${_inr(totals.subtotalInr)} · \$${totals.subtotalUsd.toStringAsFixed(2)}',
        ),
        _priceRow('GST (3%)', _inr(totals.gstInr)),
        _priceRow('Transaction fee (2.18%)', _inr(totals.transactionFeeInr)),
        _priceRow('Platform fee', _inr(totals.platformFeeInr)),
        const Divider(height: 24),
        Row(
          children: [
            Text(
              'Total',
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              _inr(totals.totalInr),
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.bronze,
              ),
            ),
          ],
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
