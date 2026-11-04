import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../jewelry_checkout/presentation/jewelry_checkout_format.dart';
import '../../application/jewelry_review_providers.dart';
import '../../data/jewelry_review_repository.dart';
import '../../domain/models/jewelry_review.dart';
import '../widgets/jewelry_review_card.dart';
import '../widgets/jewelry_review_photos.dart';
import '../widgets/jewelry_review_stars.dart';
import '../widgets/jewelry_reviews_section.dart';

const JewelryReviewListKey _key = (source: null, slug: '');

/// Seller studio → Reviews for a jewellery shop: every review of its
/// pieces (hidden ones included, marked) with All / To answer / Hidden
/// filters, and a public reply per review. [focusReviewId] (the review
/// push) is highlighted and scrolled to.
class JewelrySellerReviewsScreen extends ConsumerStatefulWidget {
  const JewelrySellerReviewsScreen({
    this.focusReviewId,
    this.initialShow,
    super.key,
  });

  final String? focusReviewId;
  final String? initialShow;

  @override
  ConsumerState<JewelrySellerReviewsScreen> createState() =>
      _JewelrySellerReviewsScreenState();
}

class _JewelrySellerReviewsScreenState
    extends ConsumerState<JewelrySellerReviewsScreen> {
  final _focusKey = GlobalKey();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    final show = JewelrySellerReviewShow.values
        .where((s) => s.api == widget.initialShow)
        .firstOrNull;
    // A review push shows every review, so the one asked for is there.
    if (show != null && widget.focusReviewId == null) {
      Future.microtask(
        () => ref.read(jewelryReviewListProvider(_key).notifier).setShow(show),
      );
    }
  }

  void _scrollToFocus() {
    if (_scrolled) return;
    final ctx = _focusKey.currentContext;
    if (ctx == null) return;
    _scrolled = true;
    Scrollable.ensureVisible(
      ctx,
      duration: LuxeMotion.medium,
      curve: LuxeMotion.settle,
      alignment: 0.1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _build));
  }

  Widget _build(BuildContext context) {
    final p = LuxePalette.of(context);
    final s = ref.watch(jewelryReviewListProvider(_key));
    final list = ref.read(jewelryReviewListProvider(_key).notifier);
    final focus = widget.focusReviewId?.toLowerCase();
    if (focus != null && !s.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocus());
    }

    Widget body;
    if (s.loading && s.items.isEmpty && s.error == null) {
      body = ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          LuxeSkeleton(height: 120, radius: LuxeSpace.radius),
          SizedBox(height: 8),
          LuxeSkeleton(height: 140, radius: LuxeSpace.radius),
        ],
      );
    } else if (s.error != null && s.items.isEmpty) {
      // Not a jewellery shop (or no shop yet): the API says why.
      body = LuxeStateView(
        icon: Icons.storefront_outlined,
        tone: LuxeTone.error,
        title: context.tr(JewelryReviewL10n.sellerUnavailable),
        message: jewelryReviewError(s.error!),
        actionLabel: context.tr(CatalogL10n.retry),
        onAction: list.refresh,
      );
    } else {
      final summary = s.summary;
      body = RefreshIndicator(
        color: p.accent,
        onRefresh: () async {
          ref.invalidate(jewelrySellerReviewStatsProvider);
          await list.refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
          children: [
            if (summary.count > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(LuxeSpace.radius),
                  border: Border.all(color: p.hairline),
                ),
                child: JewelryReviewSummaryPanel(
                  summary: summary,
                  selected: s.rating,
                  onSelect: list.setRating,
                ),
              ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final show in JewelrySellerReviewShow.values) ...[
                    ChoiceChip(
                      selected: s.show == show,
                      onSelected: (_) => list.setShow(show),
                      label: Text(_showLabel(context, show, summary)),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            JewelryReviewListBar(
              rating: s.rating,
              sort: s.sort,
              onClear: () => list.setRating(null),
              onSort: list.setSort,
            ),
            if (s.items.isEmpty && !s.loading)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: LuxeStateView(
                  icon: Icons.reviews_outlined,
                  title: context.tr(JewelryReviewL10n.sellerEmpty),
                  message: context.tr(JewelryReviewL10n.sellerEmptyBody),
                ),
              ),
            AnimatedOpacity(
              opacity: s.loading ? 0.45 : 1,
              duration: LuxeMotion.fast,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final r in s.items)
                    _SellerReviewCard(
                      key: r.id.toLowerCase() == focus ? _focusKey : null,
                      review: r,
                      focused: r.id.toLowerCase() == focus,
                    ),
                ],
              ),
            ),
            if (s.error != null && s.items.isNotEmpty)
              Text(
                jewelryReviewError(s.error!),
                style: LuxeType.body(p.caution, size: 12.5),
              ),
            if (s.hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: LuxeButton(
                  label: context.tr(JewelryReviewL10n.showMore),
                  variant: LuxeButtonVariant.secondary,
                  height: 44,
                  expand: true,
                  loading: s.loadingMore,
                  onPressed: s.loadingMore ? null : list.loadMore,
                ),
              ),
          ],
        ),
      );
    }

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(title: context.tr(JewelryReviewL10n.title)),
      body: body,
    );
  }

  static String _showLabel(
    BuildContext context,
    JewelrySellerReviewShow show,
    JewelryReviewSummary summary,
  ) {
    final (label, count) = switch (show) {
      JewelrySellerReviewShow.all => (JewelryReviewL10n.showAll, null),
      JewelrySellerReviewShow.unanswered => (
        JewelryReviewL10n.showUnanswered,
        summary.unanswered,
      ),
      JewelrySellerReviewShow.hidden => (
        JewelryReviewL10n.showHidden,
        summary.hidden,
      ),
    };
    final text = context.tr(label);
    return count == null || count == 0 ? text : '$text ($count)';
  }
}

class _SellerReviewCard extends ConsumerStatefulWidget {
  const _SellerReviewCard({
    required this.review,
    required this.focused,
    super.key,
  });

  final JewelryReview review;
  final bool focused;

  @override
  ConsumerState<_SellerReviewCard> createState() => _SellerReviewCardState();
}

class _SellerReviewCardState extends ConsumerState<_SellerReviewCard> {
  bool _busy = false;

  void _afterChange(JewelryReview updated, String message) {
    ref.read(jewelryReviewListProvider(_key).notifier).replace(updated);
    ref.invalidate(jewelrySellerReviewStatsProvider);
    showLuxeToast(context, message, tone: LuxeTone.success);
  }

  Future<void> _reply() async {
    final r = widget.review;
    final text = await showLuxeSheet<String>(
      context,
      title: context.tr(
        r.hasReply ? JewelryReviewL10n.editReply : JewelryReviewL10n.reply,
      ),
      subtitle: r.buyerName,
      builder: (_) => _ReplyForm(initial: r.sellerReply ?? ''),
    );
    if (text == null || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(jewelryReviewRepositoryProvider)
        .reply(r.id, text);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(value: (:final review, :final message)):
        _afterChange(
          review ?? r.withReply(text.trim(), DateTime.now()),
          message ?? context.tr(JewelryReviewL10n.replyPosted),
        );
      case ResultFailure(:final failure):
        showLuxeToast(
          context,
          jewelryReviewError(failure),
          tone: LuxeTone.error,
        );
    }
  }

  Future<void> _remove() async {
    final r = widget.review;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(JewelryReviewL10n.removeReply)),
        content: Text(context.tr(JewelryReviewL10n.removeReplyBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr(JewelryReviewL10n.cancel)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr(JewelryReviewL10n.remove)),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(jewelryReviewRepositoryProvider)
        .deleteReply(r.id);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(value: (:final review, :final message)):
        _afterChange(
          review ?? r.withReply(null, null),
          message ?? context.tr(JewelryReviewL10n.replyRemoved),
        );
      case ResultFailure(:final failure):
        showLuxeToast(
          context,
          jewelryReviewError(failure),
          tone: LuxeTone.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final r = widget.review;
    final piece = r.piece;
    final reason = r.hiddenReason?.trim() ?? '';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(
          color: widget.focused ? p.accent : p.hairline,
          width: widget.focused ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      : AppNetworkImage(
                          url: piece.imageUrl!,
                          memCacheWidth: 120,
                        ),
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
                      style: LuxeType.label(p.ink, size: 13),
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
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              JewelryStars(rating: r.rating.toDouble(), size: 16),
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
          const SizedBox(height: 3),
          Text(
            [
              r.buyerName,
              jewelryReviewDate(context, r.createdAt),
              if (r.editedAt != null) context.tr(JewelryReviewL10n.edited),
            ].where((s) => s.isNotEmpty).join(' · '),
            style: LuxeType.body(p.inkMuted, size: 12),
          ),
          if (r.orderNumber != null)
            InkWell(
              onTap: r.orderId == null
                  ? null
                  : () => context.push(
                      AppRouteNames.jewelryShopOrdersPath(
                        openOrderId: r.orderId,
                      ),
                    ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  context.tr(JewelryReviewL10n.order, {
                    'number': r.orderNumber,
                  }),
                  style: LuxeType.label(p.accent, size: 12),
                ),
              ),
            ),
          if (r.body != null) ...[
            const SizedBox(height: 5),
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
                  ? context.tr(JewelryReviewL10n.hiddenBy)
                  : '${context.tr(JewelryReviewL10n.hiddenBy)}: $reason',
            ),
          ],
          const SizedBox(height: 8),
          if (r.hasReply)
            JewelryReviewReplyBlock(
              label: context.tr(JewelryReviewL10n.yourReply),
              reply: r.sellerReply!,
              at: r.sellerRepliedAt,
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else ...[
                if (r.hasReply)
                  TextButton(
                    onPressed: _remove,
                    style: TextButton.styleFrom(foregroundColor: p.inkMuted),
                    child: Text(context.tr(JewelryReviewL10n.removeReply)),
                  ),
                TextButton.icon(
                  onPressed: _reply,
                  style: TextButton.styleFrom(foregroundColor: p.accent),
                  icon: Icon(
                    r.hasReply ? Icons.edit_outlined : Icons.reply_rounded,
                    size: 18,
                  ),
                  label: Text(
                    context.tr(
                      r.hasReply
                          ? JewelryReviewL10n.editReply
                          : JewelryReviewL10n.reply,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplyForm extends StatefulWidget {
  const _ReplyForm({required this.initial});

  final String initial;

  @override
  State<_ReplyForm> createState() => _ReplyFormState();
}

class _ReplyFormState extends State<_ReplyForm> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _text,
          autofocus: true,
          maxLength: JewelryReviewRules.maxReply,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: context.tr(JewelryReviewL10n.replyHint),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        LuxeButton(
          label: context.tr(JewelryReviewL10n.reply),
          variant: LuxeButtonVariant.accent,
          expand: true,
          onPressed: _text.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_text.text.trim()),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
