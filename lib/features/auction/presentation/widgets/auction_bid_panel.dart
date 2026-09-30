import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/auction_models.dart';
import 'auction_card.dart';

/// Bid summary shown in the product-detail column.
class AuctionBidPanel extends StatefulWidget {
  const AuctionBidPanel({required this.auction, super.key});

  final AuctionListing auction;

  @override
  State<AuctionBidPanel> createState() => _AuctionBidPanelState();
}

class _AuctionBidPanelState extends State<AuctionBidPanel> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auction = widget.auction;
    final deadline = auction.isUpcoming ? auction.startTime : auction.endTime;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            auction.phaseLabel,
            style: AppTypography.caption.copyWith(
              color: AppColors.bronze,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (auction.highestBidAmount != null) ...[
            const SizedBox(height: 8),
            Text(
              'Current bid ${auctionBidAmount(auction.highestBidAmount!)}',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          if (deadline != null) ...[
            const SizedBox(height: 8),
            Text(
              auction.isUpcoming ? 'Starts' : 'Ends',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
              ),
            ),
            Text(
              _remaining(deadline),
              style: AppTypography.title.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              auctionWhen(deadline),
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
              ),
            ),
          ],
          if (!auction.isReserveMet)
            Text(
              'Reserve not met',
              style: AppTypography.caption.copyWith(color: AppColors.terracotta),
            ),
          if (auction.bids.isNotEmpty)
            Text(
              '${auction.bids.length} bid${auction.bids.length == 1 ? '' : 's'}',
              style: AppTypography.caption,
            ),
        ],
      ),
    );
  }
}

String _remaining(DateTime deadline) {
  final diff = deadline.difference(DateTime.now());
  if (diff.isNegative) return 'Ended';
  final days = diff.inDays;
  final hours = diff.inHours.remainder(24);
  final minutes = diff.inMinutes.remainder(60);
  final seconds = diff.inSeconds.remainder(60);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${days}d ${two(hours)}h ${two(minutes)}m ${two(seconds)}s';
}
