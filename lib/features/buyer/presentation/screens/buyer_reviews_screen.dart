import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/buyer_layout.dart';

class BuyerReviewsScreen extends StatelessWidget {
  const BuyerReviewsScreen({super.key});

  static const _reviews = <_ReviewItem>[
    _ReviewItem(
      product: '0.71ct Oval F VVS2',
      rating: 5,
      body: 'Excellent stone quality and fast shipping.',
      dateLabel: '12 Jul 2026',
    ),
    _ReviewItem(
      product: 'Emerald Cut Sapphire',
      rating: 4,
      body: 'Color matches description. Packaging was secure.',
      dateLabel: '03 Jul 2026',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BuyerLayout(
      title: 'My Reviews',
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.s16),
        itemCount: _reviews.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (context, index) {
          final review = _reviews[index];
          return Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warmBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.product,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      review.dateLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
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
                const SizedBox(height: AppSpacing.s8),
                Text(
                  review.body,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReviewItem {
  const _ReviewItem({
    required this.product,
    required this.rating,
    required this.body,
    required this.dateLabel,
  });

  final String product;
  final int rating;
  final String body;
  final String dateLabel;
}
