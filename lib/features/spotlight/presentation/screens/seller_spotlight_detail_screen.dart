import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../buyer/presentation/maison/maison_kit.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/spotlight_seller_providers.dart';
import '../../data/spotlight_seller_repository.dart';
import '../../domain/spotlight_seller_models.dart';
import 'seller_spotlight_screen.dart';

/// One booked ad: what it shows, where and when, what it cost, how it is
/// doing day by day, and Cancel while it hasn't started.
class SellerSpotlightDetailScreen extends ConsumerStatefulWidget {
  const SellerSpotlightDetailScreen({required this.adId, super.key});

  final String adId;

  @override
  ConsumerState<SellerSpotlightDetailScreen> createState() =>
      _SellerSpotlightDetailScreenState();
}

class _SellerSpotlightDetailScreenState
    extends ConsumerState<SellerSpotlightDetailScreen> {
  bool _cancelling = false;

  Future<void> _refresh() async {
    ref.invalidate(sellerSpotlightAdProvider(widget.adId));
    await ref
        .read(sellerSpotlightAdProvider(widget.adId).future)
        .then<Object?>((v) => v)
        .catchError((_) => null);
  }

  Future<void> _cancel(SpotlightSellerAd ad) async {
    final ok = await showAtelierConfirm(
      context: context,
      title: 'Cancel this ad?',
      message:
          'It won’t run, and ${maisonInr(ad.netAmount)} goes back to your '
          'wallet.',
      confirmLabel: 'Cancel ad',
      cancelLabel: 'Keep it',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _cancelling = true);
    final result = await ref
        .read(spotlightSellerRepositoryProvider)
        .cancel(widget.adId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    switch (result) {
      case Success():
        AppHaptics.success();
        showAtelierToast(
          context,
          'Ad cancelled. The refund is back in your wallet.',
          tone: AtelierTone.emerald,
        );
        ref
          ..invalidate(sellerSpotlightAdProvider(widget.adId))
          ..invalidate(sellerSpotlightAdsProvider)
          ..invalidate(spotlightOverviewProvider);
      case ResultFailure(:final failure):
        AppHaptics.error();
        showAtelierToast(context, failure.message, tone: AtelierTone.ruby);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = ref.watch(sellerSpotlightAdProvider(widget.adId));
    return AtelierPage(
      onRefresh: _refresh,
      children: ad.when(
        loading: () => [const AtelierSkeletonList(count: 4, height: 120)],
        error: (e, _) => [
          AtelierErrorState(
            message: spotlightErrorText(e),
            onRetry: () =>
                ref.invalidate(sellerSpotlightAdProvider(widget.adId)),
          ),
        ],
        data: (a) => _content(context, a),
      ),
    );
  }

  List<Widget> _content(BuildContext context, SpotlightSellerAd ad) {
    final p = context.atelier;
    final title = ad.title?.trim();
    final subtitle = ad.subtitle?.trim();
    final image = ad.imageUrl ?? ad.mobileImageUrl;
    final days = ad.days;
    final ctr = ad.ctr;

    return [
      Reveal(
        child: AtelierCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (image != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AtelierRadius.lg),
                  ),
                  child: AspectRatio(
                    aspectRatio: ad.imageUrl != null ? 4 : 2,
                    child: AppNetworkImage(url: image, memCacheWidth: 1200),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AtelierSpace.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (title != null && title.isNotEmpty)
                                ? title
                                : spotlightPlacementName(ad),
                            style: AtelierType.display(p.ink, size: 24),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AtelierPill(
                          label: ad.state.label,
                          tone: spotlightStateTone(ad.state),
                        ),
                      ],
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(subtitle, style: AtelierType.body(p.muted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ..._notices(ad),
      const SizedBox(height: AtelierSpace.s16),
      Reveal(
        index: 1,
        child: AtelierTileGrid(
          columns: 3,
          minTileWidth: 100,
          children: [
            AtelierStatTile(
              label: 'Views',
              value: '${ad.views}',
              icon: Icons.visibility_outlined,
              dense: true,
            ),
            AtelierStatTile(
              label: 'Clicks',
              value: '${ad.clicks}',
              icon: Icons.ads_click_rounded,
              dense: true,
            ),
            AtelierStatTile(
              label: 'CTR',
              value: ctr == null ? '—' : '${ctr.toStringAsFixed(1)}%',
              icon: Icons.percent_rounded,
              tone: AtelierTone.emerald,
              dense: true,
            ),
          ],
        ),
      ),
      const SizedBox(height: AtelierSpace.s16),
      Reveal(
        index: 2,
        child: AtelierPanel(
          title: 'Booking',
          child: Wrap(
            spacing: AtelierSpace.s24,
            runSpacing: AtelierSpace.s16,
            children: [
              _kv('Placement', spotlightPlacementName(ad)),
              if (ad.category != null)
                _kv('Section', spotlightCategoryName(ad.category!)),
              _kv(
                'Dates',
                [
                  spotlightRange(ad.startDate, ad.endDate),
                  if (days != null) '($days ${days == 1 ? 'day' : 'days'})',
                ].join(' '),
              ),
              _kv('Paid', maisonInr(ad.amount)),
              if (ad.refundedAmount > 0)
                _kv('Refunded', maisonInr(ad.refundedAmount)),
              _kv('Net', maisonInr(ad.netAmount)),
              if (ad.createdAt != null)
                _kv('Booked', maisonDayLabel(ad.createdAt)),
            ],
          ),
        ),
      ),
      if (ad.daily.length > 1) ...[
        const SizedBox(height: AtelierSpace.s16),
        Reveal(
          index: 3,
          child: AtelierPanel(
            title: 'Daily views',
            subtitle: 'Tap a point for that day’s clicks',
            child: AtelierLineChart(
              height: 200,
              values: [for (final d in ad.daily) d.views.toDouble()],
              labels: [for (final d in ad.daily) maisonDayLabel(d.date)],
              detailAt: (i) {
                final d = ad.daily[i];
                return '${d.views} views · ${d.clicks} clicks';
              },
              formatValue: (v) => v.round().toString(),
            ),
          ),
        ),
      ],
      if (ad.products.isNotEmpty) ...[
        const SizedBox(height: AtelierSpace.s16),
        Reveal(
          index: 4,
          child: AtelierPanel(
            title: 'Sponsored products',
            subtitle: '${ad.products.length} in this ad',
            child: Column(
              children: [
                for (final product in ad.products)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AtelierSpace.s10),
                    child: Row(
                      children: [
                        AtelierThumb(url: product.imageUrl, size: 48),
                        const SizedBox(width: AtelierSpace.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AtelierType.label(p.ink),
                              ),
                              if (product.stockNumber != null)
                                Text(
                                  '#${product.stockNumber}',
                                  style: AtelierType.caption(p.muted),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      if (ad.canCancel) ...[
        const SizedBox(height: AtelierSpace.s24),
        AtelierButton(
          label: 'Cancel ad',
          icon: Icons.close_rounded,
          variant: AtelierButtonVariant.danger,
          expand: true,
          loading: _cancelling,
          onPressed: _cancelling ? null : () => _cancel(ad),
        ),
        const SizedBox(height: AtelierSpace.s8),
        Text(
          'Ads can be cancelled until their first day. What’s left of the '
          'payment goes back to your wallet.',
          textAlign: TextAlign.center,
          style: AtelierType.caption(p.muted),
        ),
      ],
      const SizedBox(height: AtelierSpace.s32),
    ];
  }

  List<Widget> _notices(SpotlightSellerAd ad) {
    final note = ad.adminNote?.trim();
    final text = switch (ad.state) {
      SpotlightAdState.pendingReview =>
        'Paid and waiting for GemWorld’s review. It starts on its first day '
            'once approved.',
      SpotlightAdState.scheduled => 'Approved. It goes live on its first day.',
      SpotlightAdState.expired =>
        'Not reviewed before its last day, so it was refunded in full.',
      SpotlightAdState.cancelled => 'Cancelled. The payment was refunded.',
      _ => null,
    };
    final bad =
        ad.state == SpotlightAdState.rejected ||
        ad.state == SpotlightAdState.stopped;
    return [
      if (text != null) ...[
        const SizedBox(height: AtelierSpace.s12),
        AtelierNotice(
          text: text,
          tone: spotlightStateTone(ad.state),
          dense: true,
        ),
      ],
      if (note != null && note.isNotEmpty) ...[
        const SizedBox(height: AtelierSpace.s12),
        AtelierNotice(
          text: 'GemWorld: $note',
          tone: bad ? AtelierTone.ruby : AtelierTone.neutral,
          icon: bad ? Icons.report_gmailerrorred_rounded : Icons.info_outline,
        ),
      ],
    ];
  }

  Widget _kv(String label, String value) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 120),
    child: AtelierKeyValue(label: label, value: value),
  );
}
