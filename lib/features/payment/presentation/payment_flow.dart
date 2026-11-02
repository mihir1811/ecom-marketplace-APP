import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/router/navigator_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_dialog.dart';

/// What the user is about to pay for, shown in the confirmation popup.
class PurchaseSummary {
  const PurchaseSummary({
    required this.item,
    required this.amount,
    required this.method,
    this.details = const [],
  });

  final String item;
  final String amount;
  final String method;
  final List<({String label, String value})> details;
}

/// Shared purchase flow for every payment method:
/// confirm → animated progress → success / failure popup.
///
/// Returns `null` when the user cancels at confirmation (or a flow is
/// already running), otherwise the result of [process] after the final popup
/// has been closed by the user.
abstract final class PaymentFlow {
  static bool _active = false;

  /// True while a purchase is between confirmation and its final popup.
  static bool get isActive => _active;

  static Future<Result<T, Failure>?> run<T>(
    BuildContext context, {
    required PurchaseSummary summary,
    required Future<Result<T, Failure>> Function() process,
    String Function(WidgetRef ref)? status,
    Future<void> Function(BuildContext context, T value)? showSuccess,
    String? Function(T value)? successMessage,
  }) async {
    if (_active) return null;
    _active = true;
    try {
      final confirmed = await showConfirmPurchaseDialog(context, summary);
      if (!confirmed || !context.mounted) return null;

      final result = await _withProgress(context, process, status);

      // The caller may be gone (e.g. a push tap navigated away); the result
      // still has to be shown, so fall back to the root navigator.
      final host = context.mounted ? context : rootNavigatorKey.currentContext;
      if (host == null || !host.mounted) return result;
      switch (result) {
        case Success(:final value):
          if (showSuccess != null) {
            await showSuccess(host, value);
          } else {
            await showPaymentResultDialog(
              host,
              success: true,
              message: successMessage?.call(value),
            );
          }
        case ResultFailure(:final failure):
          await showPaymentResultDialog(
            host,
            success: false,
            message: failure.message,
          );
      }
      return result;
    } finally {
      _active = false;
    }
  }

  /// Runs [process] behind a progress dialog that ignores back presses and
  /// barrier taps, then closes exactly that dialog.
  static Future<Result<T, Failure>> _withProgress<T>(
    BuildContext context,
    Future<Result<T, Failure>> Function() process,
    String Function(WidgetRef ref)? status,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final theme = Theme.of(context);
    final loader = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.s8),
        child: Theme(
          data: theme,
          child: PaymentProgressDialog(status: status),
        ),
      ),
    );
    navigator.push(loader);
    try {
      return await process();
    } catch (_) {
      return Result.failure(
        const NetworkFailure('Something went wrong while processing payment.'),
      );
    } finally {
      if (loader.isActive) {
        if (loader.isCurrent) {
          navigator.pop();
        } else {
          navigator.removeRoute(loader);
        }
      }
    }
  }
}

/// Returns `true` only when the user taps confirm.
Future<bool> showConfirmPurchaseDialog(
  BuildContext context,
  PurchaseSummary summary,
) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ConfirmPurchaseDialog(summary: summary),
  );
  return confirmed ?? false;
}

/// Final payment state. Stays open until closed with the close icon,
/// the button, or the system back button.
Future<void> showPaymentResultDialog(
  BuildContext context, {
  required bool success,
  String? title,
  String? message,
}) async {
  if (success) {
    AppHaptics.heavy();
  } else {
    AppHaptics.error();
  }
  await showAppDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        PaymentResultDialog(success: success, title: title, message: message),
  );
}

/// Pops the dialog that owns [context] once, ignoring repeat taps that would
/// otherwise pop the screen underneath.
void _closeDialog<T>(BuildContext context, [T? result]) {
  final route = ModalRoute.of(context);
  if (route == null || !route.isCurrent) return;
  Navigator.of(context).pop(result);
}

class _ConfirmPurchaseDialog extends StatelessWidget {
  const _ConfirmPurchaseDialog({required this.summary});

  final PurchaseSummary summary;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Confirm purchase',
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => _closeDialog(context, false),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.s8),
                    _SummaryRow(label: 'Item', value: summary.item),
                    _SummaryRow(label: 'Payment method', value: summary.method),
                    for (final row in summary.details)
                      _SummaryRow(label: row.label, value: row.value),
                    const Divider(height: 24),
                    _SummaryRow(
                      label: 'Amount',
                      value: summary.amount,
                      emphasize: true,
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _closeDialog(context, false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.selectedFill(context),
                              foregroundColor: AppColors.onSelected(context),
                            ),
                            onPressed: () {
                              AppHaptics.medium();
                              _closeDialog(context, true);
                            },
                            icon: const Icon(Icons.lock_outline, size: 18),
                            label: const Text('Confirm'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: emphasize
                  ? AppTypography.label.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.bronze,
                    )
                  : AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated, non-dismissible loader shown while a payment is processed.
class PaymentProgressDialog extends ConsumerStatefulWidget {
  const PaymentProgressDialog({this.status, super.key});

  /// Live status line (e.g. the checkout phase); defaults to a generic one.
  final String Function(WidgetRef ref)? status;

  @override
  ConsumerState<PaymentProgressDialog> createState() =>
      _PaymentProgressDialogState();
}

class _PaymentProgressDialogState extends ConsumerState<PaymentProgressDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status?.call(ref) ?? 'Processing payment…';
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.bronze,
                        ),
                      ),
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.85, end: 1.1).animate(
                          CurvedAnimation(
                            parent: _pulse,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 34,
                          color: AppColors.bronze,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    status,
                    key: ValueKey(status),
                    textAlign: TextAlign.center,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Please don\'t close the app.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Success / failure popup with a close icon.
class PaymentResultDialog extends StatelessWidget {
  const PaymentResultDialog({
    required this.success,
    this.title,
    this.message,
    super.key,
  });

  final bool success;
  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.error;
    final text = message?.trim();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PaymentResultIcon(success: success),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    title ??
                        (success ? 'Payment successful' : 'Payment failed'),
                    textAlign: TextAlign.center,
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (text != null && text.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: success
                            ? AppColors.textSecondary(context)
                            : color,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s20),
                  SizedBox(
                    height: 48,
                    child: success
                        ? FilledButton(
                            onPressed: () => _closeDialog<void>(context),
                            child: const Text('Done'),
                          )
                        : OutlinedButton(
                            onPressed: () => _closeDialog<void>(context),
                            child: const Text('Close'),
                          ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => _closeDialog<void>(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Check / error mark that pops in when the result appears.
class PaymentResultIcon extends StatelessWidget {
  const PaymentResultIcon({required this.success, super.key});

  final bool success;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Icon(
        success ? Icons.check_circle_rounded : Icons.error_rounded,
        size: 64,
        color: success ? AppColors.success : AppColors.error,
      ),
    );
  }
}
