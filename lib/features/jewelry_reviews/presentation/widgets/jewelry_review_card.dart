import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../jewelry_checkout/presentation/jewelry_checkout_format.dart';
import '../../../jewelry_checkout/presentation/open_jewelry_listing.dart';
import '../../domain/models/jewelry_review.dart';
import 'jewelry_review_photos.dart';
import 'jewelry_review_stars.dart';

/// Localized "3 Nov 2026".
String jewelryReviewDate(BuildContext context, DateTime? at) =>
    at == null ? '' : MaterialLocalizations.of(context).formatMediumDate(at);

/// The shop's public reply under a review.
class JewelryReviewReplyBlock extends StatelessWidget {
  const JewelryReviewReplyBlock({
    required this.label,
    required this.reply,
    this.at,
    this.trailing,
    super.key,
  });

  final String label;
  final String reply;
  final DateTime? at;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final date = jewelryReviewDate(context, at);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: p.accent, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_outlined, size: 14, color: p.accent),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  [label, if (date.isNotEmpty) date].join(' · '),
                  style: LuxeType.label(p.inkMuted, size: 12),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 4),
          Text(reply, style: LuxeType.body(p.ink, size: 13.5)),
        ],
      ),
    );
  }
}

/// "GemWorld hid this review: {reason}".
class JewelryReviewHiddenNotice extends StatelessWidget {
  const JewelryReviewHiddenNotice({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: p.caution.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.caution.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_off_outlined, size: 16, color: p.caution),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: LuxeType.body(p.caution, size: 12.5)),
          ),
        ],
      ),
    );
  }
}

/// One review in a public list. On a shop screen ([showPiece]) the piece
/// is shown with its photo (linked while it is still for sale); on a
/// product screen the variant bought is enough.
class JewelryReviewCard extends ConsumerWidget {
  const JewelryReviewCard({
    required this.review,
    required this.shopName,
    this.showPiece = false,
    super.key,
  });

  final JewelryReview review;
  final String shopName;
  final bool showPiece;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final r = review;
    final piece = r.piece;
    final meta = [
      r.buyerName,
      jewelryReviewDate(context, r.createdAt),
      if (r.editedAt != null) context.tr(JewelryReviewL10n.edited),
    ].where((s) => s.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              JewelryStars(rating: r.rating.toDouble(), size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  r.title ?? jewelryStarWord(context, r.rating),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(p.ink, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(meta, style: LuxeType.body(p.inkMuted, size: 12)),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 13, color: p.positive),
              const SizedBox(width: 4),
              Text(
                context.tr(JewelryReviewL10n.received),
                style: LuxeType.label(p.positive, size: 11.5),
              ),
            ],
          ),
          if (r.body != null) ...[
            const SizedBox(height: 7),
            Text(r.body!, style: LuxeType.body(p.ink, size: 13.5)),
          ],
          if (r.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            JewelryReviewPhotoStrip(urls: r.imageUrls),
          ],
          if (showPiece && piece.title.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PieceRow(piece: piece),
          ] else if (piece.options.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              optionsLine(piece.options),
              style: LuxeType.body(p.inkFaint, size: 12),
            ),
          ],
          if (r.hasReply) ...[
            const SizedBox(height: 8),
            JewelryReviewReplyBlock(
              label: context.tr(JewelryReviewL10n.replyFrom, {
                'shop': shopName,
              }),
              reply: r.sellerReply!,
              at: r.sellerRepliedAt,
            ),
          ],
        ],
      ),
    );
  }
}

class _PieceRow extends ConsumerWidget {
  const _PieceRow({required this.piece});

  final JewelryReviewPiece piece;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final slug = piece.listingSlug;
    final row = Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(
            dimension: 40,
            child: piece.imageUrl == null
                ? ColoredBox(
                    color: p.surfaceRaised,
                    child: Icon(Icons.diamond_outlined, color: p.accent),
                  )
                : AppNetworkImage(url: piece.imageUrl!, memCacheWidth: 120),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                piece.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuxeType.label(
                  slug == null ? p.inkMuted : p.ink,
                  size: 12.5,
                ),
              ),
              if (piece.options.isNotEmpty)
                Text(
                  optionsLine(piece.options),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.body(p.inkFaint, size: 11.5),
                ),
            ],
          ),
        ),
        if (slug != null)
          Icon(Icons.chevron_right_rounded, size: 18, color: p.inkFaint),
      ],
    );
    if (slug == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => openJewelryListing(context, ref, slug),
      child: row,
    );
  }
}
