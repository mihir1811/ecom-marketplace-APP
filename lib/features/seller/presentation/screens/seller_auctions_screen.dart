import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/seller_orders_mock_data.dart';
import '../../domain/models/seller_orders_models.dart';
import '../widgets/seller_layout.dart';

class SellerAuctionsScreen extends StatefulWidget {
  const SellerAuctionsScreen({super.key});

  @override
  State<SellerAuctionsScreen> createState() => _SellerAuctionsScreenState();
}

class _SellerAuctionsScreenState extends State<SellerAuctionsScreen> {
  SellerAuctionStatus? _filter;
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final items = kSellerAuctionsMock.where((a) {
      if (_filter == null) return true;
      return a.status == _filter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => openSellerDrawer(context),
                icon: const Icon(Icons.menu),
              ),
              Expanded(
                child: Text(
                  'My Auctions',
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.sandSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.gavel_outlined,
                        size: 56,
                        color: AppColors.textMutedLight.withValues(alpha: 0.25),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmWhite,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.warmBorder),
                          ),
                          child: Text(
                            'Seller · Auctions',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Manage your live auctions, view all bids, and see '
                          'winners when auctions close.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  _FilterChip(
                    label: 'Active',
                    selected: _filter == SellerAuctionStatus.active,
                    onTap: () =>
                        setState(() => _filter = SellerAuctionStatus.active),
                  ),
                  _FilterChip(
                    label: 'Upcoming',
                    selected: _filter == SellerAuctionStatus.upcoming,
                    onTap: () =>
                        setState(() => _filter = SellerAuctionStatus.upcoming),
                  ),
                  _FilterChip(
                    label: 'Ended',
                    selected: _filter == SellerAuctionStatus.ended,
                    onTap: () =>
                        setState(() => _filter = SellerAuctionStatus.ended),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final auction in items) ...[
                _AuctionCard(
                  auction: auction,
                  expanded: _expanded.contains(auction.id),
                  onToggleBids: () {
                    setState(() {
                      if (_expanded.contains(auction.id)) {
                        _expanded.remove(auction.id);
                      } else {
                        _expanded.add(auction.id);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'No auctions in this filter.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.info : AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? AppColors.info : AppColors.warmBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.warmWhite : AppColors.charcoal,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuctionCard extends StatelessWidget {
  const _AuctionCard({
    required this.auction,
    required this.expanded,
    required this.onToggleBids,
  });

  final SellerAuction auction;
  final bool expanded;
  final VoidCallback onToggleBids;

  String get _statusLabel => switch (auction.status) {
        SellerAuctionStatus.active => 'Active',
        SellerAuctionStatus.upcoming => 'Upcoming',
        SellerAuctionStatus.ended => 'Ended',
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.warmBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                _Pill(label: auction.category),
                _Pill(label: _statusLabel),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              auction.productLabel,
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Auction #${auction.id} · Min bid: ${auction.minBid} · Current: ${auction.currentBid}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.textMutedLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${auction.startsAt} → ${auction.endsAt}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View public page'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.info,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    'View product',
                    style: AppTypography.caption.copyWith(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            InkWell(
              onTap: onToggleBids,
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${auction.bids.length} bids · Highest: ${auction.currentBid}',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              if (auction.bids.isEmpty)
                Text(
                  'No bids yet.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                )
              else
                for (final bid in auction.bids) ...[
                  _BidTile(bid: bid),
                  const SizedBox(height: 8),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sandSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BidTile extends StatelessWidget {
  const _BidTile({required this.bid});

  final SellerAuctionBid bid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sandSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                bid.amount,
                style: AppTypography.title.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (bid.isHighest) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Highest',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${bid.bidder} · ${bid.email}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            bid.at,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
