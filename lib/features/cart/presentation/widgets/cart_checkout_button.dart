import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../buyer/application/buyer_orders_provider.dart';
import '../../../payment/application/payment_checkout_provider.dart';
import '../../../payment/presentation/widgets/payment_success_dialog.dart';
import '../../application/cart_provider.dart';
import 'delivery_address_sheet.dart';

/// Checkout CTA — create-order → Razorpay → verify.
class CartCheckoutButton extends ConsumerWidget {
  const CartCheckoutButton({super.key});

  static const _verificationRate = 0.01;

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

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(paymentCheckoutProvider.notifier).checkout();
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
    final mutating = ref.watch(cartIsMutatingProvider);
    final checkout = ref.watch(paymentCheckoutProvider);
    final totals = ref.watch(cartTotalsProvider);
    final fxAsync = ref.watch(exchangeRateProvider);
    final busy = mutating || checkout.isBusy;

    final merchandise = totals.discountedSubtotalUsd;
    final verificationFee =
        checkout.wantGemworldVerification ? merchandise * _verificationRate : 0.0;
    final payableUsd = merchandise + verificationFee;
    final rate = fxAsync.asData?.value.rate;

    String label;
    if (!hasAddress) {
      label = 'Add delivery address';
    } else if (checkout.phase == CheckoutPhase.creatingOrder) {
      label = 'Creating order…';
    } else if (checkout.phase == CheckoutPhase.awaitingPayment) {
      label = 'Complete payment…';
    } else if (checkout.phase == CheckoutPhase.verifying) {
      label = 'Verifying payment…';
    } else {
      label = 'Proceed to payment';
    }

    final subtitleParts = <String>[];
    if (!hasAddress) {
      subtitleParts.add('Required before payment');
    } else if (!busy) {
      subtitleParts.add('\$${payableUsd.toStringAsFixed(2)}');
      if (checkout.wantGemworldVerification) {
        subtitleParts.add('+1% verification');
      }
      if (rate != null && rate > 0) {
        subtitleParts.add('1 USD = ₹${rate.toStringAsFixed(2)}');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'GemWorld verification',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Adds 1% verification commission to the total',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
            ),
          ),
          value: checkout.wantGemworldVerification,
          onChanged: busy
              ? null
              : (v) => ref
                  .read(paymentCheckoutProvider.notifier)
                  .setWantGemworldVerification(v),
          activeThumbColor: AppColors.bronze,
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
                    } else if (canCheckout) {
                      _pay(context, ref);
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
                      if (subtitleParts.isNotEmpty)
                        Text(
                          subtitleParts.join(' · '),
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
