import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/auction_models.dart';
import 'auction_card.dart';

/// Bid list shown above the product spec tabs. Usernames are masked.
class AuctionBidHistory extends StatefulWidget {
  const AuctionBidHistory({required this.auction, super.key});

  final AuctionListing auction;

  @override
  State<AuctionBidHistory> createState() => _AuctionBidHistoryState();
}

class _AuctionBidHistoryState extends State<AuctionBidHistory> {
  static const _visibleRows = 5;
  static const _rowHeight = 68.0;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bids = [...widget.auction.bids]
      ..sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
    final highest = widget.auction.highestBidAmount ??
        bids.fold<double?>(
          null,
          (max, bid) => max == null || bid.amount > max ? bid.amount : max,
        );
    final window = bids.length < _visibleRows ? bids.length : _visibleRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bid history', style: AppTypography.title),
        const SizedBox(height: AppSpacing.s12),
        if (bids.isEmpty)
          Text(
            'No bids yet.',
            style: AppTypography.body.copyWith(
              color: AppColors.textMuted(context),
            ),
          )
        else
          SizedBox(
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
                  return _BidRow(
                    bid: bid,
                    isHighest: highest != null && bid.amount == highest,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _BidRow extends StatelessWidget {
  const _BidRow({required this.bid, required this.isHighest});

  final AuctionBid bid;
  final bool isHighest;

  @override
  Widget build(BuildContext context) {
    final when = bid.createdAt == null ? '' : auctionWhen(bid.createdAt!);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  maskBidderName(bid.buyerName),
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
                if (when.isNotEmpty)
                  Text(
                    when,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted(context),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                auctionBidAmount(bid.amount),
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
              ),
              if (isHighest)
                Text(
                  'Highest bid',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
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
