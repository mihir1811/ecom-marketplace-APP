import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/navigator_keys.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../buyer/application/buyer_orders_provider.dart';
import '../../../payment/application/payment_checkout_provider.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../../payment/presentation/payment_flow.dart';
import '../../../payment/presentation/widgets/contact_gemworld_sheet.dart';
import '../../../payment/presentation/widgets/payment_success_dialog.dart';
import '../../../rewards/application/rewards_provider.dart';
import '../../../rewards/domain/models/rewards.dart';
import '../../../rewards/domain/reward_points_preview.dart';
import '../../../rewards/presentation/rewards_format.dart';
import '../../../wallet/application/wallet_provider.dart';
import '../../../wallet/domain/models/wallet.dart';
import '../../application/cart_provider.dart';
import '../../application/fees_providers.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/cart_order_estimate.dart';
import '../../domain/models/fee_rule.dart';
import 'cart_section_card.dart';
import 'delivery_address_sheet.dart';

/// Sticky checkout bar: payable total and the primary CTA —
/// create-order → Razorpay / wallet → verify.
class CartCheckoutBar extends ConsumerWidget {
  const CartCheckoutBar({super.key});

  Future<void> _addAddress(BuildContext context, WidgetRef ref) async {
    // Never prefills — always a blank form for a new address.
    final saved = await showDeliveryAddressSheet(context);
    if (saved == null) return;
    final result = await ref
        .read(cartProvider.notifier)
        .saveAndSelectAddress(saved);
    if (!context.mounted) return;
    if (result case ResultFailure(:final failure)) {
      showLuxeToast(context, failure.message, tone: LuxeTone.error);
    } else {
      AppHaptics.medium();
    }
  }

  Future<void> _pay(
    BuildContext context,
    WidgetRef ref, {
    required double payableInr,
    required PurchaseSummary summary,
  }) async {
    if (!AccountAccess.guard(context, ref)) return;
    final notifier = ref.read(paymentCheckoutProvider.notifier);
    final result = await PaymentFlow.run(
      context,
      summary: summary,
      process: () => notifier.checkout(payableInr: payableInr),
      status: (ref) => _phaseLabel(ref.watch(paymentCheckoutProvider)),
      showSuccess: (context, order) =>
          showPaymentSuccessDialog(context, order: order),
    );
    final overLimit =
        result is ResultFailure<PaymentOrder, Failure> &&
        PaymentCheckoutNotifier.needsContactGemworld(result.failure);
    if (overLimit) {
      if (context.mounted) await _contactGemworld(context, ref);
      return;
    }
    if (result is! Success<PaymentOrder, Failure>) return;
    // Only after the user closed the success popup.
    ref.invalidate(buyerOrdersProvider);
    final router = rootNavigatorKey.currentContext;
    if (context.mounted) {
      context.resetTo(AppRouteNames.buyerOrders);
    } else if (router != null && router.mounted) {
      router.resetTo(AppRouteNames.buyerOrders);
    }
  }

  /// Over the online-payment limit: the bag goes to GemWorld as a pending
  /// order instead of Razorpay.
  Future<void> _contactGemworld(BuildContext context, WidgetRef ref) async {
    final sent = await showContactGemworldSheet(context);
    if (sent == null || !context.mounted) return;
    await showPaymentResultDialog(
      context,
      success: true,
      title: 'Sent to GemWorld',
      message: sent,
    );
    ref.invalidate(buyerOrdersProvider);
    if (context.mounted) context.resetTo(AppRouteNames.buyerOrders);
  }

  static String _phaseLabel(CheckoutState checkout) {
    return switch (checkout.phase) {
      CheckoutPhase.awaitingPayment => 'Complete payment…',
      CheckoutPhase.verifying => _settlingLabel(checkout),
      _ => 'Creating order…',
    };
  }

  static String _settlingLabel(CheckoutState checkout) {
    if (checkout.useWallet) return 'Paying with wallet…';
    if (checkout.usePoints) return 'Paying with points…';
    return 'Verifying payment…';
  }

  static PurchaseSummary _summary({
    required int itemCount,
    required CartOrderEstimate estimate,
    required CheckoutSplitPreview split,
    required bool fullyCovered,
  }) {
    final live = estimate.hasLiveRate;
    final method = [
      if (split.usesPoints) 'Reward points',
      if (split.usesWallet) 'Wallet',
      if (!fullyCovered) 'Razorpay',
    ].join(' + ');
    return PurchaseSummary(
      item: itemCount == 1 ? '1 item' : '$itemCount items',
      method: method,
      amount: live
          ? AppCurrency.inr(estimate.totalInr)
          : AppCurrency.usd(estimate.totalUsd),
      details: [
        if (live)
          (label: 'Total (USD)', value: AppCurrency.usd(estimate.totalUsd)),
        if (live && split.usesPoints)
          (
            label: 'Reward points (${rewardPointsLabel(split.points.points)})',
            value: '−${AppCurrency.inr(split.points.amountInr)}',
          ),
        if (live && split.usesWallet)
          (label: 'From wallet', value: AppCurrency.inr(split.walletInr)),
        if (live && (split.usesPoints || split.usesWallet) && !fullyCovered)
          (label: 'Via Razorpay', value: AppCurrency.inr(split.razorpayInr)),
        if (split.earnPoints > 0)
          (
            label: split.earnBonus == null
                ? 'You\'ll earn about'
                : 'You\'ll earn (${split.earnBonus!.name} '
                      '${rewardMultiplierLabel(split.earnBonus!.earnMultiplier)})',
            value: rewardPointsLabel(split.earnPoints),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = _CheckoutModel.watch(ref);
    final p = LuxePalette.of(context);
    final checkout = m.checkout;
    final estimate = m.estimate;
    final busy = m.busy;

    String label;
    if (!m.hasAddress) {
      label = context.tr(AccountCommerceL10n.addDeliveryAddress);
    } else if (m.hasUnavailable) {
      label = context.tr(AccountCommerceL10n.removeUnavailable);
    } else if (checkout.phase == CheckoutPhase.creatingOrder) {
      label = 'Creating order…';
    } else if (checkout.phase == CheckoutPhase.awaitingPayment) {
      label = 'Complete payment…';
    } else if (checkout.phase == CheckoutPhase.verifying) {
      label = _settlingLabel(checkout);
    } else if (m.fullyCovered) {
      label = m.split.usesPoints
          ? (m.split.usesWallet
                ? 'Pay with points & wallet'
                : 'Pay with points')
          : context.tr(AccountCommerceL10n.payWallet);
    } else {
      label = context.tr(AccountCommerceL10n.continueCheckout);
    }

    String? subtitle;
    if (!m.hasAddress) {
      subtitle = 'Required before payment';
    } else if (m.hasUnavailable) {
      subtitle = 'Unavailable items are excluded from the total';
    } else if (estimate.hasLiveRate &&
        (m.split.usesPoints || m.split.usesWallet)) {
      subtitle = [
        if (m.split.usesPoints)
          'Points −${AppCurrency.inr(m.split.points.amountInr)}',
        if (m.split.usesWallet) 'Wallet ${AppCurrency.inr(m.split.walletInr)}',
        if (!m.fullyCovered) 'pay ${AppCurrency.inr(m.split.razorpayInr)}',
      ].join(' · ');
    } else if (estimate.hasLiveRate) {
      subtitle =
          '${AppCurrency.usd(estimate.totalUsd)} USD · '
          '${estimate.liveRateLabel}';
    }

    final total = estimate.hasLiveRate
        ? AppCurrency.inr(estimate.totalInr)
        : AppCurrency.usd(estimate.totalUsd);
    final blocked = !m.hasAddress || m.hasUnavailable;

    void onPressed() {
      if (!m.hasAddress) {
        _addAddress(context, ref);
      } else if (m.hasUnavailable) {
        AppHaptics.warning();
        showLuxeToast(
          context,
          'Remove unavailable items before checkout.',
          tone: LuxeTone.error,
        );
      } else if (m.canCheckout) {
        AppHaptics.medium();
        _pay(
          context,
          ref,
          payableInr: estimate.totalInr,
          summary: _summary(
            itemCount: m.items.where((e) => e.isAvailable).length,
            estimate: estimate,
            split: m.split,
            fullyCovered: m.fullyCovered,
          ),
        );
      } else {
        AppHaptics.warning();
        showLuxeToast(
          context,
          'Select a delivery address to continue.',
          tone: LuxeTone.error,
        );
      }
    }

    // Floats above the dock like the dock itself: the cart scrolls behind
    // both, frosted under the card.
    const radius = BorderRadius.all(Radius.circular(LuxeSpace.radius));
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: p.isDark ? 0.45 : 0.1),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: p.surface.withValues(alpha: p.isDark ? 0.8 : 0.86),
                borderRadius: radius,
                border: Border.all(color: p.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context
                                    .tr(ExperienceL10n.cartTotal)
                                    .toUpperCase(),
                                style: LuxeType.eyebrow(
                                  p.inkMuted,
                                ).copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 2),
                              AnimatedSwitcher(
                                duration: LuxeMotion.medium,
                                switchInCurve: LuxeMotion.settle,
                                transitionBuilder: (c, a) => FadeTransition(
                                  opacity: a,
                                  child: SlideTransition(
                                    position: Tween(
                                      begin: const Offset(0, 0.3),
                                      end: Offset.zero,
                                    ).animate(a),
                                    child: c,
                                  ),
                                ),
                                layoutBuilder: (current, previous) => Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [...previous, ?current],
                                ),
                                child: FittedBox(
                                  key: ValueKey(total),
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    total,
                                    style: LuxeType.figure(
                                      p.ink,
                                      size: 24,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 13,
                                color: p.positive,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.tr(ExperienceL10n.cartSecure),
                                style: LuxeType.label(p.inkMuted, size: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null && !busy) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuxeType.label(
                          blocked ? p.caution : p.inkFaint,
                          size: 11.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    LuxeButton(
                      label: label,
                      expand: true,
                      loading: busy,
                      icon: !m.hasAddress
                          ? Icons.add_location_alt_outlined
                          : (m.hasUnavailable
                                ? Icons.error_outline_rounded
                                : null),
                      trailingIcon: blocked
                          ? null
                          : Icons.arrow_forward_rounded,
                      onPressed: busy ? null : onPressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Verification and wallet options that shape the payable total.
class CartPaymentOptions extends ConsumerWidget {
  const CartPaymentOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = _CheckoutModel.watch(ref);
    final fees = m.fees;
    final verificationOffered = fees.offersGemworldVerification;
    final verificationOn =
        m.checkout.wantGemworldVerification && verificationOffered;

    return CartSectionCard(
      title: context.tr(ExperienceL10n.cartPaymentOptions),
      icon: Icons.tune_rounded,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (verificationOffered)
            _CheckoutToggleTile(
              title: context.tr(AccountCommerceL10n.verificationFee),
              subtitle: fees.gemworldVerificationPercent > 0
                  ? 'Adds ${_percentLabel(fees.gemworldVerificationPercent)}% '
                        'verification commission to the total'
                  : 'Adds verification commission to the total',
              value: verificationOn,
              enabled: !m.busy,
              icon: Icons.verified_outlined,
              onChanged: (v) => ref
                  .read(paymentCheckoutProvider.notifier)
                  .setWantGemworldVerification(v),
            ),
          if (m.rewards case final rewards?
              when rewards.settings.canRedeem && rewards.balance > 0)
            _PointsPayOption(
              busy: m.busy,
              rewards: rewards,
              split: m.split,
              hasLiveRate: m.estimate.hasLiveRate,
              usePoints: m.usePoints,
              onChanged: (v) =>
                  ref.read(paymentCheckoutProvider.notifier).setUsePoints(v),
            ),
          _WalletPayOption(
            busy: m.busy,
            walletAsync: m.walletAsync,
            walletBalance: m.walletBalance,
            payableInr: m.estimate.totalInr - m.split.points.amountInr,
            remainingInr: m.remainingInr,
            walletAppliedInr: m.walletAppliedInr,
            hasLiveRate: m.estimate.hasLiveRate,
            useWallet: m.useWallet,
            onChanged: (v) =>
                ref.read(paymentCheckoutProvider.notifier).setUseWallet(v),
            onRetryWallet: () => ref.read(walletProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }
}

/// Checkout inputs and the derived payable estimate, shared by the bar and
/// the payment options so both always agree.
class _CheckoutModel {
  const _CheckoutModel._({
    required this.hasAddress,
    required this.canCheckout,
    required this.hasUnavailable,
    required this.checkout,
    required this.items,
    required this.fees,
    required this.walletAsync,
    required this.walletBalance,
    required this.busy,
    required this.estimate,
    required this.useWallet,
    required this.usePoints,
    required this.rewards,
    required this.split,
    required this.walletAppliedInr,
    required this.remainingInr,
    required this.fullyCovered,
  });

  final bool hasAddress;
  final bool canCheckout;
  final bool hasUnavailable;
  final CheckoutState checkout;
  final List<CartItem> items;
  final FeeRulesCatalog fees;
  final AsyncValue<Wallet> walletAsync;
  final double walletBalance;
  final bool busy;
  final CartOrderEstimate estimate;
  final bool useWallet;
  final bool usePoints;
  final RewardsSummary? rewards;

  /// Points first, then wallet, then Razorpay, as the server applies them.
  final CheckoutSplitPreview split;
  final double walletAppliedInr;
  final double remainingInr;

  /// Points and / or wallet pay everything: no Razorpay step.
  final bool fullyCovered;

  static _CheckoutModel watch(WidgetRef ref) {
    final hasAddress = ref.watch(cartHasAddressProvider);
    final canCheckout = ref.watch(cartCanCheckoutProvider);
    final hasUnavailable = ref.watch(cartHasUnavailableItemsProvider);
    final mutating = ref.watch(cartIsMutatingProvider);
    final checkout = ref.watch(paymentCheckoutProvider);
    final totals = ref.watch(cartTotalsProvider);
    final merchandiseUsd = ref.watch(cartAvailableMerchandiseUsdProvider);
    final items = ref.watch(cartProvider.select((s) => s.items));
    final fees = ref.watch(activeFeesProvider).value ?? FeeRulesCatalog.empty;
    ref.watch(exchangeRateProvider);
    final walletAsync = ref.watch(walletProvider);
    final rewards = ref.watch(rewardsProvider).value;

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

    final walletBalance = walletAsync.value?.balance ?? 0;
    final useWallet = checkout.useWallet;
    final usePoints = checkout.usePoints && (rewards?.canSpend ?? false);
    final split = CheckoutSplitPreview.compute(
      totalInr: estimate.totalInr,
      itemsInr: estimate.merchandiseInr,
      rewards: rewards,
      usePoints: usePoints,
      walletBalance: walletBalance,
      useWallet: useWallet,
    );

    return _CheckoutModel._(
      hasAddress: hasAddress,
      canCheckout: canCheckout,
      hasUnavailable: hasUnavailable,
      checkout: checkout,
      items: items,
      fees: fees,
      walletAsync: walletAsync,
      walletBalance: walletBalance,
      busy: mutating || checkout.isBusy,
      estimate: estimate,
      useWallet: useWallet,
      usePoints: usePoints,
      rewards: rewards,
      split: split,
      walletAppliedInr: split.walletInr,
      remainingInr: split.razorpayInr,
      fullyCovered: estimate.hasLiveRate && split.fullyCovered,
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
    final p = LuxePalette.of(context);
    final titleColor = enabled ? p.ink : p.inkFaint;
    final subtitleColor = enabled ? p.inkMuted : p.inkFaint;

    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: icon == null
            ? null
            : Icon(icon, color: enabled ? p.accent : p.inkFaint, size: 22),
        title: Text(title, style: LuxeType.label(titleColor, size: 14)),
        subtitle: GestureDetector(
          onTap: onSubtitleTap,
          child: Text(
            subtitle,
            style: LuxeType.body(subtitleColor, size: 12.5),
          ),
        ),
        value: value,
        onChanged: enabled
            ? (v) {
                AppHaptics.selection();
                onChanged(v);
              }
            : null,
        activeThumbColor: p.canvas,
        activeTrackColor: p.accent,
        inactiveThumbColor: enabled ? p.inkMuted : p.inkFaint,
        inactiveTrackColor: p.surfaceRaised,
        trackOutlineColor: WidgetStatePropertyAll(p.hairline),
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
    final isLoading = walletAsync.isLoading && walletAsync.value == null;
    final hasError = walletAsync.hasError && walletAsync.value == null;
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

/// "Use reward points": shown while the programme is on and the buyer has
/// points; disabled below the spendable minimum.
class _PointsPayOption extends StatelessWidget {
  const _PointsPayOption({
    required this.busy,
    required this.rewards,
    required this.split,
    required this.hasLiveRate,
    required this.usePoints,
    required this.onChanged,
  });

  final bool busy;
  final RewardsSummary rewards;
  final CheckoutSplitPreview split;
  final bool hasLiveRate;
  final bool usePoints;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final settings = rewards.settings;
    final locked = !rewards.canSpend;
    final balance = rewardPointsLabel(rewards.balance);

    String subtitle;
    if (locked) {
      subtitle =
          'Collect at least ${rewardPointsLabel(settings.minRedeemPoints)} '
          'to use them · balance $balance';
    } else if (!hasLiveRate) {
      subtitle = 'Balance $balance · waiting for live total';
    } else if (usePoints && split.usesPoints) {
      subtitle =
          'Use ${rewardPointsLabel(split.points.points)} · '
          '−${AppCurrency.inr(split.points.amountInr)} off the total';
    } else if (usePoints) {
      subtitle = 'Balance $balance · this total is too small to use points';
    } else {
      subtitle =
          'Balance $balance (${AppCurrency.inr(rewards.balanceValueInr)}) · '
          'up to ${rewardPercentLabel(settings.maxRedeemPercent)} of the total';
    }

    return _CheckoutToggleTile(
      title: 'Use reward points',
      subtitle: subtitle,
      value: usePoints && !locked,
      enabled: !busy && !locked,
      icon: Icons.auto_awesome_outlined,
      onChanged: onChanged,
    );
  }
}
