import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/result.dart';
import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../buyer/presentation/maison/maison_kit.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../application/wallet_provider.dart';
import '../../../application/wallet_top_up_provider.dart';

const _presets = <double>[500, 1000, 2500, 5000, 10000];

/// Buyer "Add funds" sheet: one large amount, presets, a live preview of
/// the new balance and the Razorpay phases while the payment runs.
class WalletTopUpSheet extends ConsumerStatefulWidget {
  const WalletTopUpSheet({super.key, this.initialAmount});

  /// Prefilled amount in rupees, e.g. a live bid's shortfall.
  final double? initialAmount;

  static Future<void> show(BuildContext context, {double? initialAmount}) {
    return showAtelierSheet<void>(
      context: context,
      title: 'Add funds',
      subtitle: context.tr(RemainingL10n.topUpMinimum),
      builder: (_) => WalletTopUpSheet(initialAmount: initialAmount),
    );
  }

  @override
  ConsumerState<WalletTopUpSheet> createState() => _WalletTopUpSheetState();
}

class _WalletTopUpSheetState extends ConsumerState<WalletTopUpSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAmount;
    if (initial != null && initial > 0) {
      _controller.text = initial.ceil().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _amount {
    final raw = _controller.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  void _setPreset(double value) {
    AppHaptics.selection();
    _controller.text = value.toStringAsFixed(0);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    setState(() => _error = null);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final amount = _amount;
    if (amount == null) {
      AppHaptics.error();
      setState(() => _error = context.tr(RemainingL10n.enterAmountInr));
      return;
    }
    final invalid = ref
        .read(walletTopUpProvider.notifier)
        .validateAmount(amount);
    if (invalid != null) {
      AppHaptics.error();
      setState(() => _error = invalid.message);
      return;
    }
    setState(() => _error = null);

    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final successText = context.tr(RemainingL10n.walletTopUpSuccess);
    final result = await ref.read(walletTopUpProvider.notifier).topUp(amount);
    if (!mounted) return;
    switch (result) {
      case Success():
        AppHaptics.success();
        Navigator.of(context).maybePop();
        showMaisonToast(
          messenger,
          palette,
          successText,
          tone: AtelierTone.emerald,
          icon: Icons.account_balance_wallet_rounded,
        );
      case ResultFailure(:final failure):
        AppHaptics.error();
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final topUp = ref.watch(walletTopUpProvider);
    final busy = topUp.isBusy;
    final balance = ref.watch(walletProvider).asData?.value.balance;
    final amount = _amount ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: AtelierMotion.base,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(
            color: p.sunken,
            borderRadius: BorderRadius.circular(AtelierRadius.lg),
            border: Border.all(
              color: _error != null
                  ? p.ruby.withValues(alpha: 0.6)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(RemainingL10n.amountInr).toUpperCase(),
                style: AtelierType.overline(p.muted),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('₹', style: AtelierType.display(p.gold, size: 44)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !busy,
                      autofocus: true,
                      cursorColor: p.gold,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      onChanged: (_) => setState(() => _error = null),
                      onSubmitted: (_) => busy ? null : _submit(),
                      style: AtelierType.display(p.ink, size: 44),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: '0',
                        hintStyle: AtelierType.display(p.muted, size: 44),
                        semanticCounterText: context.tr(
                          RemainingL10n.amountInr,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (balance != null) ...[
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: AtelierMotion.base,
                  child: Row(
                    key: ValueKey(amount > 0),
                    children: [
                      Icon(
                        amount > 0
                            ? Icons.trending_up_rounded
                            : Icons.account_balance_wallet_outlined,
                        size: 14,
                        color: amount > 0 ? p.emerald : p.muted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          amount > 0
                              ? 'New balance ${maisonInr(balance + amount)}'
                              : 'Current balance ${maisonInr(balance)}',
                          style: AtelierType.caption(
                            amount > 0 ? p.emerald : p.muted,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        AtelierFieldError(error: _error),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _presets)
              AtelierChoiceChip(
                label: maisonInr(preset).replaceAll('.00', ''),
                selected: _amount == preset,
                onTap: busy ? () {} : () => _setPreset(preset),
              ),
          ],
        ),
        AnimatedSize(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          child: busy
              ? Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: _Phases(phase: topUp.phase),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 22),
        AtelierButton(
          label: amount > 0
              ? 'Add ${maisonInr(amount).replaceAll('.00', '')}'
              : context.tr(RemainingL10n.continuePayment),
          icon: Icons.lock_outline_rounded,
          variant: AtelierButtonVariant.gold,
          loading: busy,
          expand: true,
          onPressed: busy ? null : _submit,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 13, color: p.muted),
            const SizedBox(width: 6),
            Text(
              'Secured by Razorpay · Funds arrive instantly',
              style: AtelierType.caption(p.muted, size: 11.5),
            ),
          ],
        ),
      ],
    );
  }
}

class _Phases extends StatelessWidget {
  const _Phases({required this.phase});

  final WalletTopUpPhase phase;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    const steps = [
      (WalletTopUpPhase.creating, 'Preparing'),
      (WalletTopUpPhase.awaitingPayment, 'Payment'),
      (WalletTopUpPhase.verifying, 'Verifying'),
    ];
    final current = steps.indexWhere((s) => s.$1 == phase);
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: AnimatedContainer(
                  duration: AtelierMotion.slow,
                  height: 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: i <= current ? p.gold : p.hairline,
                ),
              ),
            ),
          Column(
            children: [
              AnimatedContainer(
                duration: AtelierMotion.slow,
                curve: AtelierMotion.settle,
                width: i == current ? 26 : 20,
                height: i == current ? 26 : 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < current
                      ? p.gold
                      : i == current
                      ? p.goldSoft
                      : p.sunken,
                  border: Border.all(color: i <= current ? p.gold : p.hairline),
                ),
                child: i < current
                    ? Icon(Icons.check_rounded, size: 13, color: p.onGold)
                    : i == current
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: p.gold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                steps[i].$2,
                style: AtelierType.caption(
                  i <= current ? p.ink : p.muted,
                  size: 11,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
