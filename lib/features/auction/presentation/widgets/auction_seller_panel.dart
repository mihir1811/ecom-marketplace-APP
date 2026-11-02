import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../application/auction_providers.dart';
import '../../domain/models/auction_models.dart';
import '../auction_seller_outcome.dart';
import 'auction_card.dart';

/// The seller's own auction: end it early while live, then decide once
/// bidding closes (accept the highest or another bidder, or reject to
/// restart or remove), then follow the winner's cart payment.
class AuctionSellerPanel extends ConsumerWidget {
  const AuctionSellerPanel({
    required this.auction,
    required this.auctionId,
    super.key,
  });

  final AuctionListing auction;
  final String auctionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final a = auction;
    final submitting = ref.watch(
      auctionDetailProvider(auctionId).select((s) => s.isSubmitting),
    );
    final actions = _SellerActions(context, ref, a, auctionId);

    Widget note(IconData icon, String text, {Color? color}) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color ?? p.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: LuxeType.label(p.inkMuted, size: 13.5)),
        ),
      ],
    );

    if (a.isLive) {
      return Row(
        children: [
          Expanded(
            child: note(
              Icons.storefront_outlined,
              'Your auction is live. When bidding closes you decide whether '
              'to sell.',
            ),
          ),
          const SizedBox(width: 10),
          LuxeButton(
            label: 'End now',
            icon: Icons.stop_circle_outlined,
            variant: LuxeButtonVariant.secondary,
            loading: submitting,
            onPressed: submitting ? null : actions.end,
          ),
        ],
      );
    }

    if (a.isUpcoming) {
      return note(
        Icons.schedule_rounded,
        a.startTime == null
            ? 'Your auction has not started yet.'
            : 'Your auction starts ${auctionWhen(a.startTime!)}.',
      );
    }

    final outcome = auctionSellerOutcome(a);

    if (a.awaitingSellerDecision) {
      final eligible = a.eligibleBids();
      final next = eligible.firstOrNull;
      final hasDeclined = a.declinedWinnerIds.isNotEmpty;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your decision',
            style: LuxeType.label(
              p.ink,
              size: 13,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (outcome != null) note(outcome.icon, outcome.text),
          if (next != null) ...[
            const SizedBox(height: 6),
            Text(
              '${hasDeclined ? 'Next bidder' : 'Highest bid'}: '
              '${next.buyerName ?? 'Bidder'} · ${auctionBidAmount(next.amount)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LuxeType.label(p.ink, size: 13),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              LuxeButton(
                label: a.highestBidAmount == null ? 'Relist' : 'Reject',
                variant: LuxeButtonVariant.secondary,
                onPressed: submitting ? null : actions.reject,
              ),
              if (next != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: LuxeButton(
                    label: hasDeclined
                        ? 'Accept next bidder'
                        : 'Accept ${auctionBidAmount(next.amount)}',
                    icon: Icons.handshake_outlined,
                    expand: true,
                    loading: submitting,
                    onPressed: submitting ? null : () => actions.accept(next),
                  ),
                ),
              ],
            ],
          ),
          if (eligible.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: submitting
                    ? null
                    : () => actions.chooseBidder(eligible),
                icon: const Icon(Icons.people_outline_rounded, size: 16),
                label: Text(
                  'Choose another bidder',
                  style: LuxeType.label(p.accent, size: 12.5),
                ),
              ),
            ),
        ],
      );
    }

    if (a.winPayment != AuctionWinPayment.none) {
      final amount = a.winningAmount ?? a.highestBidAmount ?? a.currentBid;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sold to ${a.winnerName ?? 'the winner'} · '
            '${auctionBidAmount(amount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LuxeType.label(
              p.ink,
              size: 13.5,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          if (outcome != null) ...[
            const SizedBox(height: 6),
            note(
              outcome.icon,
              outcome.text,
              color: outcome.done ? p.positive : p.accent,
            ),
          ],
        ],
      );
    }

    if (a.isActive && a.isEnded) {
      // Ended by the clock; the backend closes it for review within a
      // minute and the socket update reloads this screen.
      return note(
        Icons.hourglass_top_rounded,
        'Bidding has closed. Your decision opens in a moment.',
      );
    }

    return note(Icons.lock_clock_outlined, switch (a.closureStatus
        .toUpperCase()) {
      'ENDED_NO_BIDS' => 'Your auction ended without bids.',
      'REMOVED' => 'You removed this auction listing.',
      _ => 'This auction is closed.',
    });
  }
}

/// Seller mutations from the detail screen, each confirmed first.
class _SellerActions {
  _SellerActions(this.context, this.ref, this.auction, this.auctionId);

  final BuildContext context;
  final WidgetRef ref;
  final AuctionListing auction;
  final String auctionId;

  AuctionDetailNotifier get _notifier =>
      ref.read(auctionDetailProvider(auctionId).notifier);

  Future<void> end() async {
    final ok = await _confirm(
      title: 'End this auction now?',
      message:
          'Bidding on ${auction.title} closes immediately at the current '
          'price of ${auctionBidAmount(auction.currentBid)}. You then decide '
          'whether to sell.',
      confirmLabel: 'End auction',
    );
    if (!ok || !context.mounted) return;
    _done(await _notifier.endAuction());
  }

  Future<void> accept(AuctionBid bid) async {
    final reserve = auction.reservePrice;
    final below = reserve != null && bid.amount < reserve;
    final ok = await _confirm(
      title: 'Sell to this bidder?',
      message:
          '${bid.buyerName ?? 'This bidder'} wins ${auction.title} at '
          '${auctionBidAmount(bid.amount)}'
          '${below ? ', below your reserve of ${auctionBidAmount(reserve)}' : ''}. '
          'It goes into their cart and they have 24 hours to pay, or it '
          'comes back to you.',
      confirmLabel: 'Accept',
    );
    if (!ok || !context.mounted) return;
    _done(await _notifier.accept(bidId: bid.id));
  }

  Future<void> chooseBidder(List<AuctionBid> eligible) async {
    final bid = await showLuxeSheet<AuctionBid>(
      context,
      title: 'Choose a bidder',
      subtitle: 'They get the item in their cart at their bid.',
      builder: (sheetContext) {
        final p = LuxePalette.of(sheetContext);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < eligible.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: i == 0 ? p.accentSoft : p.surfaceRaised,
                  child: Text(
                    '${i + 1}',
                    style: LuxeType.figure(p.ink, size: 12),
                  ),
                ),
                title: Text(
                  eligible[i].buyerName ?? 'Bidder',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(p.ink, size: 14),
                ),
                subtitle: eligible[i].createdAt == null
                    ? null
                    : Text(
                        auctionWhen(eligible[i].createdAt!),
                        style: LuxeType.label(p.inkFaint, size: 11.5),
                      ),
                trailing: Text(
                  auctionBidAmount(eligible[i].amount),
                  style: LuxeType.figure(p.ink, size: 15),
                ),
                onTap: () => Navigator.of(sheetContext).pop(eligible[i]),
              ),
          ],
        );
      },
    );
    if (bid == null || !context.mounted) return;
    await accept(bid);
  }

  Future<void> reject() async {
    final action = await showLuxeSheet<String>(
      context,
      title: 'Reject outcome',
      subtitle: auction.title,
      builder: (sheetContext) {
        final p = LuxePalette.of(sheetContext);
        Widget option(String value, IconData icon, String label, String hint) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: p.ink),
            title: Text(label, style: LuxeType.label(p.ink, size: 14)),
            subtitle: Text(hint, style: LuxeType.label(p.inkFaint, size: 12)),
            onTap: () => Navigator.of(sheetContext).pop(value),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            option(
              'restart',
              Icons.restart_alt_rounded,
              'Restart auction',
              'Relists in 5 minutes for 7 days with the same bid floor',
            ),
            option(
              'remove',
              Icons.remove_circle_outline_rounded,
              'Remove listing',
              'Takes the item off auction',
            ),
          ],
        );
      },
    );
    if (action == null || !context.mounted) return;
    if (action == 'remove') {
      final ok = await _confirm(
        title: 'Remove this listing?',
        message: '${auction.title} comes off auction. Bids are not accepted.',
        confirmLabel: 'Remove',
      );
      if (!ok || !context.mounted) return;
    }
    final window = action == 'restart' ? auctionRestartWindow() : null;
    _done(
      await _notifier.reject(
        action: action,
        startTime: window?.start,
        endTime: window?.end,
        minimumBid: auction.minimumBid,
        reservePrice: auction.reservePrice,
      ),
    );
  }

  /// Toasts the backend message; on success the seller lists reload too.
  void _done(String? message) {
    if (!context.mounted) return;
    if (message != null) {
      AppHaptics.success();
      ref.invalidate(sellerAuctionStandingProvider);
      showLuxeToast(context, message, tone: LuxeTone.success);
      return;
    }
    final error = ref.read(auctionDetailProvider(auctionId)).errorMessage;
    if (error != null) {
      AppHaptics.error();
      showLuxeToast(context, error, tone: LuxeTone.error);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) {
        void close(bool value) {
          // A second tap during the exit animation would pop the screen.
          final route = ModalRoute.of(dialogContext);
          if (route == null || !route.isCurrent) return;
          Navigator.pop(dialogContext, value);
        }

        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => close(false),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => close(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
