import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../payment/application/payment_checkout_provider.dart';
import '../../application/cart_provider.dart';
import '../../application/fees_providers.dart';
import '../../domain/models/cart_order_estimate.dart';
import '../../domain/models/fee_rule.dart';
import 'cart_section_card.dart';

/// Order summary card — merchandise from API, fees from `GET /fees` (+ fallbacks).
class CartTotalsSection extends ConsumerWidget {
  const CartTotalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(exchangeRateProvider);
    final totals = ref.watch(cartTotalsProvider);
    final summary = ref.watch(cartSummaryProvider);
    final items = ref.watch(cartProvider.select((s) => s.items));
    final availableItems = items.where((i) => i.isAvailable).toList();
    final merchandiseUsd = ref.watch(cartAvailableMerchandiseUsdProvider);
    final fees = ref.watch(activeFeesProvider).valueOrNull ?? FeeRulesCatalog.empty;
    final wantVerification = ref.watch(
      paymentCheckoutProvider.select((s) => s.wantGemworldVerification),
    );

    final lines = availableItems
        .map(
          (item) => CartLineForFees(
            productType: item.productType,
            amountUsd: item.displayPriceUsd,
          ),
        )
        .toList();

    final estimate = CartOrderEstimate.compute(
      merchandiseUsd: merchandiseUsd,
      exchangeRate: totals.exchangeRate,
      wantVerification: wantVerification,
      fees: fees,
      lines: lines,
    );

    final unavailableCount = items.length - availableItems.length;
    final availableSubtotalUsd = availableItems.fold<double>(
      0,
      (sum, e) => sum + e.displayPriceUsd,
    );
    // Prefer API subtotal when it already matches available merchandise.
    final showItemsSubtotal = totals.subtotalUsd > merchandiseUsd &&
        totals.totalDiscountUsd > 0 &&
        unavailableCount == 0;

    final gstLabel = estimate.gstRateLabel == null ||
            estimate.gstRateLabel == 'mixed'
        ? 'GST'
        : 'GST (${estimate.gstRateLabel}%)';
    final txLabel = estimate.transactionFeeRateLabel == null
        ? 'Transaction fee'
        : 'Transaction fee (${estimate.transactionFeeRateLabel}%)';

    return CartSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER SUMMARY',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          if (unavailableCount > 0) ...[
            Text(
              '$unavailableCount unavailable item${unavailableCount == 1 ? '' : 's'} excluded from total',
              style: AppTypography.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          if (showItemsSubtotal) ...[
            _usdOnlyRow('Items subtotal', totals.subtotalUsd),
            if (totals.automaticDiscountUsd > 0)
              _usdOnlyRow(
                'Automatic discount',
                -totals.automaticDiscountUsd,
              ),
            if (totals.promoDiscountUsd > 0)
              _usdOnlyRow('Promo discount', -totals.promoDiscountUsd),
            if (totals.totalDiscountUsd > 0 &&
                totals.promoDiscountUsd <= 0 &&
                totals.automaticDiscountUsd <= 0)
              _usdOnlyRow('Discount', -totals.totalDiscountUsd),
          ] else if (unavailableCount > 0 &&
              availableSubtotalUsd > merchandiseUsd) ...[
            _usdOnlyRow('Items subtotal', availableSubtotalUsd),
          ],
          _subtotalRow(estimate),
          if (wantVerification && estimate.verificationUsd > 0)
            _inrRow(
              'GemWorld verification',
              estimate.verificationInr,
              fallbackUsd: estimate.verificationUsd,
              hasRate: estimate.hasLiveRate,
            ),
          if (estimate.hasLiveRate) ...[
            if (estimate.gstInr > 0)
              _inrRow(gstLabel, estimate.gstInr, hasRate: true),
            if (estimate.transactionFeeInr > 0)
              _inrRow(txLabel, estimate.transactionFeeInr, hasRate: true),
            if (estimate.platformFeeInr > 0)
              _inrRow('Platform fee', estimate.platformFeeInr, hasRate: true),
            if (estimate.deliveryFeeInr > 0)
              _inrRow(
                'Delivery fee',
                estimate.deliveryFeeInr,
                hasRate: true,
              ),
          ],
          if (summary.appliedPromoCodes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            Wrap(
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
          ],
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    estimate.hasLiveRate
                        ? _inrLabel(estimate.totalInr)
                        : AppCurrency.usd(estimate.totalUsd),
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.bronze,
                    ),
                  ),
                  if (estimate.hasLiveRate) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${AppCurrency.usd(estimate.totalUsd)} · ${estimate.liveRateLabel}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subtotalRow(CartOrderEstimate estimate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subtotal',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                estimate.hasLiveRate
                    ? _inrLabel(estimate.merchandiseInr)
                    : AppCurrency.usd(estimate.merchandiseUsd),
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (estimate.hasLiveRate)
                Text(
                  AppCurrency.usd(estimate.merchandiseUsd),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inrRow(
    String label,
    double inrValue, {
    required bool hasRate,
    double? fallbackUsd,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            hasRate
                ? _inrLabel(inrValue)
                : AppCurrency.usd(fallbackUsd ?? 0),
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _usdOnlyRow(String label, double usdValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            AppCurrency.usd(usdValue),
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _inrLabel(double amount) =>
      '${AppCurrency.inrSymbol}${formatGroupedWhole(amount.roundToDouble())}';
}
