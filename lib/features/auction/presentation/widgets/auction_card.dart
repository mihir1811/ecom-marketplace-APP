import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../domain/models/auction_models.dart';

class AuctionCard extends StatelessWidget {
  const AuctionCard({required this.auction, this.grid = false, super.key});

  final AuctionListing auction;
  final bool grid;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(AppRouteNames.auctionDetailPath(auction.id)),
        child: grid ? _grid(context) : _list(context),
      ),
    );
  }

  Widget _list(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumb(url: auction.imageUrl),
          const SizedBox(width: AppSpacing.s12),
          Expanded(child: _details(context)),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _Thumb(url: auction.imageUrl, expand: true)),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: _details(context),
        ),
      ],
    );
  }

  Widget _details(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          auction.phaseLabel,
          style: AppTypography.caption.copyWith(
            color: AppColors.bronze,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          auction.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        if (!grid && auction.sellerName != null) ...[
          const SizedBox(height: 2),
          Text(
            auction.sellerName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted(context),
            ),
          ),
        ],
        if (auctionOutcomeLabel(auction.userOutcome) != null) ...[
          const SizedBox(height: 4),
          Text(
            auctionOutcomeLabel(auction.userOutcome)!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.bronze,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (auction.myHighestBid != null) ...[
          const SizedBox(height: 2),
          Text(
            'Your bid ${auctionBidAmount(auction.myHighestBid!)}'
            '${auction.myBidCount > 1 ? ' · ${auction.myBidCount} bids' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          auction.highestBidAmount == null
              ? AppCurrency.usd(auction.minimumBid)
              : auctionBidAmount(auction.highestBidAmount!),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          auction.endTime == null ? 'Min ${AppCurrency.usd(auction.minimumBid)}' : 'Ends ${_when(auction.endTime!)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted(context),
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, this.expand = false});

  final String? url;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final image = url;
    return ClipRRect(
      borderRadius: expand
          ? const BorderRadius.vertical(top: Radius.circular(14))
          : BorderRadius.circular(10),
      child: SizedBox(
        width: expand ? double.infinity : 84,
        height: expand ? double.infinity : 84,
        child: image == null
            ? ColoredBox(
                color: AppColors.card(context),
                child: Icon(
                  Icons.gavel_outlined,
                  color: AppColors.textMuted(context),
                ),
              )
            : Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: AppColors.card(context),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ),
      ),
    );
  }
}

String auctionWhen(DateTime value) => _when(value);

/// Whole-dollar bid. Fractional cents are not shown.
String auctionBidAmount(num amount) =>
    AppCurrency.usd(amount.round(), decimals: 0);

String? auctionOutcomeLabel(String? outcome) {
  return switch (outcome) {
    'participating' => 'Participating',
    'won' => 'Won',
    'lost' => 'Lost',
    _ => null,
  };
}

String _when(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
