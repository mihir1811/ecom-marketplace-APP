import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../domain/live_format.dart';
import '../../domain/models/live_show_models.dart';

const _maxBid = 100000000;

/// Custom bid: whole rupees, at least `minNextBid`, nudged by the lot's
/// bid step. Returns the amount to send, or `null`.
Future<int?> showLiveBidSheet(
  BuildContext context, {
  required LiveAuctionLot lot,
  required int initial,
  double? freeToBid,
}) {
  return showLuxeSheet<int>(
    context,
    title: 'Your bid',
    subtitle: lot.title,
    builder: (_) =>
        _LiveBidSheet(lot: lot, initial: initial, freeToBid: freeToBid),
  );
}

/// First bid of a show: say once that bids are binding and a win pays from
/// the wallet on its own.
Future<bool?> confirmLiveBid(
  BuildContext context, {
  required int amount,
  required String lotTitle,
}) {
  return showLuxeSheet<bool>(
    context,
    title: 'Bid ${liveInr(amount)}?',
    subtitle: lotTitle,
    builder: (context) {
      final p = LuxePalette.of(context);
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (icon, text) in const [
              (
                Icons.lock_outline_rounded,
                'Held in your wallet while you lead; released if outbid.',
              ),
              (
                Icons.receipt_long_outlined,
                'A win pays automatically. No checkout step.',
              ),
              (
                Icons.gavel_rounded,
                'Bids are final. Late bids reset the clock to 10 s.',
              ),
            ]) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: p.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: LuxeType.body(p.inkMuted, size: 13.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 6),
            LuxeButton(
              label: 'Place bid',
              icon: Icons.gavel_rounded,
              variant: LuxeButtonVariant.accent,
              expand: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 6),
            LuxeButton(
              label: 'Not now',
              variant: LuxeButtonVariant.ghost,
              expand: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      );
    },
  );
}

class _LiveBidSheet extends StatefulWidget {
  const _LiveBidSheet({
    required this.lot,
    required this.initial,
    this.freeToBid,
  });

  final LiveAuctionLot lot;
  final int initial;
  final double? freeToBid;

  @override
  State<_LiveBidSheet> createState() => _LiveBidSheetState();
}

class _LiveBidSheetState extends State<_LiveBidSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.initial}',
  );

  int get _min => widget.lot.minNextBid.ceil();
  int get _step =>
      widget.lot.bidStep.ceil() <= 0 ? 1 : widget.lot.bidStep.ceil();

  int? get _amount => int.tryParse(_controller.text.replaceAll(',', '').trim());

  String? get _error {
    final a = _amount;
    if (a == null) return 'Enter a whole rupee amount.';
    if (a < _min) return 'The minimum bid is ${liveInr(_min)}.';
    if (a > _maxBid) return 'Bids go up to ${liveInr(_maxBid)}.';
    return null;
  }

  void _nudge(int by) {
    AppHaptics.selection();
    final next = ((_amount ?? _min) + by).clamp(_min, _maxBid);
    setState(() => _controller.text = '$next');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final error = _error;
    final amount = _amount;
    final free = widget.freeToBid;
    final short = free != null && amount != null && amount > free;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                label: 'Lower by ${liveInr(_step)}',
                onTap: (amount ?? _min) > _min ? () => _nudge(-_step) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: LuxeType.figure(p.ink, size: 30),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: LuxeType.figure(p.inkMuted, size: 22),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              _StepButton(
                icon: Icons.add_rounded,
                label: 'Raise by ${liveInr(_step)}',
                onTap: () => _nudge(_step),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            error ?? 'Minimum ${liveInr(_min)} · steps of ${liveInr(_step)}',
            textAlign: TextAlign.center,
            style: LuxeType.body(
              error != null ? p.caution : p.inkMuted,
              size: 13,
            ),
          ),
          if (free != null) ...[
            const SizedBox(height: 4),
            Text(
              short
                  ? 'Free to bid ${liveInr(free)}. You will be asked to add '
                        '${liveInr((amount - free).ceil())}.'
                  : 'Free to bid ${liveInr(free)}',
              textAlign: TextAlign.center,
              style: LuxeType.body(short ? p.caution : p.inkFaint, size: 12.5),
            ),
          ],
          const SizedBox(height: 18),
          LuxeButton(
            label: amount == null
                ? 'Place bid'
                : 'Place bid ${liveInr(amount)}',
            icon: Icons.gavel_rounded,
            variant: LuxeButtonVariant.accent,
            expand: true,
            onPressed: error == null
                ? () => Navigator.of(context).pop(amount)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Bids are binding. A win pays from your wallet automatically.',
            textAlign: TextAlign.center,
            style: LuxeType.body(p.inkFaint, size: 12),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.surfaceRaised,
            border: Border.all(color: p.hairline),
          ),
          child: Icon(icon, color: onTap == null ? p.inkFaint : p.ink),
        ),
      ),
    );
  }
}
