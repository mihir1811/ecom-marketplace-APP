import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_network_image.dart';
import '../../../../seller/domain/models/seller_review.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../maison/maison_kit.dart';
import 'review_ledger.dart';

/// One review the buyer wrote: the atelier, the stars and words, any
/// photos, the seller's reply and a way back to the order.
class BuyerReviewCard extends StatefulWidget {
  const BuyerReviewCard({
    required this.review,
    required this.onOpenOrder,
    super.key,
  });

  final SellerReview review;
  final VoidCallback onOpenOrder;

  @override
  State<BuyerReviewCard> createState() => _BuyerReviewCardState();
}

class _BuyerReviewCardState extends State<BuyerReviewCard> {
  bool _expanded = false;

  SellerReview get review => widget.review;

  String get _seller {
    final name = review.sellerName?.trim();
    return name == null || name.isEmpty ? 'Seller' : name;
  }

  bool get _edited {
    final c = review.createdAt, u = review.updatedAt;
    return c != null && u != null && u.difference(c).inMinutes >= 1;
  }

  /// "Reviewed today", "Reviewed on 12 Oct 2026 · edited".
  String? get _dated {
    final created = review.createdAt;
    if (created == null) return null;
    final day = maisonDayLabel(created);
    final when = day == 'Today' || day == 'Yesterday'
        ? day.toLowerCase()
        : 'on $day';
    return 'Reviewed $when${_edited ? ' · edited' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final title = review.title?.trim();
    final comment = review.comment?.trim();
    final reply = review.sellerReply?.trim();
    final dated = _dated;

    return Pressable(
      onTap: widget.onOpenOrder,
      scale: 0.985,
      semanticLabel:
          '$_seller, ${review.rating} stars. ${title ?? ''} Open order',
      borderRadius: BorderRadius.circular(AtelierRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.lg),
          border: Border.all(color: p.hairline),
          boxShadow: p.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Row(
                children: [
                  _SellerSeal(name: _seller, logo: review.sellerLogo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _seller,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.title(p.ink, size: 15),
                        ),
                        if (dated != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            dated,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.caption(p.muted, size: 11.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!review.isVisible) ...[
                    const SizedBox(width: 8),
                    const Tooltip(
                      message: 'Hidden from the public seller page',
                      child: AtelierPill(
                        label: 'Hidden',
                        icon: Icons.visibility_off_outlined,
                        tone: AtelierTone.amber,
                        dense: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  ReviewStars(rating: review.rating.toDouble(), size: 17),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      reviewRatingWord(review.rating),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.label(p.gold, size: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (title != null && title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Text(
                  '“$title”',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.display(
                    p.ink,
                    size: 22,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            if (comment != null && comment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: _ExpandableText(
                  text: comment,
                  expanded: _expanded,
                  onToggle: () => setState(() => _expanded = !_expanded),
                ),
              ),
            if (review.imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _PhotoStrip(urls: review.imageUrls),
              ),
            if (reply != null && reply.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: _SellerReply(
                  seller: _seller,
                  reply: reply,
                  repliedAt: review.repliedAt,
                ),
              ),
            const SizedBox(height: 14),
            Container(height: 1, color: p.hairline),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 15, color: p.muted),
                  const SizedBox(width: 6),
                  Text(
                    'Order',
                    style: AtelierType.caption(p.muted, size: 11.5),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      maisonShortId(review.orderId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.figure(p.inkSoft, size: 12),
                    ),
                  ),
                  const Spacer(),
                  Text('View order', style: AtelierType.label(p.gold, size: 12)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_outward_rounded, size: 15, color: p.gold),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seller logo in a fine gold ring, or their initials.
class _SellerSeal extends StatelessWidget {
  const _SellerSeal({required this.name, this.logo});

  final String name;
  final String? logo;

  String get _initials {
    final words = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && RegExp(r'[A-Za-z0-9]').hasMatch(w[0]))
        .toList();
    if (words.isEmpty) return 'S';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final initials = Center(
      child: Text(_initials, style: AtelierType.display(p.gold, size: 18)),
    );
    final url = logo?.trim();
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: p.gold.withValues(alpha: 0.5)),
      ),
      child: ClipOval(
        child: ColoredBox(
          color: p.goldSoft,
          child: url == null || url.isEmpty
              ? initials
              : AppNetworkImage(
                  url: url,
                  fit: BoxFit.cover,
                  memCacheWidth: 120,
                  error: initials,
                ),
        ),
      ),
    );
  }
}

/// Comment clamped to four lines with a "Read more" toggle when it runs
/// longer; the card grows smoothly.
class _ExpandableText extends StatelessWidget {
  const _ExpandableText({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  static const _lines = 4;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final style = AtelierType.body(p.inkSoft, size: 13.5);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: _lines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: AtelierMotion.base,
              curve: AtelierMotion.emphasized,
              alignment: Alignment.topCenter,
              child: Text(
                text,
                maxLines: expanded ? null : _lines,
                overflow: expanded ? null : TextOverflow.ellipsis,
                style: style,
              ),
            ),
            if (overflows)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Pressable(
                  onTap: onToggle,
                  scale: 0.95,
                  semanticLabel: expanded ? 'Show less' : 'Read more',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          expanded ? 'Show less' : 'Read more',
                          style: AtelierType.label(p.ink, size: 12),
                        ),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: AtelierMotion.base,
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 16,
                            color: p.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => Reveal(
          index: i,
          horizontal: true,
          offset: 10,
          child: Pressable(
            onTap: () => showReviewPhotos(context, urls, initial: i),
            scale: 0.94,
            semanticLabel: 'Photo ${i + 1} of ${urls.length}',
            borderRadius: BorderRadius.circular(AtelierRadius.sm),
            child: Hero(
              tag: 'review-photo-${urls[i]}-$i',
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AtelierRadius.sm),
                  border: Border.all(color: p.hairline),
                ),
                clipBehavior: Clip.antiAlias,
                child: AppNetworkImage(
                  url: urls[i],
                  fit: BoxFit.cover,
                  memCacheWidth: 200,
                  error: ColoredBox(
                    color: p.sunken,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 20,
                      color: p.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerReply extends StatelessWidget {
  const _SellerReply({
    required this.seller,
    required this.reply,
    this.repliedAt,
  });

  final String seller;
  final String reply;
  final DateTime? repliedAt;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: p.sunken.withValues(alpha: p.isDark ? 0.7 : 0.55),
        borderRadius: BorderRadius.circular(AtelierRadius.md),
        border: Border(left: BorderSide(color: p.gold, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply_rounded, size: 14, color: p.gold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'REPLY FROM ${seller.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.overline(p.gold),
                ),
              ),
              if (repliedAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  maisonRelative(repliedAt),
                  style: AtelierType.caption(p.muted, size: 10.5),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(reply, style: AtelierType.body(p.ink, size: 13)),
        ],
      ),
    );
  }
}

/// Full-screen photo viewer: swipe between photos, pinch to zoom.
Future<void> showReviewPhotos(
  BuildContext context,
  List<String> urls, {
  int initial = 0,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close photos',
    barrierColor: Colors.black.withValues(alpha: 0.92),
    transitionDuration: AtelierMotion.base,
    pageBuilder: (_, _, _) => _PhotoViewer(urls: urls, initial: initial),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.urls, required this.initial});

  final List<String> urls;
  final int initial;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initial,
  );
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pages,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => Hero(
                tag: 'review-photo-${widget.urls[i]}-$i',
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: AppNetworkImage(
                      url: widget.urls[i],
                      fit: BoxFit.contain,
                      error: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white54,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 16,
              right: 8,
              child: Row(
                children: [
                  if (widget.urls.length > 1)
                    Text(
                      '${_index + 1} / ${widget.urls.length}',
                      style: AtelierType.figure(Colors.white, size: 13),
                    ),
                  const Spacer(),
                  Tooltip(
                    message: 'Close',
                    child: Pressable(
                      onTap: () => Navigator.of(context).pop(),
                      scale: 0.9,
                      semanticLabel: 'Close',
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.urls.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.urls.length; i++)
                      AnimatedContainer(
                        duration: AtelierMotion.base,
                        curve: AtelierMotion.emphasized,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _index ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? const Color(0xFFD5B27A)
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton in the shape of a [BuyerReviewCard].
class BuyerReviewSkeleton extends StatelessWidget {
  const BuyerReviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(color: p.hairline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 44, height: 44, radius: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 150, height: 13),
                    SizedBox(height: 8),
                    SkeletonBox(width: 90, height: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SkeletonBox(width: 110, height: 14),
          SizedBox(height: 12),
          SkeletonBox(width: 200, height: 18),
          SizedBox(height: 10),
          SkeletonBox(height: 10),
          SizedBox(height: 6),
          SkeletonBox(width: 220, height: 10),
        ],
      ),
    );
  }
}
