import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/auth/auth_providers.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../payment/domain/models/payment_models.dart';
import '../../../../seller/application/seller_reviews_provider.dart';
import '../../../../seller/domain/models/seller_review.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../../tracking/application/order_shipments_provider.dart';
import '../../../../tracking/domain/models/shipment_models.dart';
import '../../maison/maison_kit.dart';
import 'order_refund_panels.dart';

/// Seller ratings on this order and one review form per seller not yet
/// reviewed, opened once that seller's parcel is delivered.
class OrderReviewPanel extends ConsumerStatefulWidget {
  const OrderReviewPanel({required this.order, super.key});

  final PaymentOrder order;

  @override
  ConsumerState<OrderReviewPanel> createState() => _OrderReviewPanelState();
}

class _OrderReviewPanelState extends ConsumerState<OrderReviewPanel> {
  /// Sellers reviewed in this session, before the provider refresh lands.
  final Set<String> _submittedLocally = {};

  bool get _isPaid => widget.order.status.toUpperCase() == 'PAID';

  List<({String sellerId, String sellerName})> get _targets {
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
    final targets = _targets;
    final async = ref.watch(orderSellerReviewsProvider(widget.order.id));
    final shipmentsAsync = ref.watch(orderShipmentsProvider(widget.order.id));
    final delivered = deliveredSellerIds(
      shipmentsAsync.asData?.value ?? const <Shipment>[],
    );
    final reviews = async.asData?.value ?? <SellerReview>[];
    final reviewed = {...reviews.map((r) => r.sellerId), ..._submittedLocally};
    final unreviewed = targets
        .where((t) => !reviewed.contains(t.sellerId))
        .toList();
    // Reviews open per seller once that seller's parcel is delivered.
    final pending = _isPaid
        ? unreviewed.where((t) => delivered.contains(t.sellerId)).toList()
        : const <({String sellerId, String sellerName})>[];
    final awaitingDelivery = _isPaid && pending.length < unreviewed.length;

    final Widget body;
    if ((async.isLoading && !async.hasValue) ||
        (shipmentsAsync.isLoading && !shipmentsAsync.hasValue)) {
      body = const AtelierSkeletonCard(height: 90);
    } else if (async.hasError) {
      body = AtelierNotice(
        text: async.error is Failure
            ? (async.error! as Failure).message
            : context.tr(AccountCommerceL10n.reviewsLoadFailed),
        tone: AtelierTone.ruby,
        icon: Icons.error_outline_rounded,
        actionLabel: context.tr(AccountCommerceL10n.retry),
        onAction: () =>
            ref.invalidate(orderSellerReviewsProvider(widget.order.id)),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final review in reviews) ...[
            _ReviewCard(review: review),
            const SizedBox(height: 8),
          ],
          if (!_isPaid && targets.isNotEmpty)
            const AtelierNotice(
              text: 'You can leave a review once your order is delivered.',
              icon: Icons.schedule_rounded,
            ),
          if (_isPaid && unreviewed.isEmpty && targets.isNotEmpty)
            const AtelierNotice(
              text: 'You have reviewed every seller on this order. Thank you.',
              tone: AtelierTone.emerald,
              icon: Icons.verified_rounded,
            ),
          if (awaitingDelivery) ...[
            if (reviews.isNotEmpty || pending.isNotEmpty)
              const SizedBox(height: 5),
            AtelierNotice(
              text: pending.isEmpty
                  ? 'You can leave a review once your order is delivered.'
                  : 'Other sellers open for review once their parcel is '
                        'delivered.',
              icon: Icons.local_shipping_outlined,
            ),
          ],
          for (var i = 0; i < pending.length; i++) ...[
            if (i > 0 || reviews.isNotEmpty) const SizedBox(height: 5),
            _ReviewForm(
              key: ValueKey('review-${pending[i].sellerId}'),
              orderId: widget.order.id,
              sellerId: pending[i].sellerId,
              sellerName: pending[i].sellerName,
              onSubmitted: () =>
                  setState(() => _submittedLocally.add(pending[i].sellerId)),
            ),
          ],
          if (targets.isEmpty && reviews.isEmpty)
            const AtelierNotice(
              text: 'Rate sellers from this order once it is delivered.',
            ),
        ],
      );
    }

    return AtelierPanel(
      overline: 'Reviews',
      title: context.tr(AccountCommerceL10n.sellerRatingReview),
      subtitle: targets.length > 1
          ? 'Leave a review for each seller on this order.'
          : 'How was your experience with the seller?',
      child: AnimatedSwitcher(duration: AtelierMotion.base, child: body),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({
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
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  final _title = TextEditingController();
  final _comment = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      AppHaptics.error();
      setState(() => _error = context.tr(AccountCommerceL10n.selectStar));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final thanks = context.tr(AccountCommerceL10n.thanksReview, {
      'seller': widget.sellerName,
    });
    final title = _title.text.trim();
    final comment = _comment.text.trim();
    final result = await submitSellerReview(
      ref,
      SubmitSellerReviewInput(
        sellerId: widget.sellerId,
        orderId: widget.orderId,
        rating: _rating,
        title: title.isEmpty ? null : title,
        comment: comment.isEmpty ? null : comment,
      ),
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        AppHaptics.success();
        setState(() => _submitting = false);
        widget.onSubmitted();
        showMaisonToast(
          messenger,
          palette,
          thanks,
          tone: AtelierTone.emerald,
          icon: Icons.star_rounded,
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
    final p = context.atelier;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.sunken,
        borderRadius: BorderRadius.circular(AtelierRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AtelierMonogram(name: widget.sellerName, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rate ${widget.sellerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.title(p.ink, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StarPicker(
            rating: _rating,
            enabled: !_submitting,
            onChanged: (v) => setState(() {
              _rating = v;
              _error = null;
            }),
          ),
          AnimatedSize(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            alignment: Alignment.topCenter,
            child: _rating == 0
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AtelierTextField(
                          controller: _title,
                          label: context.tr(RemainingL10n.titleOptional),
                          enabled: !_submitting,
                          textCapitalization: TextCapitalization.sentences,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(120),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AtelierTextField(
                          controller: _comment,
                          label: context.tr(RemainingL10n.reviewOptional),
                          hint: 'What stood out — the piece, packing, care?',
                          maxLines: 4,
                          enabled: !_submitting,
                          textCapitalization: TextCapitalization.sentences,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(2000),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
          AtelierFieldError(error: _error),
          const SizedBox(height: 10),
          AtelierButton(
            label: context.tr(AccountCommerceL10n.submitReviewFor, {
              'seller': widget.sellerName,
            }),
            icon: Icons.star_rounded,
            expand: true,
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.review});

  final SellerReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final me = ref.watch(authProvider.select((s) => s.user?.id)) ?? '';
    final mine = me.isNotEmpty && review.userId == me;
    final who = mine
        ? 'You'
        : (review.userName?.trim().isNotEmpty == true
              ? review.userName!.trim()
              : 'Buyer');
    final seller = review.sellerName?.trim();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.sunken,
        borderRadius: BorderRadius.circular(AtelierRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRow(rating: review.rating),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [
                    who,
                    if (seller != null && seller.isNotEmpty) 'for $seller',
                  ].join(' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.caption(p.inkSoft, size: 12),
                ),
              ),
              if (review.createdAt != null)
                Text(
                  atelierDate(review.createdAt!.toLocal()),
                  style: AtelierType.caption(p.muted, size: 11),
                ),
            ],
          ),
          if (review.title != null && review.title!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.title!, style: AtelierType.title(p.ink, size: 14)),
          ],
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(review.comment!, style: AtelierType.body(p.inkSoft, size: 13)),
          ],
          if (review.sellerReply != null && review.sellerReply!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(AtelierRadius.sm),
                border: Border(left: BorderSide(color: p.gold, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SELLER REPLY', style: AtelierType.overline(p.muted)),
                  const SizedBox(height: 4),
                  Text(
                    review.sellerReply!,
                    style: AtelierType.body(p.inkSoft, size: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
