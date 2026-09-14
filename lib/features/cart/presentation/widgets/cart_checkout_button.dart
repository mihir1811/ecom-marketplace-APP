import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/error/result.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../buyer/application/buyer_orders_provider.dart';
import '../../../payment/application/payment_checkout_provider.dart';
import '../../application/fees_providers.dart';
import '../../domain/models/fee_rule.dart';
import '../../../payment/presentation/widgets/payment_success_dialog.dart';
import '../../../wallet/application/wallet_provider.dart';
import '../../../wallet/domain/models/wallet.dart';
import '../../application/cart_provider.dart';
import '../../domain/models/cart_order_estimate.dart';
import 'delivery_address_sheet.dart';

/// Checkout CTA — create-order → Razorpay / wallet → verify.
class CartCheckoutButton extends ConsumerWidget {
  const CartCheckoutButton({super.key});

  Future<void> _addAddress(BuildContext context, WidgetRef ref) async {
    // Never prefills — always a blank form for a new address.
    final saved = await showDeliveryAddressSheet(context);
    if (saved == null) return;
    final result = await ref
        .read(cartProvider.notifier)
        .saveAndSelectAddress(saved);
    if (!context.mounted) return;
    if (result case ResultFailure(:final failure)) {
      AppHaptics.error();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    } else {
      AppHaptics.medium();
    }
  }

  Future<void> _pay(
    BuildContext context,
    WidgetRef ref, {
    required double payableInr,
  }) async {
    if (!AccountAccess.guard(context, ref)) return;
    final result = await ref
        .read(paymentCheckoutProvider.notifier)
        .checkout(payableInr: payableInr);
    if (!context.mounted) return;
    switch (result) {
      case Success(:final value):
        await showPaymentSuccessDialog(context, order: value);
        if (!context.mounted) return;
        ref.invalidate(buyerOrdersProvider);
        context.resetTo(AppRouteNames.buyerOrders);
      case ResultFailure(:final failure):
        AppHaptics.error();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAddress = ref.watch(cartHasAddressProvider);
    final canCheckout = ref.watch(cartCanCheckoutProvider);
    final hasUnavailable = ref.watch(cartHasUnavailableItemsProvider);
    final mutating = ref.watch(cartIsMutatingProvider);
    final checkout = ref.watch(paymentCheckoutProvider);
    final totals = ref.watch(cartTotalsProvider);
    final merchandiseUsd = ref.watch(cartAvailableMerchandiseUsdProvider);
    final items = ref.watch(cartProvider.select((s) => s.items));
    final fees =
        ref.watch(activeFeesProvider).valueOrNull ?? FeeRulesCatalog.empty;
    ref.watch(exchangeRateProvider);
    final walletAsync = ref.watch(walletProvider);
    final busy = mutating || checkout.isBusy;

    final estimate = CartOrderEstimate.compute(
      merchandiseUsd: merchandiseUsd,
      exchangeRate: totals.exchangeRate,
      wantVerification: checkout.wantGemworldVerification,
      fees: fees,
      lines: [
        for (final item in items)
          if (item.isAvailable)
            CartLineForFees(
              productType: item.productType,
              amountUsd: item.displayPriceUsd,
            ),
      ],
    );

    final wallet = walletAsync.valueOrNull;
    final walletBalance = wallet?.balance ?? 0;
    final useWallet = checkout.useWallet;
    final walletAppliedInr = useWallet
        ? math.min(walletBalance, estimate.totalInr)
        : 0.0;
    final remainingInr = math.max(0.0, estimate.totalInr - walletAppliedInr);
    final fullyCoveredByWallet =
        useWallet && estimate.hasLiveRate && remainingInr <= 0.009;
    final verificationOffered = fees.offersGemworldVerification;
    final verificationOn =
        checkout.wantGemworldVerification && verificationOffered;

    String label;
    if (!hasAddress) {
      label = context.tr(AccountCommerceL10n.addDeliveryAddress);
    } else if (hasUnavailable) {
      label = context.tr(AccountCommerceL10n.removeUnavailable);
    } else if (checkout.phase == CheckoutPhase.creatingOrder) {
      label = 'Creating order…';
    } else if (checkout.phase == CheckoutPhase.awaitingPayment) {
      label = 'Complete payment…';
    } else if (checkout.phase == CheckoutPhase.verifying) {
      label = useWallet ? 'Paying with wallet…' : 'Verifying payment…';
    } else if (fullyCoveredByWallet) {
      label = context.tr(AccountCommerceL10n.payWallet);
    } else {
      label = context.tr(AccountCommerceL10n.continueCheckout);
    }

    String? subtitle;
    if (!hasAddress) {
      subtitle = 'Required before payment';
    } else if (hasUnavailable) {
      subtitle = 'Unavailable items are excluded from the total';
    } else if (!busy &&
        estimate.hasLiveRate &&
        useWallet &&
        walletAppliedInr > 0) {
      subtitle = fullyCoveredByWallet
          ? 'Wallet ${AppCurrency.inr(walletAppliedInr)}'
          : 'Wallet ${AppCurrency.inr(walletAppliedInr)} · pay ${AppCurrency.inr(remainingInr)}';
    } else if (!busy && estimate.hasLiveRate) {
      subtitle =
          '${AppCurrency.usd(estimate.totalUsd)} USD · ${estimate.liveRateLabel}';
    } else if (!busy) {
      subtitle = AppCurrency.usd(estimate.totalUsd);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (verificationOffered) ...[
          _CheckoutToggleTile(
            title: context.tr(AccountCommerceL10n.verificationFee),
            subtitle: fees.gemworldVerificationPercent > 0
                ? 'Adds ${_percentLabel(fees.gemworldVerificationPercent)}% verification commission to the total'
                : 'Adds verification commission to the total',
            value: verificationOn,
            enabled: !busy,
            onChanged: (v) => ref
                .read(paymentCheckoutProvider.notifier)
                .setWantGemworldVerification(v),
          ),
          const SizedBox(height: AppSpacing.s4),
        ],
        _WalletPayOption(
          busy: busy,
          walletAsync: walletAsync,
          walletBalance: walletBalance,
          payableInr: estimate.totalInr,
          remainingInr: remainingInr,
          walletAppliedInr: walletAppliedInr,
          hasLiveRate: estimate.hasLiveRate,
          useWallet: checkout.useWallet,
          onChanged: (v) =>
              ref.read(paymentCheckoutProvider.notifier).setUseWallet(v),
          onRetryWallet: () => ref.read(walletProvider.notifier).refresh(),
        ),
        const SizedBox(height: AppSpacing.s8),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.selectedFill(context),
              foregroundColor: AppColors.onSelected(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.r12),
              ),
            ),
            onPressed: busy
                ? null
                : () {
                    if (!hasAddress) {
                      _addAddress(context, ref);
                    } else if (hasUnavailable) {
                      AppHaptics.warning();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Remove unavailable items before checkout.',
                          ),
                        ),
                      );
                    } else if (canCheckout) {
                      _pay(context, ref, payableInr: estimate.totalInr);
                    } else {
                      AppHaptics.warning();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Select a delivery address to continue.',
                          ),
                        ),
                      );
                    }
                  },
            child: busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onSelected(context),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: AppTypography.label.copyWith(
                          color: AppColors.onSelected(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.onSelected(
                              context,
                            ).withValues(alpha: 0.75),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

String _percentLabel(double percent) {
  return percent == percent.roundToDouble()
      ? percent.toStringAsFixed(0)
      : percent.toStringAsFixed(2);
}

class _CheckoutToggleTile extends StatelessWidget {
  const _CheckoutToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.icon,
    this.onSubtitleTap,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final VoidCallback? onSubtitleTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = enabled
        ? AppColors.textPrimary(context)
        : AppColors.textMuted(context);
    final subtitleColor = enabled
        ? AppColors.textSecondary(context)
        : AppColors.textMuted(context);

    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: icon == null
            ? null
            : Icon(
                icon,
                color: enabled
                    ? AppColors.bronze
                    : AppColors.textMuted(context),
              ),
        title: Text(
          title,
          style: AppTypography.label.copyWith(
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        subtitle: GestureDetector(
          onTap: onSubtitleTap,
          child: Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: subtitleColor),
          ),
        ),
        value: value,
        onChanged: enabled
            ? (v) {
                AppHaptics.selection();
                onChanged(v);
              }
            : null,
        activeThumbColor: AppColors.warmWhite,
        activeTrackColor: AppColors.bronze,
        inactiveThumbColor: enabled
            ? (AppColors.isDark(context)
                  ? AppColors.textSecondaryDark
                  : AppColors.charcoalLight)
            : AppColors.textMuted(context),
        inactiveTrackColor: AppColors.border(context),
      ),
    );
  }
}

class _WalletPayOption extends StatelessWidget {
  const _WalletPayOption({
    required this.busy,
    required this.walletAsync,
    required this.walletBalance,
    required this.payableInr,
    required this.remainingInr,
    required this.walletAppliedInr,
    required this.hasLiveRate,
    required this.useWallet,
    required this.onChanged,
    required this.onRetryWallet,
  });

  final bool busy;
  final AsyncValue<Wallet> walletAsync;
  final double walletBalance;
  final double payableInr;
  final double remainingInr;
  final double walletAppliedInr;
  final bool hasLiveRate;
  final bool useWallet;
  final ValueChanged<bool> onChanged;
  final VoidCallback onRetryWallet;

  @override
  Widget build(BuildContext context) {
    final isLoading = walletAsync.isLoading && walletAsync.valueOrNull == null;
    final hasError = walletAsync.hasError && walletAsync.valueOrNull == null;
    final enabled = !busy && !isLoading && !hasError;

    String subtitle;
    if (isLoading) {
      subtitle = 'Loading wallet balance…';
    } else if (hasError) {
      subtitle = 'Could not load wallet. Tap to retry.';
    } else if (!hasLiveRate) {
      subtitle =
          'Balance ${AppCurrency.inr(walletBalance)} · waiting for live total';
    } else if (useWallet && walletAppliedInr > 0 && remainingInr > 0.009) {
      subtitle =
          'Balance ${AppCurrency.inr(walletBalance)} · apply ${AppCurrency.inr(walletAppliedInr)}, pay ${AppCurrency.inr(remainingInr)}';
    } else if (useWallet && walletAppliedInr > 0) {
      subtitle =
          'Balance ${AppCurrency.inr(walletBalance)} · covers ${AppCurrency.inr(payableInr)}';
    } else {
      subtitle = 'Balance ${AppCurrency.inr(walletBalance)}';
    }

    return _CheckoutToggleTile(
      title: context.tr(AccountCommerceL10n.payWallet),
      subtitle: subtitle,
      value: useWallet,
      enabled: enabled,
      icon: Icons.account_balance_wallet_outlined,
      onChanged: onChanged,
      onSubtitleTap: hasError && !busy ? onRetryWallet : null,
    );
  }
}
