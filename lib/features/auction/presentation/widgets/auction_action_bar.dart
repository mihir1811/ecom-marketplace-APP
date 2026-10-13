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
import '../../../payment/presentation/payment_flow.dart';
import '../../../rewards/application/rewards_provider.dart';
import '../../../rewards/presentation/rewards_format.dart';
import '../../application/auction_providers.dart';
import '../../domain/models/auction_models.dart';
import 'auction_card.dart';

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
    final won =
        auth.userId != null &&
        auction.winnerId == auth.userId &&
        !_paid(auction.winnerStatus);
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
      content = note(Icons.storefront_outlined, 'This is your auction.');
    } else if (won) {
      content = Row(
        children: [
          LuxeButton(
            label: 'Decline win',
            variant: LuxeButtonVariant.secondary,
            onPressed: submitting ? null : _decline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LuxeButton(
              label: 'Pay',
              icon: Icons.lock_outline_rounded,
              expand: true,
              loading: submitting,
              onPressed: submitting ? null : _pay,
            ),
          ),
        ],
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

  bool _paid(String? status) {
    final value = status?.toUpperCase() ?? '';
    return value == 'PAID' || value == 'CAPTURED' || value == 'COMPLETED';
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
    final message = await ref
        .read(auctionDetailProvider(widget.auctionId).notifier)
        .declineWin();
    _result(message);
  }

  Future<void> _pay() async {
    if (PaymentFlow.isActive) return;
    if (!AccountAccess.guard(context, ref)) return;
    var useWallet = false;
    var usePoints = false;
    final proceed = await showAppDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Pay for this win'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final rewards = ref.watch(rewardsProvider).valueOrNull;
                      final settings = rewards?.settings;
                      if (rewards == null ||
                          settings == null ||
                          !settings.canRedeem ||
                          rewards.balance <= 0) {
                        return const SizedBox.shrink();
                      }
                      final locked = !rewards.canSpend;
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: usePoints && !locked,
                        title: const Text('Use reward points'),
                        subtitle: Text(
                          locked
                              ? 'Collect at least '
                                    '${rewardPointsLabel(settings.minRedeemPoints)} '
                                    'to use them'
                              : 'Balance ${rewardPointsLabel(rewards.balance)} · '
                                    'up to '
                                    '${rewardPercentLabel(settings.maxRedeemPercent)} '
                                    'of the total',
                        ),
                        onChanged: locked
                            ? null
                            : (value) =>
                                  setLocal(() => usePoints = value ?? false),
                      );
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: useWallet,
                    title: const Text('Use wallet balance'),
                    onChanged: (value) =>
                        setLocal(() => useWallet = value ?? false),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => _popDialog(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => _popDialog(context, true),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
    if (proceed != true || !mounted) return;
    final auction = widget.auction;
    final amount = auction.highestBidAmount ?? auction.currentBid;
    final notifier = ref.read(auctionDetailProvider(widget.auctionId).notifier);
    await PaymentFlow.run(
      context,
      summary: PurchaseSummary(
        item: auction.title.isEmpty ? 'Auction win' : auction.title,
        method: usePoints || useWallet
            ? '${[if (usePoints) 'Reward points', if (useWallet) 'Wallet'].join(' + ')}'
                  ' (Razorpay for any balance)'
            : 'Razorpay',
        amount: auctionBidAmount(amount),
      ),
      process: () => notifier.pay(useWallet: useWallet, usePoints: usePoints),
      successMessage: (message) => message,
    );
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
