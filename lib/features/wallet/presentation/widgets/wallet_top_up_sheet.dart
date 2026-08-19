import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/wallet_top_up_provider.dart';

const _presets = <double>[500, 1000, 2000, 5000];

/// Amount form that starts Razorpay wallet top-up.
class WalletTopUpSheet extends ConsumerStatefulWidget {
  const WalletTopUpSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.r32),
        ),
      ),
      builder: (context) => const WalletTopUpSheet(),
    );
  }

  @override
  ConsumerState<WalletTopUpSheet> createState() => _WalletTopUpSheetState();
}

class _WalletTopUpSheetState extends ConsumerState<WalletTopUpSheet> {
  final _controller = TextEditingController();
  String? _fieldError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _parsedAmount {
    final raw = _controller.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final amount = _parsedAmount;
    if (amount == null) {
      setState(() => _fieldError = 'Enter an amount in INR.');
      return;
    }
    final invalid =
        ref.read(walletTopUpProvider.notifier).validateAmount(amount);
    if (invalid != null) {
      setState(() => _fieldError = invalid.message);
      return;
    }
    setState(() => _fieldError = null);

    final result = await ref.read(walletTopUpProvider.notifier).topUp(amount);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success():
        Navigator.of(context).maybePop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Wallet topped up successfully')),
        );
      case ResultFailure(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topUp = ref.watch(walletTopUpProvider);
    final busy = topUp.isBusy;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s24,
        AppSpacing.s16,
        AppSpacing.s24,
        AppSpacing.s24 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(AppSpacing.circular),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Top up wallet',
            style: AppTypography.title.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Amount is in INR. Minimum ₹1.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted(context),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          TextField(
            controller: _controller,
            enabled: !busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) {
              if (_fieldError != null) setState(() => _fieldError = null);
            },
            onSubmitted: (_) => busy ? null : _submit(),
            decoration: InputDecoration(
              labelText: 'Amount (INR)',
              prefixText: '₹ ',
              errorText: _fieldError,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final preset in _presets)
                ActionChip(
                  label: Text('₹${preset.toStringAsFixed(0)}'),
                  onPressed: busy
                      ? null
                      : () {
                          _controller.text = preset.toStringAsFixed(0);
                          setState(() => _fieldError = null);
                        },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue to payment'),
          ),
        ],
      ),
    );
  }
}
