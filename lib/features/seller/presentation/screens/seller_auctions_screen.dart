import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../auction/application/auction_providers.dart';
import '../../../auction/data/repositories/auction_repository_impl.dart';
import '../../../auction/domain/models/auction_models.dart';
import '../../../auction/presentation/widgets/auction_card.dart';
import '../widgets/seller_auction_create_sheet.dart';

class SellerAuctionsScreen extends ConsumerStatefulWidget {
  const SellerAuctionsScreen({super.key});

  @override
  ConsumerState<SellerAuctionsScreen> createState() =>
      _SellerAuctionsScreenState();
}

class _SellerAuctionsScreenState extends ConsumerState<SellerAuctionsScreen> {
  String? _status;
  final Set<String> _expanded = {};
  final Map<String, List<AuctionBid>> _bids = {};
  final Set<String> _loadingBids = {};

  AuctionFeedQuery get _query =>
      AuctionFeedQuery(kind: AuctionFeedKind.seller, status: _status);

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(auctionFeedProvider(_query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              _header(context),
              const SizedBox(height: AppSpacing.s16),
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in const [
                    (null, 'All'),
                    ('active', 'Active'),
                    ('upcoming', 'Upcoming'),
                    ('ended', 'Ended'),
                  ])
                    ChoiceChip(
                      label: Text(entry.$2),
                      selected: _status == entry.$1,
                      onSelected: (_) => setState(() => _status = entry.$1),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              if (feed.isLoading && feed.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.s32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (feed.errorMessage != null && feed.items.isEmpty)
                CatalogEmptyState(
                  title: 'Auctions unavailable',
                  message: feed.errorMessage!,
                  actionLabel: 'Retry',
                  onAction: () =>
                      ref.read(auctionFeedProvider(_query).notifier).refresh(),
                )
              else if (feed.items.isEmpty)
                CatalogEmptyState(
                  title: context.tr(RemainingL10n.auctions),
                  message: context.tr(RemainingL10n.noAuctionsFilter),
                  icon: Icons.gavel_outlined,
                )
              else
                for (final auction in feed.items) ...[
                  _SellerAuctionCard(
                    auction: auction,
                    expanded: _expanded.contains(auction.id),
                    bids: _bids[auction.id],
                    loadingBids: _loadingBids.contains(auction.id),
                    onToggle: () => _toggle(auction.id),
                    onChanged: _refresh,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                ],
              if (feed.hasMore && feed.items.isNotEmpty)
                TextButton(
                  onPressed: feed.isLoadingMore
                      ? null
                      : () => ref
                            .read(auctionFeedProvider(_query).notifier)
                            .loadMore(),
                  child: Text(feed.isLoadingMore ? 'Loading…' : 'Load more'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(RemainingL10n.sellerAuctions),
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(RemainingL10n.manageYourLiveAuctionsViewAll),
            style: AppTypography.title,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final created = await showSellerAuctionCreateSheet(context);
              if (created && mounted) await _refresh();
            },
            icon: const Icon(Icons.add),
            label: const Text('Create auction'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(String id) async {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
        return;
      }
      _expanded.add(id);
    });
    if (_bids.containsKey(id) || !_expanded.contains(id)) return;
    setState(() => _loadingBids.add(id));
    final result = await ref.read(auctionRepositoryProvider).bids(id);
    if (!mounted) return;
    setState(() {
      _loadingBids.remove(id);
      if (result case Success(:final value)) {
        _bids[id] = value;
      }
    });
  }

  Future<void> _refresh() {
    return ref.read(auctionFeedProvider(_query).notifier).refresh();
  }
}

class _SellerAuctionCard extends ConsumerWidget {
  const _SellerAuctionCard({
    required this.auction,
    required this.expanded,
    required this.loadingBids,
    required this.onToggle,
    required this.onChanged,
    this.bids,
  });

  final AuctionListing auction;
  final bool expanded;
  final bool loadingBids;
  final List<AuctionBid>? bids;
  final VoidCallback onToggle;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
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
          const SizedBox(height: 6),
          Text(auction.title, style: AppTypography.title),
          Text(
            '${auction.productType} · ${AppCurrency.usd(auction.currentBid)}',
            style: AppTypography.caption,
          ),
          if (auction.endTime != null)
            Text(
              'Ends ${auctionWhen(auction.endTime!)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () =>
                    context.push(AppRouteNames.auctionDetailPath(auction.id)),
                child: const Text('Open'),
              ),
              TextButton(onPressed: onToggle, child: const Text('Bids')),
              if (auction.isLive)
                TextButton(
                  onPressed: () => _act(
                    context,
                    ref,
                    () => ref.read(auctionRepositoryProvider).end(auction.id),
                  ),
                  child: const Text('End'),
                ),
              if (auction.awaitingSellerDecision)
                TextButton(
                  onPressed: () => _act(
                    context,
                    ref,
                    () => ref.read(auctionRepositoryProvider).accept(
                      auctionId: auction.id,
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              if (auction.awaitingSellerDecision || auction.isEnded)
                TextButton(
                  onPressed: () => _reject(context, ref),
                  child: const Text('Reject'),
                ),
              if (!auction.isSold)
                TextButton(
                  onPressed: () => _act(
                    context,
                    ref,
                    () => ref.read(auctionRepositoryProvider).delete(auction.id),
                  ),
                  child: const Text('Delete'),
                ),
            ],
          ),
          if (expanded) ...[
            const Divider(),
            if (loadingBids)
              const LinearProgressIndicator()
            else if (bids == null || bids!.isEmpty)
              const Text('No bids yet.')
            else
              for (final bid in bids!)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppCurrency.usd(bid.amount)),
                  subtitle: Text(bid.buyerName ?? bid.buyerId),
                  trailing: auction.awaitingSellerDecision
                      ? TextButton(
                          onPressed: () => _act(
                            context,
                            ref,
                            () => ref
                                .read(auctionRepositoryProvider)
                                .selectWinner(
                                  auctionId: auction.id,
                                  bidderId: bid.buyerId,
                                ),
                          ),
                          child: const Text('Select'),
                        )
                      : null,
                ),
          ],
        ],
      ),
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject outcome'),
        content: const Text('Restart the auction or remove the listing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'remove'),
            child: const Text('Remove'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'restart'),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    DateTime? start;
    DateTime? end;
    if (action == 'restart') {
      final now = DateTime.now();
      start = now.add(const Duration(minutes: 5));
      end = now.add(const Duration(days: 7));
    }
    await _act(
      context,
      ref,
      () => ref.read(auctionRepositoryProvider).reject(
        auctionId: auction.id,
        action: action,
        startTime: start,
        endTime: end,
        minimumBid: auction.minimumBid,
        reservePrice: auction.reservePrice,
      ),
    );
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    Future<Result<AuctionMutation, Failure>> Function() call,
  ) async {
    final result = await call();
    if (!context.mounted) return;
    final message = switch (result) {
      Success(:final value) => value.message,
      ResultFailure(:final failure) => failure.message,
    };
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
    if (result is Success) await onChanged();
  }
}
