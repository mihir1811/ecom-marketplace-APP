import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auction/application/auction_providers.dart';
import '../../../auction/domain/models/auction_models.dart';
import '../../../auction/presentation/widgets/auction_standing_strip.dart';

/// Seller auction outcomes: live, upcoming, ended, decisions, sales, and bids.
class SellerAuctionStandingSection extends ConsumerWidget {
  const SellerAuctionStandingSection({this.onSelected, super.key});

  /// When set, a count opens that seller filter instead of the auctions page.
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standing = ref.watch(sellerAuctionStandingProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            0,
            AppSpacing.s16,
            AppSpacing.s8,
          ),
          child: Text('Auction outcomes', style: AppTypography.title),
        ),
        standing.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: TextButton(
              onPressed: () => ref.invalidate(sellerAuctionStandingProvider),
              child: Text(
                error is Failure ? error.message : 'Could not load auctions.',
              ),
            ),
          ),
          data: (value) => AuctionStandingStrip(
            onSelected: (id) {
              final select = onSelected;
              if (select != null) {
                select(id);
                return;
              }
              context.go(AppRouteNames.sellerAuctions);
            },
            items: _items(value),
          ),
        ),
      ],
    );
  }

  List<AuctionStandingItem> _items(SellerAuctionStanding value) {
    return [
      AuctionStandingItem(id: 'all', label: 'Auctions', count: value.total),
      AuctionStandingItem(id: 'active', label: 'Active', count: value.active),
      AuctionStandingItem(
        id: 'upcoming',
        label: 'Upcoming',
        count: value.upcoming,
      ),
      AuctionStandingItem(id: 'ended', label: 'Ended', count: value.ended),
      AuctionStandingItem(
        id: 'needs',
        label: 'Needs decision',
        count: value.needsDecision,
      ),
      AuctionStandingItem(id: 'sold', label: 'Sold', count: value.sold),
      AuctionStandingItem(id: 'bids', label: 'Bids', count: value.bids),
    ];
  }
}
