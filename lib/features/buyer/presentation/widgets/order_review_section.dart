import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../../seller/application/seller_reviews_provider.dart';
import '../../../seller/domain/models/seller_review.dart';
import '../../../seller/presentation/widgets/seller_review_form.dart';

/// Public seller ratings + write forms after payment (one per unreviewed seller).
class OrderReviewSection extends ConsumerStatefulWidget {
  const OrderReviewSection({required this.order, super.key});

  final PaymentOrder order;

  @override
  ConsumerState<OrderReviewSection> createState() => _OrderReviewSectionState();
}

class _OrderReviewSectionState extends ConsumerState<OrderReviewSection> {
  /// Sellers already submitted in this session (before provider refresh lands).
  final Set<String> _submittedLocally = {};

  bool get _isPaid => widget.order.status.toUpperCase() == 'PAID';

  List<({String sellerId, String sellerName})> get _sellerTargets {
    final seen = <String>{};
    final targets = <({String sellerId, String sellerName})>[];
    for (final seller in widget.order.sellers) {
      if (seller.id.isEmpty || !seen.add(seller.id)) continue;
      targets.add((sellerId: seller.id, sellerName: seller.companyName));
    }
    for (final item in widget.order.items) {
      final id = item.sellerId;
      if (id == null || id.isEmpty || !seen.add(id)) continue;
      targets.add((
        sellerId: id,
        sellerName: item.sellerName?.trim().isNotEmpty == true
            ? item.sellerName!
            : 'Seller',
      ));
    }
    return targets;
  }

  @override
  Widget build(BuildContext context) {
    final targets = _sellerTargets;
    final orderAsync = ref.watch(orderSellerReviewsProvider(widget.order.id));
    final orderReviews = orderAsync.asData?.value ?? <SellerReview>[];
    final reviewedSellerIds = <String>{
      ...orderReviews.map((r) => r.sellerId),
      ..._submittedLocally,
    };
    final pendingTargets = targets
        .where((t) => !reviewedSellerIds.contains(t.sellerId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(AccountCommerceL10n.sellerRatingReview),
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          targets.isEmpty
              ? 'Rate sellers from this order after payment.'
              : 'Leave a review for each seller on this order.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted(context),
          ),
        ),
        const SizedBox(height: 12),
        if (orderAsync.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (orderAsync.hasError)
          Text(
            orderAsync.error is Failure
                ? (orderAsync.error! as Failure).message
                : context.tr(AccountCommerceL10n.reviewsLoadFailed),
            style: AppTypography.caption.copyWith(color: AppColors.error),
          )
        else ...[
          if (orderReviews.isNotEmpty) ...[
            for (final review in orderReviews)
              _ExistingReviewCard(review: review),
            const SizedBox(height: 4),
          ],
          if (!_isPaid && targets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'You can leave a review after payment is complete.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
              ),
            ),
          ],
          if (_isPaid && pendingTargets.isEmpty && targets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'You have reviewed every seller on this order.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
              ),
            ),
          ],
          if (_isPaid)
            for (final target in pendingTargets) ...[
              const SizedBox(height: 12),
              _SellerReviewFormBlock(
                key: ValueKey('review-form-${target.sellerId}'),
                orderId: widget.order.id,
                sellerId: target.sellerId,
                sellerName: target.sellerName,
                onSubmitted: () {
                  setState(() => _submittedLocally.add(target.sellerId));
                },
              ),
            ],
        ],
      ],
    );
  }
}

class _SellerReviewFormBlock extends ConsumerStatefulWidget {
  const _SellerReviewFormBlock({
    required this.orderId,
    required this.sellerId,
    required this.sellerName,
    required this.onSubmitted,
    super.key,
  });

  final String orderId;
  final String sellerId;
  final String sellerName;
  final VoidCallback onSubmitted;

  @override
  ConsumerState<_SellerReviewFormBlock> createState() =>
      _SellerReviewFormBlockState();
}

class _SellerReviewFormBlockState
    extends ConsumerState<_SellerReviewFormBlock> {
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

  Future<void> _submit() async {
    if (_rating < 1) {
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
        sellerId: widget.sellerId,
        orderId: widget.orderId,
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
        setState(() => _submitting = false);
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(AccountCommerceL10n.thanksReview, {
                'seller': widget.sellerName,
              }),
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          sellerName: widget.sellerName,
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
                : Text(
                    context.tr(AccountCommerceL10n.submitReviewFor, {
                      'seller': widget.sellerName,
                    }),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ExistingReviewCard extends ConsumerWidget {
  const _ExistingReviewCard({required this.review});

  final SellerReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId =
        ref.watch(authProvider.select((s) => s.user?.id)) ?? '';
    final isMine = currentUserId.isNotEmpty && review.userId == currentUserId;
    final buyerLabel = isMine
        ? 'me'
        : (review.userName?.trim().isNotEmpty == true
              ? review.userName!.trim()
              : 'Buyer');

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
                  buyerLabel,
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
          if (review.sellerName != null &&
              review.sellerName!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Seller: ${review.sellerName}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
              ),
            ),
          ],
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
