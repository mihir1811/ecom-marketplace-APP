import 'package:flutter/material.dart';

import '../domain/models/auction_models.dart';
import 'widgets/auction_card.dart';

/// One status line for the seller: where the accepted winner's cart payment
/// stands, or what the finished auction is waiting on.
typedef AuctionSellerOutcome = ({IconData icon, String text, bool done});

/// Seller-facing outcome of a finished auction (app API guide, "Seller
/// screens"). Null while the auction has nothing to report.
AuctionSellerOutcome? auctionSellerOutcome(AuctionListing a) {
  switch (a.winPayment) {
    case AuctionWinPayment.paid:
      return (
        icon: Icons.verified_rounded,
        text: 'Paid by the winner. Ship it from your orders.',
        done: true,
      );
    case AuctionWinPayment.withGemworld:
      return (
        icon: Icons.support_agent_outlined,
        text: 'Awaiting payment: GemWorld is arranging it with the winner.',
        done: false,
      );
    case AuctionWinPayment.due:
    case AuctionWinPayment.expired:
      final due = a.paymentDueAt;
      return (
        icon: Icons.hourglass_top_rounded,
        text: due == null
            ? 'Awaiting payment from the winner.'
            : 'Awaiting payment: the winner has until ${auctionWhen(due)} '
                  'to check out, or the item comes back to you.',
        done: false,
      );
    case AuctionWinPayment.none:
      if (a.awaitingSellerDecision && a.declinedWinnerIds.isNotEmpty) {
        final next = a.eligibleBids().firstOrNull;
        return (
          icon: Icons.replay_rounded,
          text: next == null
              ? 'The last winner declined or didn’t pay in time, and no '
                    'other bidders remain. Restart or remove the auction.'
              : 'The last winner declined or didn’t pay in time. Accept the '
                    'next bidder (${auctionBidAmount(next.amount)}), restart '
                    'or remove the auction.',
          done: false,
        );
      }
      if (a.awaitingSellerDecision) {
        final reserve = a.reservePrice;
        return (
          icon: Icons.gavel_rounded,
          text: a.highestBidAmount == null
              ? 'Ended without bids. Relist it or remove the listing.'
              : reserve != null && !a.isReserveMet
              ? 'Ended below your reserve of ${auctionBidAmount(reserve)}. '
                    'Accept the highest bid, pick another bidder or reject.'
              : 'Bidding closed. Accept the highest bid, pick another bidder '
                    'or reject.',
          done: false,
        );
      }
      return null;
  }
}

/// Start and end used when the seller restarts a rejected auction.
({DateTime start, DateTime end}) auctionRestartWindow() {
  final now = DateTime.now();
  return (
    start: now.add(const Duration(minutes: 5)),
    end: now.add(const Duration(days: 7)),
  );
}
