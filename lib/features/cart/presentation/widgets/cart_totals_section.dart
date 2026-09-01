import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../payment/application/payment_checkout_provider.dart';
import '../../../wallet/application/wallet_provider.dart';
import '../../application/cart_provider.dart';
import '../../application/fees_providers.dart';
import '../../domain/models/cart_order_estimate.dart';
import '../../domain/models/fee_rule.dart';
import 'cart_section_card.dart';

/// Order summary card — merchandise from cart summary, fees from `GET /fees`.
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
    final feesAsync = ref.watch(activeFeesProvider);
    final fees = feesAsync.valueOrNull ?? FeeRulesCatalog.empty;
    final wantVerification = ref.watch(
      paymentCheckoutProvider.select((s) => s.wantGemworldVerification),
    );
    final useWallet = ref.watch(
      paymentCheckoutProvider.select((s) => s.useWallet),
    );
    final walletBalance = ref.watch(walletProvider).valueOrNull?.balance ?? 0;

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
      wantVerification: wantVerification && fees.offersGemworldVerification,
      fees: fees,
      lines: lines,
      apiTotalInr: summary.totalInr,
      apiTotalUsd: summary.totalUsd,
    );

    final walletAppliedInr = useWallet
        ? math.min(walletBalance, estimate.totalInr)
        : 0.0;
    final remainingInr = math.max(0.0, estimate.totalInr - walletAppliedInr);

    final unavailableCount = items.length - availableItems.length;
    final availableSubtotalUsd = availableItems.fold<double>(
      0,
      (sum, e) => sum + e.displayPriceUsd,
    );
    // Prefer API subtotal when it already matches available merchandise.
    final showItemsSubtotal =
        totals.subtotalUsd > merchandiseUsd &&
        totals.totalDiscountUsd > 0 &&
        unavailableCount == 0;

    return CartSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(AccountCommerceL10n.orderSummary),
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted(context),
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
            _usdOnlyRow(
              context,
              context.tr(AccountCommerceL10n.itemsSubtotal),
              totals.subtotalUsd,
            ),
            if (totals.automaticDiscountUsd > 0)
              _usdOnlyRow(
                context,
                context.tr(AccountCommerceL10n.automaticDiscount),
                -totals.automaticDiscountUsd,
              ),
            if (totals.promoDiscountUsd > 0)
              _usdOnlyRow(
                context,
                context.tr(AccountCommerceL10n.promoDiscount),
                -totals.promoDiscountUsd,
              ),
            if (totals.totalDiscountUsd > 0 &&
                totals.promoDiscountUsd <= 0 &&
                totals.automaticDiscountUsd <= 0)
              _usdOnlyRow(context, 'Discount', -totals.totalDiscountUsd),
          ] else if (unavailableCount > 0 &&
              availableSubtotalUsd > merchandiseUsd) ...[
            _usdOnlyRow(
              context,
              context.tr(AccountCommerceL10n.itemsSubtotal),
              availableSubtotalUsd,
            ),
          ],
          _subtotalRow(context, estimate),
          if (wantVerification && estimate.verificationUsd > 0)
            _inrRow(
              context,
              fees.ofType(FeeType.gemworldVerification).isNotEmpty
                  ? (fees
                            .ofType(FeeType.gemworldVerification)
                            .first
                            .name
                            .trim()
                            .isEmpty
                        ? context.tr(AccountCommerceL10n.verificationFee)
                        : fees.ofType(FeeType.gemworldVerification).first.name)
                  : context.tr(AccountCommerceL10n.verificationFee),
              estimate.verificationInr,
              fallbackUsd: estimate.verificationUsd,
              hasRate: estimate.hasLiveRate,
            ),
          if (estimate.hasLiveRate) ...[
            for (final fee in estimate.feeLines)
              _inrRow(context, _feeLabel(fee), fee.amountInr, hasRate: true),
          ] else if (feesAsync.isLoading) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: Text(
                'Loading fees…',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                ),
              ),
            ),
          ] else if (merchandiseUsd > 0) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: Text(
                'Fees appear once the live exchange rate loads.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                ),
              ),
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
                    backgroundColor: AppColors.surface(context),
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
                        color: AppColors.textMuted(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (estimate.totalFromApi) ...[
                    const SizedBox(height: 2),
                    Text(
                      'From cart API',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (useWallet && estimate.hasLiveRate && walletAppliedInr > 0) ...[
            const SizedBox(height: AppSpacing.s12),
            _inrRow(context, 'Wallet', -walletAppliedInr, hasRate: true),
            _inrRow(
              context,
              remainingInr <= 0.009
                  ? context.tr(AccountCommerceL10n.amountToPay)
                  : context.tr(AccountCommerceL10n.payRazorpay),
              remainingInr,
              hasRate: true,
            ),
          ],
        ],
      ),
    );
  }

  String _feeLabel(CartFeeLine fee) {
    final rate = fee.rateLabel;
    if (rate == null || rate.isEmpty) return fee.label;
    if (fee.label.contains('%')) return fee.label;
    return '${fee.label} ($rate%)';
  }

  Widget _subtotalRow(BuildContext context, CartOrderEstimate estimate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subtotal',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary(context),
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
                    color: AppColors.textMuted(context),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inrRow(
    BuildContext context,
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
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          Text(
            hasRate ? _inrLabel(inrValue) : AppCurrency.usd(fallbackUsd ?? 0),
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _usdOnlyRow(BuildContext context, String label, double usdValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          Text(
            AppCurrency.usd(usdValue),
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _inrLabel(double amount) =>
      '${AppCurrency.inrSymbol}${formatGroupedWhole(amount.roundToDouble())}';
}
