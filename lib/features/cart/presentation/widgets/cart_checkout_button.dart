import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
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
    final result =
        await ref.read(cartProvider.notifier).saveAndSelectAddress(saved);
    if (!context.mounted) return;
    if (result case ResultFailure(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }
  }

  Future<void> _pay(
    BuildContext context,
    WidgetRef ref, {
    required double payableInr,
  }) async {
    final result = await ref
        .read(paymentCheckoutProvider.notifier)
        .checkout(payableInr: payableInr);
    if (!context.mounted) return;
    switch (result) {
      case Success(:final value):
        await showPaymentSuccessDialog(context, order: value);
        if (!context.mounted) return;
        ref.invalidate(buyerOrdersProvider);
        context.go(AppRouteNames.buyerOrders);
      case ResultFailure(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
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
    final canPayWithWallet =
        estimate.hasLiveRate && walletBalance + 0.009 >= estimate.totalInr;
    final useWallet = checkout.useWallet && canPayWithWallet;
    final verificationOn = checkout.wantGemworldVerification;

    String label;
    if (!hasAddress) {
      label = 'Add delivery address';
    } else if (hasUnavailable) {
      label = 'Remove unavailable items';
    } else if (checkout.phase == CheckoutPhase.creatingOrder) {
      label = 'Creating order…';
    } else if (checkout.phase == CheckoutPhase.awaitingPayment) {
      label = 'Complete payment…';
    } else if (checkout.phase == CheckoutPhase.verifying) {
      label = useWallet ? 'Paying with wallet…' : 'Verifying payment…';
    } else if (useWallet) {
      label = 'Pay with wallet';
    } else {
      label = 'Continue to checkout';
    }

    String? subtitle;
    if (!hasAddress) {
      subtitle = 'Required before payment';
    } else if (hasUnavailable) {
      subtitle = 'Unavailable items are excluded from the total';
    } else if (!busy && estimate.hasLiveRate) {
      subtitle =
          '${AppCurrency.usd(estimate.totalUsd)} USD · ${estimate.liveRateLabel}';
    } else if (!busy) {
      subtitle = AppCurrency.usd(estimate.totalUsd);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.warmWhite,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'GemWorld verification',
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
            subtitle: Text(
              'Adds 1% verification commission to the total',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            value: verificationOn,
            onChanged: busy
                ? null
                : (v) => ref
                    .read(paymentCheckoutProvider.notifier)
                    .setWantGemworldVerification(v),
            activeThumbColor: AppColors.warmWhite,
            activeTrackColor: AppColors.bronze,
            inactiveThumbColor: AppColors.charcoalLight,
            inactiveTrackColor: AppColors.warmBorder,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        _WalletPayOption(
          busy: busy,
          walletAsync: walletAsync,
          walletBalance: walletBalance,
          payableInr: estimate.totalInr,
          hasLiveRate: estimate.hasLiveRate,
          canPayWithWallet: canPayWithWallet,
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
              backgroundColor: AppColors.charcoal,
              foregroundColor: AppColors.warmWhite,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Remove unavailable items before checkout.',
                          ),
                        ),
                      );
                    } else if (canCheckout) {
                      if (checkout.useWallet && !canPayWithWallet) {
                        ref
                            .read(paymentCheckoutProvider.notifier)
                            .setUseWallet(false);
                      }
                      _pay(
                        context,
                        ref,
                        payableInr: estimate.totalInr,
                      );
                    } else {
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
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.warmWhite,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: AppTypography.label.copyWith(
                          color: AppColors.warmWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warmWhite.withValues(alpha: 0.75),
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

class _WalletPayOption extends StatelessWidget {
  const _WalletPayOption({
    required this.busy,
    required this.walletAsync,
    required this.walletBalance,
    required this.payableInr,
    required this.hasLiveRate,
    required this.canPayWithWallet,
    required this.useWallet,
    required this.onChanged,
    required this.onRetryWallet,
  });

  final bool busy;
  final AsyncValue<Wallet> walletAsync;
  final double walletBalance;
  final double payableInr;
  final bool hasLiveRate;
  final bool canPayWithWallet;
  final bool useWallet;
  final ValueChanged<bool> onChanged;
  final VoidCallback onRetryWallet;

  @override
  Widget build(BuildContext context) {
    final isLoading = walletAsync.isLoading && walletAsync.valueOrNull == null;
    final hasError = walletAsync.hasError && walletAsync.valueOrNull == null;
    final enabled = !busy && canPayWithWallet;
    final switchedOn = useWallet && canPayWithWallet;

    String subtitle;
    if (isLoading) {
      subtitle = 'Loading wallet balance…';
    } else if (hasError) {
      subtitle = 'Could not load wallet. Tap to retry.';
    } else if (!hasLiveRate) {
      subtitle =
          'Balance ${AppCurrency.inr(walletBalance)} · waiting for live total';
    } else if (canPayWithWallet) {
      subtitle =
          'Balance ${AppCurrency.inr(walletBalance)} · covers ${AppCurrency.inr(payableInr)}';
    } else {
      subtitle =
          'Balance ${AppCurrency.inr(walletBalance)} · need ${AppCurrency.inr(payableInr)}';
    }

    final titleColor =
        enabled ? AppColors.textPrimaryLight : AppColors.textMutedLight;
    final subtitleColor =
        enabled ? AppColors.textSecondaryLight : AppColors.textMutedLight;

    return Material(
      color: AppColors.warmWhite,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(
          Icons.account_balance_wallet_outlined,
          color: enabled ? AppColors.bronze : AppColors.textMutedLight,
        ),
        title: Text(
          'Pay with wallet',
          style: AppTypography.label.copyWith(
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        subtitle: GestureDetector(
          onTap: hasError && !busy ? onRetryWallet : null,
          child: Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: subtitleColor),
          ),
        ),
        value: switchedOn,
        onChanged: enabled ? onChanged : null,
        activeThumbColor: AppColors.warmWhite,
        activeTrackColor: AppColors.bronze,
        inactiveThumbColor:
            enabled ? AppColors.charcoalLight : AppColors.textMutedLight,
        inactiveTrackColor: enabled
            ? AppColors.warmBorder
            : AppColors.sandSurface,
      ),
    );
  }
}
