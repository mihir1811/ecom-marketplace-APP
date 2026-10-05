import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
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

    final p = LuxePalette.of(context);
    String verificationLabel() {
      final rules = fees.ofType(FeeType.gemworldVerification);
      if (rules.isEmpty || rules.first.name.trim().isEmpty) {
        return context.tr(AccountCommerceL10n.verificationFee);
      }
      return rules.first.name;
    }

    return CartSectionCard(
      title: context.tr(AccountCommerceL10n.orderSummary),
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (unavailableCount > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: p.caution.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unavailableCount unavailable item'
                '${unavailableCount == 1 ? '' : 's'} excluded from total',
                style: LuxeType.label(p.caution, size: 12),
              ),
            ),
            const SizedBox(height: 12),
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
                positive: true,
              ),
            if (totals.promoDiscountUsd > 0)
              _usdOnlyRow(
                context,
                context.tr(AccountCommerceL10n.promoDiscount),
                -totals.promoDiscountUsd,
                positive: true,
              ),
            if (totals.totalDiscountUsd > 0 &&
                totals.promoDiscountUsd <= 0 &&
                totals.automaticDiscountUsd <= 0)
              _usdOnlyRow(
                context,
                'Discount',
                -totals.totalDiscountUsd,
                positive: true,
              ),
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
              verificationLabel(),
              estimate.verificationInr,
              fallbackUsd: estimate.verificationUsd,
              hasRate: estimate.hasLiveRate,
            ),
          if (estimate.hasLiveRate) ...[
            for (final fee in estimate.feeLines)
              _inrRow(context, _feeLabel(fee), fee.amountInr, hasRate: true),
          ] else if (feesAsync.isLoading) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LuxeSkeleton(width: 120, height: 12),
                  LuxeSkeleton(width: 64, height: 12),
                ],
              ),
            ),
          ] else if (merchandiseUsd > 0) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Fees appear once the live exchange rate loads.',
                style: LuxeType.label(p.inkFaint, size: 12),
              ),
            ),
          ],
          if (summary.appliedPromoCodes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final promo in summary.appliedPromoCodes)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: ShapeDecoration(
                      color: p.accentSoft,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      promo.code,
                      style: LuxeType.label(p.accent, size: 11.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: p.hairline),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(ExperienceL10n.cartTotal),
                style: LuxeType.display(24, p.ink),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      estimate.hasLiveRate
                          ? _inrLabel(estimate.totalInr)
                          : AppCurrency.usd(estimate.totalUsd),
                      style: LuxeType.figure(
                        p.ink,
                        size: 22,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (estimate.hasLiveRate) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${AppCurrency.usd(estimate.totalUsd)} · '
                        '${estimate.liveRateLabel}',
                        textAlign: TextAlign.end,
                        style: LuxeType.label(p.inkFaint, size: 11.5),
                      ),
                    ],
                    if (estimate.totalFromApi) ...[
                      const SizedBox(height: 2),
                      Text(
                        'From cart API',
                        style: LuxeType.label(p.inkFaint, size: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (useWallet && estimate.hasLiveRate && walletAppliedInr > 0) ...[
            const SizedBox(height: 12),
            _inrRow(
              context,
              'Wallet',
              -walletAppliedInr,
              hasRate: true,
              positive: true,
            ),
            _inrRow(
              context,
              remainingInr <= 0.009
                  ? context.tr(AccountCommerceL10n.amountToPay)
                  : context.tr(AccountCommerceL10n.payRazorpay),
              remainingInr,
              hasRate: true,
              strong: true,
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
    final p = LuxePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subtotal', style: LuxeType.body(p.inkMuted, size: 13.5)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                estimate.hasLiveRate
                    ? _inrLabel(estimate.merchandiseInr)
                    : AppCurrency.usd(estimate.merchandiseUsd),
                style: LuxeType.figure(p.ink, size: 14.5),
              ),
              if (estimate.hasLiveRate)
                Text(
                  AppCurrency.usd(estimate.merchandiseUsd),
                  style: LuxeType.label(p.inkFaint, size: 11.5),
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
    bool positive = false,
    bool strong = false,
  }) {
    final p = LuxePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: strong
                  ? LuxeType.label(p.ink, size: 13.5)
                  : LuxeType.body(p.inkMuted, size: 13.5),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            hasRate ? _inrLabel(inrValue) : AppCurrency.usd(fallbackUsd ?? 0),
            style: LuxeType.figure(positive ? p.positive : p.ink, size: 14.5),
          ),
        ],
      ),
    );
  }

  Widget _usdOnlyRow(
    BuildContext context,
    String label,
    double usdValue, {
    bool positive = false,
  }) {
    final p = LuxePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: LuxeType.body(p.inkMuted, size: 13.5)),
          ),
          Text(
            AppCurrency.usd(usdValue),
            style: LuxeType.figure(positive ? p.positive : p.ink, size: 14),
          ),
        ],
      ),
    );
  }

  String _inrLabel(double amount) =>
      '${AppCurrency.inrSymbol}${formatGroupedWhole(amount.roundToDouble())}';
}
