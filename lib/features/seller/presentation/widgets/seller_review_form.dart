import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Star rating + optional comment form used after payment and on orders.
class SellerReviewForm extends StatelessWidget {
  const SellerReviewForm({
    required this.rating,
    required this.onRatingChanged,
    required this.commentController,
    this.titleController,
    this.enabled = true,
    this.compact = false,
    this.sellerName,
    super.key,
  });

  final int rating;
  final ValueChanged<int> onRatingChanged;
  final TextEditingController commentController;
  final TextEditingController? titleController;
  final bool enabled;
  final bool compact;
  final String? sellerName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sellerName != null && sellerName!.isNotEmpty) ...[
          Text(
            'Rate $sellerName',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: compact ? 8 : 12),
        ] else ...[
          Text(
            'Rate your experience',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: compact ? 8 : 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            return IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: enabled ? () => onRatingChanged(star) : null,
              icon: Icon(
                star <= rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: compact ? 28 : 34,
                color: AppColors.bronze,
              ),
            );
          }),
        ),
        if (titleController != null) ...[
          const SizedBox(height: AppSpacing.s8),
          TextField(
            controller: titleController,
            enabled: enabled,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Title (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s8),
        TextField(
          controller: commentController,
          enabled: enabled,
          minLines: compact ? 2 : 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Write a review (optional)',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
