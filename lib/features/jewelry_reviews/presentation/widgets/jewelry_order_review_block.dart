import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../jewelry_checkout/domain/models/marketplace_order.dart';
import '../../../jewelry_checkout/presentation/jewelry_checkout_format.dart';
import '../../application/jewelry_review_providers.dart';
import '../../domain/models/jewelry_review.dart';
import 'jewelry_review_card.dart';
import 'jewelry_review_form.dart';
import 'jewelry_review_photos.dart';
import 'jewelry_review_stars.dart';

/// Under a piece on the buyer's order screen: a "How is it?" prompt once
/// it is delivered, then the buyer's review with Edit (30 days), the
/// GemWorld-hidden notice and the shop's reply. Nothing otherwise.
class JewelryOrderReviewBlock extends ConsumerWidget {
  const JewelryOrderReviewBlock({
    required this.orderId,
    required this.item,
    super.key,
  });

  final String orderId;
  final MarketplaceOrderItem item;

  Future<void> _open(
    BuildContext context,
    WidgetRef ref, {
    JewelryOwnReview? existing,
    int stars = 0,
  }) async {
    final saved = await showJewelryReviewForm(
      context,
      orderId: orderId,
      orderItemId: item.id,
      pieceTitle: item.title,
      existing: existing,
      initialRating: stars,
    );
    if (saved == null) return;
    // Show it on the line straight away; no need to reload the order.
    final overrides = ref.read(jewelryOwnReviewOverridesProvider.notifier);
    overrides.state = {...overrides.state, item.id: saved};
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(
      jewelryOwnReviewOverridesProvider.select((m) => m[item.id]),
    );
    final review = override ?? item.review;
    // Reviews open only once the piece is delivered, whatever the API says.
    final canReview =
        override == null &&
        item.review == null &&
        item.canReview &&
        item.isDelivered;
    if (review == null && !canReview) return const SizedBox.shrink();

    final p = LuxePalette.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: p.surfaceRaised.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: review == null
          ? _Prompt(
              onStar: (s) => _open(context, ref, stars: s),
              onWrite: () => _open(context, ref),
            )
          : _OwnReview(
              review: review,
              shopName: item.shopName,
              onEdit: () => _open(context, ref, existing: review),
            ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.onStar, required this.onWrite});

  final ValueChanged<int> onStar;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(JewelryReviewL10n.howIsIt),
          style: LuxeType.label(p.ink, size: 14),
        ),
        const SizedBox(height: 2),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            JewelryStarPicker(value: 0, onChanged: onStar, size: 30),
            TextButton.icon(
              onPressed: onWrite,
              style: TextButton.styleFrom(foregroundColor: p.accent),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: Text(context.tr(JewelryReviewL10n.writeReview)),
            ),
          ],
        ),
      ],
    );
  }
}

class _OwnReview extends StatelessWidget {
  const _OwnReview({
    required this.review,
    required this.shopName,
    required this.onEdit,
  });

  final JewelryOwnReview review;
  final String shopName;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final r = review;
    final reason = r.hiddenReason?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr(JewelryReviewL10n.yourReview).toUpperCase(),
                style: LuxeType.eyebrow(p.inkMuted),
              ),
            ),
            if (r.canEdit)
              TextButton.icon(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: p.accent,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(context.tr(JewelryReviewL10n.edit)),
              ),
          ],
        ),
        Row(
          children: [
            JewelryStars(rating: r.rating.toDouble(), size: 16),
            const SizedBox(width: 6),
            Text(
              jewelryStarWord(context, r.rating),
              style: LuxeType.label(p.accent, size: 12.5),
            ),
          ],
        ),
        if (r.title != null) ...[
          const SizedBox(height: 5),
          Text(r.title!, style: LuxeType.label(p.ink, size: 14)),
        ],
        if (r.body != null) ...[
          const SizedBox(height: 3),
          Text(r.body!, style: LuxeType.body(p.ink, size: 13.5)),
        ],
        if (r.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 8),
          JewelryReviewPhotoStrip(urls: r.imageUrls, size: 56),
        ],
        if (r.hidden) ...[
          const SizedBox(height: 8),
          JewelryReviewHiddenNotice(
            text: reason.isEmpty
                ? context.tr(JewelryReviewL10n.hiddenNoticeBare)
                : context.tr(JewelryReviewL10n.hiddenNotice, {
                    'reason': reason,
                  }),
          ),
        ],
        if ((r.sellerReply ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          JewelryReviewReplyBlock(
            label: context.tr(JewelryReviewL10n.replyFrom, {'shop': shopName}),
            reply: r.sellerReply!,
            at: r.sellerRepliedAt,
          ),
        ],
        if (r.canEdit && r.editableUntil != null) ...[
          const SizedBox(height: 6),
          Text(
            context.tr(JewelryReviewL10n.canChangeUntil, {
              'date': dateTimeLabel(context, r.editableUntil),
            }),
            style: LuxeType.body(p.inkFaint, size: 11.5),
          ),
        ],
      ],
    );
  }
}
