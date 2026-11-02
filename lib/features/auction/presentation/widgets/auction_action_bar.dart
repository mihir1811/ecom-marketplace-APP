import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/error/result.dart';
import '../../application/auction_providers.dart';
import '../../domain/models/auction_models.dart';
import 'auction_card.dart';
import 'auction_clock.dart';
import 'auction_seller_panel.dart';

/// Sticky auction actions. Replaces the product add-to-cart bar.
class AuctionActionBar extends ConsumerStatefulWidget {
  const AuctionActionBar({
    required this.auction,
    required this.auctionId,
    super.key,
  });

  final AuctionListing auction;
  final String auctionId;

  @override
  ConsumerState<AuctionActionBar> createState() => _AuctionActionBarState();
}

class _AuctionActionBarState extends ConsumerState<AuctionActionBar> {
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: _plusFive(widget.auction).toString());
  }

  @override
  void didUpdateWidget(covariant AuctionActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auction.currentBid != widget.auction.currentBid &&
        _amount.text == _plusFive(oldWidget.auction).toString()) {
      _amount.text = _plusFive(widget.auction).toString();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final auction = widget.auction;
    final auth = ref.watch(
      authProvider.select(
        (s) => (
          signedIn: s.isAuthenticated,
          userId: s.user?.id,
          sellerId: s.sellerId,
        ),
      ),
    );
    final submitting = ref.watch(
      auctionDetailProvider(widget.auctionId).select((s) => s.isSubmitting),
    );
    final myBidId = ref.watch(
      auctionDetailProvider(widget.auctionId).select((s) => s.myBidId),
    );
    final owns =
        auction.sellerId.isNotEmpty &&
        (auction.sellerId == auth.sellerId || auction.sellerId == auth.userId);
    final userId = auth.userId;
    final lapsed = userId != null && auction.declinedWinnerIds.contains(userId);
    final won = userId != null && !lapsed && auction.winnerId == userId;
    final suggestions = _suggestions(auction);
    final ownBidId = _ownBidId(auction, auth.userId, myBidId);

    Widget note(IconData icon, String text) => Row(
      children: [
        Icon(icon, size: 18, color: p.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: LuxeType.label(p.inkMuted, size: 13.5)),
        ),
      ],
    );

    final Widget content;
    if (owns) {
      content = AuctionSellerPanel(
        auction: auction,
        auctionId: widget.auctionId,
      );
    } else if (lapsed) {
      content = note(
        Icons.event_busy_outlined,
        'This win was declined or not paid within 24 hours.',
      );
    } else if (won) {
      // Rebuilds each second so the panel moves to "Time is up" on its own.
      content = ListenableBuilder(
        listenable: AuctionClock.instance,
        builder: (context, _) => _winnerPanel(auction, submitting, note),
      );
    } else if (!auction.isLive) {
      content = note(
        auction.isUpcoming ? Icons.schedule_rounded : Icons.lock_clock_outlined,
        auction.isUpcoming
            ? 'Bidding opens when the auction starts.'
            : 'This auction is closed.',
      );
    } else if (!auth.signedIn) {
      content = LuxeButton(
        label: 'Sign in to bid',
        icon: Icons.login_rounded,
        expand: true,
        onPressed: () => context.push(AppRouteNames.login),
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < suggestions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _SuggestionChip(
                    amount: auctionBidAmount(suggestions[i].amount),
                    label: suggestions[i].label,
                    selected: _amount.text == suggestions[i].amount.toString(),
                    onTap: submitting
                        ? null
                        : () {
                            AppHaptics.selection();
                            setState(() {
                              _amount.text = suggestions[i].amount.toString();
                            });
                          },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  style: LuxeType.figure(p.ink, size: 16),
                  decoration: const InputDecoration(
                    labelText: 'Your bid',
                    prefixText: r'$ ',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              LuxeButton(
                label: 'Place bid',
                icon: Icons.gavel_rounded,
                loading: submitting,
                onPressed: submitting ? null : _bid,
              ),
            ],
          ),
          if (ownBidId != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: submitting ? null : () => _cancel(ownBidId),
                style: TextButton.styleFrom(foregroundColor: p.caution),
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: Text(
                  'Cancel my bid',
                  style: LuxeType.label(p.caution, size: 12.5),
                ),
              ),
            ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.hairline, width: 0.6)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: AnimatedSize(
            duration: LuxeMotion.medium,
            curve: LuxeMotion.settle,
            alignment: Alignment.bottomCenter,
            child: content,
          ),
        ),
      ),
    );
  }

  /// Winner state: the win is paid from the cart at normal checkout.
  Widget _winnerPanel(
    AuctionListing auction,
    bool submitting,
    Widget Function(IconData icon, String text) note,
  ) {
    final p = LuxePalette.of(context);
    switch (auction.winPayment) {
      case AuctionWinPayment.paid:
        return note(Icons.verified_outlined, 'Payment complete');
      case AuctionWinPayment.withGemworld:
        return note(
          Icons.support_agent_outlined,
          'GemWorld is arranging the payment for this win with you.',
        );
      case AuctionWinPayment.expired:
        return note(
          Icons.timer_off_outlined,
          'Your 24 hours to pay have ended.',
        );
      case AuctionWinPayment.none:
        return note(
          Icons.emoji_events_outlined,
          'You won this auction. Waiting for the seller to confirm.',
        );
      case AuctionWinPayment.due:
        break;
    }
    final due = auction.paymentDueAt;
    final amount =
        auction.winningAmount ?? auction.highestBidAmount ?? auction.currentBid;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Winning bid', style: LuxeType.label(p.inkMuted, size: 12.5)),
            const SizedBox(width: 8),
            Text(
              auctionBidAmount(amount),
              style: LuxeType.figure(
                p.ink,
                size: 17,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        if (due != null) ...[
          const SizedBox(height: 4),
          Text(
            'Check out by ${auctionWhen(due)} '
            '(${auctionRemainingShort(due)} left)',
            style: LuxeType.label(p.ink, size: 13),
          ),
        ],
        const SizedBox(height: 2),
        Text(
          'Checkout adds the usual charges (GST, fees, delivery).',
          style: LuxeType.label(p.inkFaint, size: 11.5),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            LuxeButton(
              label: 'Decline win',
              variant: LuxeButtonVariant.secondary,
              onPressed: submitting ? null : _decline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LuxeButton(
                label: 'Go to checkout',
                icon: Icons.shopping_bag_outlined,
                expand: true,
                loading: submitting,
                onPressed: submitting ? null : _checkout,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _baseAmount(AuctionListing auction) {
    final highest = auction.highestBidAmount;
    if (highest == null) {
      final minimum = auction.minimumBid.ceil();
      return minimum < 1 ? 1 : minimum;
    }
    final whole = highest.round();
    return whole < 1 ? 1 : whole;
  }

  int _plusFive(AuctionListing auction) {
    final amount = _baseAmount(auction) + 5;
    return amount < 1 ? 1 : amount;
  }

  int _percentAbove(AuctionListing auction, int percent) {
    final amount = (_baseAmount(auction) * (100 + percent) / 100).ceil();
    return amount < 1 ? 1 : amount;
  }

  List<({int amount, String label})> _suggestions(AuctionListing auction) {
    return [
      (amount: _plusFive(auction), label: r'+$5'),
      (amount: _percentAbove(auction, 5), label: '+5%'),
      (amount: _percentAbove(auction, 10), label: '+10%'),
    ];
  }

  String? _ownBidId(AuctionListing auction, String? userId, String? stored) {
    if (stored != null && stored.isNotEmpty) return stored;
    if (userId == null || userId.isEmpty) return null;
    AuctionBid? mine;
    for (final bid in auction.bids) {
      if (bid.buyerId != userId) continue;
      final current = mine;
      if (current == null) {
        mine = bid;
        continue;
      }
      final bidAt = bid.createdAt;
      final currentAt = current.createdAt;
      if (bidAt != null && (currentAt == null || bidAt.isAfter(currentAt))) {
        mine = bid;
      }
    }
    return mine?.id;
  }

  Future<void> _bid() async {
    if (!AccountAccess.guard(context, ref)) return;
    final amount = int.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      _toast('Enter a whole-dollar bid.');
      return;
    }
    final confirmed = await _confirm(
      title: 'Place this bid?',
      message: 'You are about to bid ${auctionBidAmount(amount)}.',
      confirmLabel: 'Place bid',
    );
    if (!confirmed || !mounted) return;
    final message = await ref
        .read(auctionDetailProvider(widget.auctionId).notifier)
        .placeBid(amount.toDouble());
    _result(message);
  }

  Future<void> _cancel(String bidId) async {
    final confirmed = await _confirm(
      title: 'Cancel bid',
      message: 'Are you sure you want to cancel bid?',
      confirmLabel: 'Cancel bid',
    );
    if (!confirmed || !mounted) return;
    final message = await ref
        .read(auctionDetailProvider(widget.auctionId).notifier)
        .cancelBid(bidId);
    _result(message);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showAppDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => _popDialog(context, false),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => _popDialog(context, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _decline() async {
    AuctionSettings? settings;
    try {
      settings = await ref.read(auctionSettingsProvider.future);
    } catch (_) {
      // The confirm still shows without the numbers.
    }
    if (!mounted) return;
    final limit = settings?.winnerRejectWarningLimit ?? 0;
    final days = settings?.winnerRejectBlacklistDays ?? 0;
    final confirmed = await _confirm(
      title: 'Decline this win?',
      message: limit > 0 && days > 0
          ? 'You will receive a warning. After $limit declined wins you will '
                'be blacklisted from auctions for $days days.'
          : 'You will receive a warning.',
      confirmLabel: 'Decline win',
    );
    if (!confirmed || !mounted) return;
    final message = await ref
        .read(auctionDetailProvider(widget.auctionId).notifier)
        .declineWin();
    _result(message);
  }

  /// The win already sits in the cart; make sure it still does, then open
  /// the cart, where it checks out with the usual charges.
  Future<void> _checkout() async {
    if (!AccountAccess.guard(context, ref)) return;
    final result = await ref
        .read(auctionDetailProvider(widget.auctionId).notifier)
        .addWinToCart();
    if (!mounted) return;
    switch (result) {
      case Success():
        context.push(AppRouteNames.cart);
      case ResultFailure(:final failure):
        _toast(failure.message);
    }
  }

  void _result(String? message) {
    if (!mounted) return;
    if (message != null) {
      _toast(message);
      return;
    }
    final error = ref
        .read(auctionDetailProvider(widget.auctionId))
        .errorMessage;
    if (error != null) _toast(error);
  }

  /// Pops the dialog once; a second tap during the exit animation would
  /// otherwise pop the auction screen underneath.
  void _popDialog(BuildContext dialogContext, bool value) {
    final route = ModalRoute.of(dialogContext);
    if (route == null || !route.isCurrent) return;
    Navigator.pop(dialogContext, value);
  }

  void _toast(String message) {
    showLuxeToast(context, message, tone: LuxeTone.info);
  }
}

/// Quick-bid preset: amount over its rule ("+5%").
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.amount,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String amount;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$amount $label',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: LuxeMotion.medium,
          curve: LuxeMotion.settle,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? p.ink : p.surfaceRaised,
            borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
            border: Border.all(color: selected ? p.ink : p.hairline),
          ),
          child: Column(
            children: [
              Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuxeType.figure(
                  selected ? p.canvas : p.ink,
                  size: 13.5,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                label,
                style: LuxeType.label(
                  selected ? p.canvas : p.inkMuted,
                  size: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
