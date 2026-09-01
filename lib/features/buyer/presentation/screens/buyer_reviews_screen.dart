import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../seller/application/seller_reviews_provider.dart';
import '../../../seller/domain/models/seller_review.dart';
import '../widgets/buyer_layout.dart';

class BuyerReviewsScreen extends ConsumerWidget {
  const BuyerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mySellerReviewsProvider);

    return BuyerLayout(
      title: context.tr(AccountCommerceL10n.myReviews),
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(mySellerReviewsProvider),
        child: async.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.s24),
            children: [
              Text(
                e is Failure
                    ? e.message
                    : context.tr(AccountCommerceL10n.reviewsLoadFailed),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s16),
              Center(
                child: FilledButton(
                  onPressed: () => ref.invalidate(mySellerReviewsProvider),
                  child: Text(context.tr(AccountCommerceL10n.retry)),
                ),
              ),
            ],
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      context.tr(AccountCommerceL10n.noReviews),
                      style: AppTypography.body,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          context.openRoute(AppRouteNames.buyerOrders),
                      child: Text(context.tr(AccountCommerceL10n.viewOrders)),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemCount: reviews.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) {
                return _ReviewCard(review: reviews[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final SellerReview review;

  @override
  Widget build(BuildContext context) {
    final date = review.createdAt;
    final dateLabel = date == null
        ? null
        : '${date.day}/${date.month}/${date.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.openRoute(
          AppRouteNames.buyerOrderDetailPath(review.orderId),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review.sellerName ?? 'Seller',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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
              const SizedBox(height: 4),
              Text(
                context.tr(AccountCommerceL10n.orderNumber, {
                  'order': review.orderId,
                }),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                ),
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
              if (review.title != null && review.title!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  review.title!,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (review.comment != null && review.comment!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  review.comment!,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
