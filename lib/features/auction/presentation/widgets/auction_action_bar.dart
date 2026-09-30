import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../application/auction_providers.dart';
import '../../domain/models/auction_models.dart';

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
    _amount = TextEditingController(
      text: _nextAmount(widget.auction).toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(covariant AuctionActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auction.currentBid != widget.auction.currentBid &&
        _amount.text == _nextAmount(oldWidget.auction).toStringAsFixed(2)) {
      _amount.text = _nextAmount(widget.auction).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final owns = auction.sellerId.isNotEmpty &&
        (auction.sellerId == auth.sellerId || auction.sellerId == auth.userId);
    final won =
        auth.userId != null &&
        auction.winnerId == auth.userId &&
        !_paid(auction.winnerStatus);

    return Material(
      color: AppColors.surface(context),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s12,
            AppSpacing.s16,
            AppSpacing.s12,
          ),
          child: owns
              ? const Text('This is your auction.')
              : won
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: submitting ? null : _decline,
                        child: const Text('Decline win'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: FilledButton(
                        onPressed: submitting ? null : _pay,
                        child: const Text('Pay'),
                      ),
                    ),
                  ],
                )
              : !auction.isLive
              ? Text(
                  auction.isUpcoming
                      ? 'Bidding opens when the auction starts.'
                      : 'This auction is closed.',
                )
              : !auth.signedIn
              ? FilledButton(
                  onPressed: () => context.push(AppRouteNames.login),
                  child: const Text('Sign in to bid'),
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Bid',
                          prefixText: r'$',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: FilledButton(
                        onPressed: submitting ? null : _bid,
                        child: const Text('Place bid'),
                      ),
                    ),
                    if (myBidId != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Cancel bid',
                        onPressed: submitting ? null : () => _cancel(myBidId),
                        icon: const Icon(Icons.undo),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  double _nextAmount(AuctionListing auction) {
    final base = auction.highestBidAmount ?? auction.minimumBid;
    if (auction.highestBidAmount == null) return base;
    return base + 1;
  }

  bool _paid(String? status) {
    final value = status?.toUpperCase() ?? '';
    return value == 'PAID' || value == 'CAPTURED' || value == 'COMPLETED';
  }

  Future<void> _bid() async {
    if (!AccountAccess.guard(context, ref)) return;
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      _toast('Enter a bid amount.');
      return;
    }
    final confirmed = await _confirm(
      title: 'Place this bid?',
      message: 'You are about to bid ${AppCurrency.usd(amount)}.',
      confirmLabel: 'Place bid',
    );
    if (!confirmed || !mounted) return;
    final message = await ref
        .read(auctionDetailProvider(widget.auctionId).notifier)
        .placeBid(amount);
    _result(message);
  }

  Future<void> _cancel(String bidId) async {
    final confirmed = await _confirm(
      title: 'Cancel this bid?',
      message: 'Your highest bid will be withdrawn if the auction is still open.',
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
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
    if (!AccountAccess.guard(context, ref)) return;
    var useWallet = false;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Pay for this win'),
              content: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: useWallet,
                title: const Text('Use wallet balance'),
                onChanged: (value) => setLocal(() => useWallet = value ?? false),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
    if (proceed != true || !mounted) return;
    final message = await ref
        .read(auctionDetailProvider(widget.auctionId).notifier)
        .pay(useWallet: useWallet);
    _result(message);
  }

  void _result(String? message) {
    if (!mounted) return;
    if (message != null) {
      _toast(message);
      return;
    }
    final error = ref.read(auctionDetailProvider(widget.auctionId)).errorMessage;
    if (error != null) _toast(error);
  }

  void _toast(String message) {
    AppHaptics.medium();
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
