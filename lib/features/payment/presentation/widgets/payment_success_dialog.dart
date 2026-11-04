import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/models/payment_models.dart';
import '../payment_flow.dart';

/// Returns `true` once the user continues. Seller reviews open on the order
/// screen after delivery, not here.
Future<bool> showPaymentSuccessDialog(
  BuildContext context, {
  required PaymentOrder order,
}) async {
  AppHaptics.heavy();
  final result = await showAppDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PaymentSuccessDialog(order: order),
  );
  return result ?? true;
}

class PaymentSuccessDialog extends StatelessWidget {
  const PaymentSuccessDialog({required this.order, super.key});

  final PaymentOrder order;

  /// Closes once; repeat taps must not pop the screen underneath.
  void _close(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: maxHeight),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PaymentResultIcon(success: true),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    context.tr(AccountCommerceL10n.paymentSuccessful),
                    textAlign: TextAlign.center,
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Order ${order.id}',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _close(context),
                      child: Text(context.tr(AccountCommerceL10n.viewOrders)),
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
                onPressed: () => _close(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
