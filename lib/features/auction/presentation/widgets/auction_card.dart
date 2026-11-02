import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/catalog_card_image_pager.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../domain/models/auction_models.dart';
import 'auction_clock.dart';

/// Auction result card on the shared luxe card layout: phase and a live
/// countdown over the photo, title, the viewer's standing, and the
/// current (or opening) bid.
class AuctionCard extends ConsumerWidget {
  const AuctionCard({required this.auction, this.grid = false, super.key});

  final AuctionListing auction;
  final bool grid;

  void _open(BuildContext context) =>
      context.openRoute(AppRouteNames.auctionDetailPath(auction.id));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = auction;
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    final standing = _standing(
      a,
      isWinner: userId != null && a.winnerId == userId,
    );
    final deadline = auctionDeadline(a);
    final countdown = deadline != null && (a.isLive || a.isUpcoming)
        ? _CountdownChip(deadline: deadline, upcoming: a.isUpcoming)
        : null;
    final price = _BidFigure(auction: a);

    if (grid) {
      return LuxeProductGridCard(
        onTap: () => _open(context),
        media: _AuctionThumb(url: a.imageUrl),
        title: a.title,
        subtitle: standing ?? a.sellerName ?? _typeLabel(a.productType),
        meta: _when(a),
        price: price,
        overlays: LuxeMediaOverlays(
          topLeft: AuctionPhaseBadge(auction: a),
          bottomLeft: countdown,
        ),
      );
    }
    return LuxeProductListCard(
      onTap: () => _open(context),
      media: _AuctionThumb(url: a.imageUrl),
      title: a.title,
      subtitle: standing ?? a.sellerName ?? _typeLabel(a.productType),
      detail: [
        if (standing != null && a.sellerName != null) a.sellerName!,
        ?_when(a),
      ].join(' · '),
      price: price,
      thumbTopLeft: AuctionPhaseBadge(auction: a),
      thumbBottomLeft: countdown,
    );
  }
}

/// "Won · Pay by 2026-10-29 15:28 · Your bid $1,200" for the viewer's own
/// activity.
String? _standing(AuctionListing a, {required bool isWinner}) {
  final parts = [
    ?auctionOutcomeLabel(a.userOutcome),
    if (isWinner) ?auctionWinPaymentLabel(a),
    if (a.myHighestBid != null) 'Your bid ${auctionBidAmount(a.myHighestBid!)}',
    if (a.myHighestBid != null && a.myBidCount > 1) '${a.myBidCount} bids',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

String? _when(AuctionListing a) {
  if (a.isUpcoming && a.startTime != null) {
    return 'Starts ${auctionWhen(a.startTime!)}';
  }
  if (a.endTime != null) return 'Ends ${auctionWhen(a.endTime!)}';
  return 'Min ${AppCurrency.usd(a.minimumBid)}';
}

String _typeLabel(String type) => switch (type) {
  'diamond' => 'Diamond',
  'gemstone' => 'Gemstone',
  'meleeDiamond' => 'Melee diamond',
  'jewellery' => 'Jewellery',
  _ => type,
};

/// Current bid (or opening bid) with a quiet caption.
class _BidFigure extends StatelessWidget {
  const _BidFigure({required this.auction});

  final AuctionListing auction;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final highest = auction.highestBidAmount;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            highest == null
                ? AppCurrency.usd(auction.minimumBid)
                : auctionBidAmount(highest),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: LuxeType.figure(
              p.ink,
              size: 15,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          highest == null ? 'opening' : 'current bid',
          maxLines: 1,
          style: LuxeType.label(p.inkFaint, size: 11),
        ),
      ],
    );
  }
}

class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.deadline, required this.upcoming});

  final DateTime deadline;
  final bool upcoming;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: ShapeDecoration(
        color: p.isDark ? const Color(0x99000000) : const Color(0xEBFFFFFF),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            upcoming ? Icons.schedule_rounded : Icons.timer_outlined,
            size: 12,
            color: p.ink,
          ),
          const SizedBox(width: 4),
          AuctionCountdown(
            deadline: deadline,
            short: true,
            style: LuxeType.figure(p.ink, size: 11),
          ),
        ],
      ),
    );
  }
}

class _AuctionThumb extends StatelessWidget {
  const _AuctionThumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final fallback = ColoredBox(
      color: p.surfaceRaised,
      child: Center(
        child: Icon(Icons.gavel_rounded, size: 40, color: p.accent),
      ),
    );
    final image = url?.trim();
    return CatalogCardImagePager(
      imageUrls: image == null || image.isEmpty ? const [] : [image],
      fallback: fallback,
      memCacheWidth: 480,
    );
  }
}

/// "2026-10-04 18:00" in local time.
String auctionWhen(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Whole-dollar bid. Fractional cents are not shown.
String auctionBidAmount(num amount) =>
    AppCurrency.usd(amount.round(), decimals: 0);

/// The accepted winner's payment line: deadline, GemWorld, or paid.
String? auctionWinPaymentLabel(AuctionListing a) {
  return switch (a.winPayment) {
    AuctionWinPayment.due =>
      a.paymentDueAt == null
          ? 'Pay from your cart'
          : 'Pay by ${auctionWhen(a.paymentDueAt!)}',
    AuctionWinPayment.withGemworld => 'GemWorld is arranging the payment',
    AuctionWinPayment.expired => 'Payment window ended',
    AuctionWinPayment.paid => 'Paid',
    AuctionWinPayment.none => null,
  };
}

String? auctionOutcomeLabel(String? outcome) {
  return switch (outcome) {
    'participating' => 'Participating',
    'won' => 'Won',
    'lost' => 'Lost',
    _ => null,
  };
}
