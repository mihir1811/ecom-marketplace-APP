import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../domain/models/auction_models.dart';
import 'auction_card.dart';

/// Bid history card. Usernames are masked; the highest bid is marked and
/// bids arriving live slide in at the top.
class AuctionBidHistory extends StatefulWidget {
  const AuctionBidHistory({required this.auction, super.key});

  final AuctionListing auction;

  @override
  State<AuctionBidHistory> createState() => _AuctionBidHistoryState();
}

class _AuctionBidHistoryState extends State<AuctionBidHistory> {
  static const _visibleRows = 5;
  static const _rowHeight = 64.0;
  final _scroll = ScrollController();

  /// Bid ids already shown; anything new animates in.
  final _seen = <String>{};
  bool _primed = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final bids = [...widget.auction.bids]
      ..sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
    final highest =
        widget.auction.highestBidAmount ??
        bids.fold<double?>(
          null,
          (max, bid) => max == null || bid.amount > max ? bid.amount : max,
        );
    final window = bids.length < _visibleRows ? bids.length : _visibleRows;
    final fresh = <String>{
      if (_primed)
        for (final b in bids)
          if (!_seen.contains(b.id)) b.id,
    };
    _seen.addAll(bids.map((b) => b.id));
    _primed = true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text('Bid history', style: LuxeType.display(28, p.ink)),
            ),
            if (bids.isNotEmpty)
              Text(
                '${bids.length} bid${bids.length == 1 ? '' : 's'}',
                style: LuxeType.label(p.inkMuted, size: 12.5),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(LuxeSpace.radius),
            border: Border.all(color: p.hairline),
          ),
          child: bids.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Row(
                    children: [
                      Icon(Icons.gavel_rounded, size: 18, color: p.inkFaint),
                      const SizedBox(width: 10),
                      Text(
                        'No bids yet — be the first.',
                        style: LuxeType.body(p.inkMuted, size: 14),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: _rowHeight * window,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: ListView.builder(
                      controller: _scroll,
                      primary: false,
                      itemExtent: _rowHeight,
                      itemCount: bids.length,
                      itemBuilder: (context, index) {
                        final bid = bids[index];
                        Widget row = _BidRow(
                          bid: bid,
                          isHighest: highest != null && bid.amount == highest,
                          divider: index < bids.length - 1,
                        );
                        if (fresh.contains(bid.id) &&
                            !MediaQuery.disableAnimationsOf(context)) {
                          row = row
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .moveY(
                                begin: -10,
                                end: 0,
                                duration: 600.ms,
                                curve: LuxeMotion.settle,
                              );
                        }
                        return row;
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _BidRow extends StatelessWidget {
  const _BidRow({
    required this.bid,
    required this.isHighest,
    required this.divider,
  });

  final AuctionBid bid;
  final bool isHighest;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final when = bid.createdAt == null ? '' : auctionWhen(bid.createdAt!);
    final name = maskBidderName(bid.buyerName);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider
            ? Border(bottom: BorderSide(color: p.hairline, width: 0.6))
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isHighest ? p.accentSoft : p.surfaceRaised,
            child: Text(
              name.isEmpty ? '·' : name[0].toUpperCase(),
              style: LuxeType.label(isHighest ? p.accent : p.inkMuted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: LuxeType.label(p.ink, size: 13.5)),
                if (when.isNotEmpty)
                  Text(when, style: LuxeType.label(p.inkFaint, size: 11.5)),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                auctionBidAmount(bid.amount),
                style: LuxeType.figure(
                  p.ink,
                  size: 14.5,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              if (isHighest)
                Text('Highest bid', style: LuxeType.label(p.accent, size: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

/// `abdshc` becomes `a***c`. A single character becomes `a***`.
String maskBidderName(String? raw) {
  final name = raw?.trim() ?? '';
  if (name.isEmpty) return 'Bidder';
  if (name.length == 1) return '$name***';
  return '${name[0]}***${name[name.length - 1]}';
}
