import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/models/payment_models.dart';
import '../../../seller/application/seller_reviews_provider.dart';
import '../../../seller/domain/models/seller_review.dart';
import '../../../seller/presentation/widgets/seller_review_form.dart';

/// Returns `true` if the user chose to continue (submit or skip).
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

class PaymentSuccessDialog extends ConsumerStatefulWidget {
  const PaymentSuccessDialog({required this.order, super.key});

  final PaymentOrder order;

  @override
  ConsumerState<PaymentSuccessDialog> createState() =>
      _PaymentSuccessDialogState();
}

class _PaymentSuccessDialogState extends ConsumerState<PaymentSuccessDialog> {
  late final TextEditingController _commentController;
  late final TextEditingController _titleController;
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String? get _sellerId {
    if (widget.order.sellers.isNotEmpty) return widget.order.sellers.first.id;
    for (final item in widget.order.items) {
      if (item.sellerId != null && item.sellerId!.isNotEmpty) {
        return item.sellerId;
      }
    }
    return null;
  }

  String get _sellerName {
    if (widget.order.sellers.isNotEmpty) {
      return widget.order.sellers.first.companyName;
    }
    return widget.order.primarySellerName;
  }

  bool get _canReview {
    final paid = widget.order.status.toUpperCase() == 'PAID';
    return paid && _sellerId != null && _sellerId!.isNotEmpty;
  }

  Future<void> _submit() async {
    final sellerId = _sellerId;
    if (sellerId == null || _rating < 1) {
      AppHaptics.error();
      setState(() => _error = context.tr(AccountCommerceL10n.selectStar));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await submitSellerReview(
      ref,
      SubmitSellerReviewInput(
        sellerId: sellerId,
        orderId: widget.order.id,
        rating: _rating,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      ),
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        AppHaptics.success();
        Navigator.of(context).pop(true);
      case ResultFailure(:final failure):
        AppHaptics.error();
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                context.tr(AccountCommerceL10n.paymentSuccessful),
                textAlign: TextAlign.center,
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Order ${widget.order.id}',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMutedLight,
                ),
              ),
              if (_canReview) ...[
                const SizedBox(height: AppSpacing.s20),
                SellerReviewForm(
                  rating: _rating,
                  onRatingChanged: (v) => setState(() {
                    _rating = v;
                    _error = null;
                  }),
                  commentController: _commentController,
                  titleController: _titleController,
                  enabled: !_submitting,
                  compact: true,
                  sellerName: _sellerName,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.s20),
              if (_canReview)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.charcoal,
                      foregroundColor: AppColors.warmWhite,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.warmWhite,
                            ),
                          )
                        : Text(context.tr(AccountCommerceL10n.submitReview)),
                  ),
                ),
              if (_canReview) const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(true),
                  child: Text(
                    _canReview
                        ? context.tr(AccountCommerceL10n.skipViewOrders)
                        : context.tr(AccountCommerceL10n.viewOrders),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
