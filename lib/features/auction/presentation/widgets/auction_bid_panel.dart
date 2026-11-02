import 'package:flutter/material.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../domain/models/auction_models.dart';
import 'auction_card.dart';
import 'auction_clock.dart';

/// Bid summary card on the auction detail: phase, the current (or opening)
/// bid as the hero figure, a live countdown, reserve and the viewer's own
/// standing. Only the countdown text ticks; the card itself never rebuilds
/// on the clock.
class AuctionBidPanel extends StatelessWidget {
  const AuctionBidPanel({required this.auction, super.key});

  final AuctionListing auction;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final a = auction;
    final deadline = auctionDeadline(a);
    final highest = a.highestBidAmount;
    final bidCount = a.bids.length;

    Widget pill(String text, Color tone, IconData icon) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: ShapeDecoration(
        color: tone.withValues(alpha: 0.1),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tone),
          const SizedBox(width: 5),
          Text(text, style: LuxeType.label(tone, size: 11.5)),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AuctionPhaseBadge(auction: a, glass: false),
              const Spacer(),
              Text(
                '$bidCount bid${bidCount == 1 ? '' : 's'}',
                style: LuxeType.label(p.inkMuted, size: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            (highest == null ? 'Opening bid' : 'Current bid').toUpperCase(),
            style: LuxeType.eyebrow(p.inkMuted),
          ),
          const SizedBox(height: 5),
          TweenAnimationBuilder<double>(
            // Rolls up to each new bid as it arrives over the socket.
            tween: Tween(end: highest ?? a.minimumBid),
            duration: LuxeMotion.reveal,
            curve: LuxeMotion.settle,
            builder: (context, value, _) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                highest == null
                    ? AppCurrency.usd(value)
                    : auctionBidAmount(value),
                style: LuxeType.display(
                  40,
                  p.ink,
                ).copyWith(fontFeatures: const [FontFeature.liningFigures()]),
              ),
            ),
          ),
          if (highest != null) ...[
            const SizedBox(height: 2),
            Text(
              'Opening bid ${AppCurrency.usd(a.minimumBid)}',
              style: LuxeType.label(p.inkFaint, size: 12),
            ),
          ],
          if (deadline != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: p.surfaceRaised,
                borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    a.isUpcoming
                        ? Icons.schedule_rounded
                        : Icons.timer_outlined,
                    size: 20,
                    color: p.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.isUpcoming ? 'Starts in' : 'Ends in',
                          style: LuxeType.label(p.inkMuted, size: 11.5),
                        ),
                        const SizedBox(height: 2),
                        AuctionCountdown(
                          deadline: deadline,
                          style: LuxeType.figure(
                            p.ink,
                            size: 17,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    auctionWhen(deadline),
                    style: LuxeType.label(p.inkFaint, size: 11.5),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (a.isReserveMet)
                pill('Reserve met', p.positive, Icons.check_circle_outline)
              else
                pill('Reserve not met', p.caution, Icons.info_outline_rounded),
              if (a.myHighestBid != null)
                pill(
                  'Your bid ${auctionBidAmount(a.myHighestBid!)}',
                  p.accent,
                  Icons.person_outline_rounded,
                ),
              if (auctionOutcomeLabel(a.userOutcome) != null)
                pill(
                  auctionOutcomeLabel(a.userOutcome)!,
                  p.accent,
                  Icons.emoji_events_outlined,
                ),
              if (a.catalogPrice != null && a.catalogPrice! > 0)
                pill(
                  'Catalogue ${auctionBidAmount(a.catalogPrice!)}',
                  p.inkMuted,
                  Icons.sell_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
