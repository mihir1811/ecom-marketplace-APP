import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../../seller/application/seller_reviews_provider.dart';
import '../../../seller/domain/models/seller_review.dart';
import '../../../seller/presentation/widgets/seller_review_form.dart';

/// Public seller ratings + optional write form after payment.
class OrderReviewSection extends ConsumerStatefulWidget {
  const OrderReviewSection({required this.order, super.key});

  final PaymentOrder order;

  @override
  ConsumerState<OrderReviewSection> createState() => _OrderReviewSectionState();
}

class _OrderReviewSectionState extends ConsumerState<OrderReviewSection> {
  late final TextEditingController _commentController;
  late final TextEditingController _titleController;
  int _rating = 0;
  bool _submitting = false;
  String? _error;
  bool _submittedLocally = false;

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

  bool get _isPaid => widget.order.status.toUpperCase() == 'PAID';

  Future<void> _submit() async {
    final sellerId = _sellerId;
    if (sellerId == null || _rating < 1) {
      setState(() => _error = 'Please select a star rating.');
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
        setState(() {
          _submitting = false;
          _submittedLocally = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for your review!')),
        );
      case ResultFailure(:final failure):
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerId = _sellerId;
    final publicAsync = sellerId == null
        ? const AsyncValue<List<SellerReview>>.data([])
        : ref.watch(publicSellerReviewsProvider(sellerId));
    final orderAsync = ref.watch(orderSellerReviewsProvider(widget.order.id));

    final publicReviews = publicAsync.asData?.value ?? const <SellerReview>[];
    final orderReviews = orderAsync.asData?.value ?? const <SellerReview>[];
    final alreadyReviewedThisOrder =
        _submittedLocally || orderReviews.isNotEmpty;
    final canForm =
        _isPaid &&
        sellerId != null &&
        !alreadyReviewedThisOrder &&
        !orderAsync.isLoading;
    final isLoading = publicAsync.isLoading || orderAsync.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Seller Rating & review',
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Public ratings for $_sellerName',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted(context),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (publicAsync.hasError)
          Text(
            publicAsync.error is Failure
                ? (publicAsync.error! as Failure).message
                : 'Could not load reviews.',
            style: AppTypography.caption.copyWith(color: AppColors.error),
          )
        else if (publicReviews.isEmpty)
          Text(
            'No reviews yet for this seller.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted(context),
            ),
          )
        else
          Column(
            children: [
              for (final review in publicReviews)
                _ExistingReviewCard(review: review),
            ],
          ),
        if (!_isPaid && sellerId != null) ...[
          const SizedBox(height: 8),
          Text(
            'You can leave a review after payment is complete.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted(context),
            ),
          ),
        ],
        if (canForm) ...[
          const SizedBox(height: 8),
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
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
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
                  : const Text('Submit review'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ExistingReviewCard extends StatelessWidget {
  const _ExistingReviewCard({required this.review});

  final SellerReview review;

  @override
  Widget build(BuildContext context) {
    final date = review.createdAt;
    final dateLabel = date == null
        ? null
        : '${date.day}/${date.month}/${date.year}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.sellerName ?? 'Seller',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (dateLabel != null)
                Text(
                  dateLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 18,
                color: AppColors.bronze,
              );
            }),
          ),
          if (review.title != null && review.title!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.title!,
              style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.comment!,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary(context),
                height: 1.4,
              ),
            ),
          ],
          if (review.sellerReply != null && review.sellerReply!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Seller reply: ${review.sellerReply}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
