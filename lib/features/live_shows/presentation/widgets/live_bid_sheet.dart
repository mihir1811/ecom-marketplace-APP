import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../domain/live_format.dart';
import '../../domain/models/live_show_models.dart';

const _maxBid = 100000000;

/// Number pad for the bid box: whole rupees, at least `minNextBid`, nudged
/// by the lot's bid step. Returns the amount to put in the box (the slider
/// then places it), or `null`.
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
                  ? 'Free to bid ${liveInr(free)}. Add '
                        '${liveInr((amount - free).ceil())} to your wallet '
                        'to bid this much.'
                  : 'Free to bid ${liveInr(free)}',
              textAlign: TextAlign.center,
              style: LuxeType.body(short ? p.caution : p.inkFaint, size: 12.5),
            ),
          ],
          const SizedBox(height: 18),
          LuxeButton(
            label: amount == null ? 'Set bid' : 'Set bid ${liveInr(amount)}',
            icon: Icons.check_rounded,
            variant: LuxeButtonVariant.accent,
            expand: true,
            onPressed: error == null
                ? () => Navigator.of(context).pop(amount)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Then slide to bid. Bids are binding.',
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
