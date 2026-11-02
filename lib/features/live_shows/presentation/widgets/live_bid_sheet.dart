import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../domain/live_format.dart';
import '../../domain/models/live_show_models.dart';
import 'live_sheet.dart';
import 'live_stage_tokens.dart';

const _maxBid = 100000000;

/// Exact-amount pad for the bid: whole rupees, at least `minNextBid`,
/// nudged by the lot's step. Returns the amount to put in the dock (the
/// slider then places it), or `null`.
Future<int?> showLiveBidSheet(
  BuildContext context, {
  required LiveAuctionLot lot,
  required int initial,
  double? freeToBid,
}) {
  return showLiveSheet<int>(
    context,
    title: 'Custom bid',
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
    final error = _error;
    final amount = _amount;
    final free = widget.freeToBid;
    final short = free != null && amount != null && amount > free;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: LiveStage.ink.withValues(alpha: 0.04),
              border: Border.all(
                color: error != null || short
                    ? LiveStage.urgent.withValues(alpha: 0.5)
                    : LiveStage.champagne.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                Text('ENTER AMOUNT', style: LiveType.eyebrow()),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _Step(
                      icon: Icons.remove_rounded,
                      label: 'Lower by ${liveInr(_step)}',
                      onTap: (amount ?? _min) > _min
                          ? () => _nudge(-_step)
                          : null,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        cursorColor: LiveStage.champagne,
                        style: LiveType.display(
                          44,
                          color: short || error != null
                              ? LiveStage.urgent
                              : LiveStage.champagne,
                        ),
                        decoration: InputDecoration(
                          prefixText: '₹',
                          prefixStyle: LiveType.display(
                            30,
                            color: LiveStage.inkFaint,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    _Step(
                      icon: Icons.add_rounded,
                      label: 'Raise by ${liveInr(_step)}',
                      onTap: () => _nudge(_step),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: LiveMotion.quick,
                  child: Text(
                    error ??
                        'Minimum ${liveInr(_min)} · steps of ${liveInr(_step)}',
                    key: ValueKey(error),
                    textAlign: TextAlign.center,
                    style: LiveType.body(
                      12.5,
                      color: error != null
                          ? LiveStage.urgent
                          : LiveStage.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (i, (label, value)) in [
                ('Min', _min),
                if (widget.lot.bidStep.ceil() > 0) ('+1 step', _min + _step),
                if (widget.lot.bidStep.ceil() > 0)
                  ('+2 steps', _min + _step * 2),
                if (widget.lot.bidStep.ceil() > 0)
                  ('+5 steps', _min + _step * 5),
              ].indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _Pick(
                    hint: label,
                    label: liveInr(value),
                    selected: amount == value,
                    short: free != null && value > free,
                    onTap: () {
                      AppHaptics.selection();
                      setState(() => _controller.text = '$value');
                    },
                  ),
                ),
              ],
            ],
          ),
          if (free != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  short
                      ? Icons.error_outline_rounded
                      : Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: short ? LiveStage.urgent : LiveStage.inkMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    short
                        ? 'Free to bid ${liveInr(free)}. Add '
                              '${liveInr((amount - free).ceil())} to your '
                              'wallet to bid this much.'
                        : 'Free to bid ${liveInr(free)}',
                    style: LiveType.body(
                      12.5,
                      color: short ? LiveStage.ink : LiveStage.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          LiveButton(
            label: amount == null ? 'Set bid' : 'Set bid ${liveInr(amount)}',
            icon: Icons.check_rounded,
            onTap: error == null
                ? () => Navigator.of(context).pop(amount)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            'You confirm by sliding. Bids are binding: the amount is held in '
            'your wallet while you lead, and a win pays automatically.',
            textAlign: TextAlign.center,
            style: LiveType.body(11.5, color: LiveStage.inkFaint),
          ),
        ],
      ),
    );
  }
}

class _Pick extends StatelessWidget {
  const _Pick({
    required this.hint,
    required this.label,
    required this.selected,
    required this.short,
    required this.onTap,
  });

  final String hint;
  final String label;
  final bool selected;
  final bool short;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: LivePressable(
        haptic: false,
        semanticLabel: '$hint, $label',
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: LiveMotion.ease,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? LiveStage.champagne.withValues(alpha: 0.14)
                : LiveStage.ink.withValues(alpha: 0.04),
            border: Border.all(
              color: selected
                  ? LiveStage.champagne.withValues(alpha: 0.8)
                  : LiveStage.hairline,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: LiveType.figure(
                    13,
                    color: short
                        ? LiveStage.inkFaint
                        : (selected ? LiveStage.champagne : LiveStage.ink),
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Text(hint, style: LiveType.body(10, color: LiveStage.inkFaint)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LiveIconButton(icon: icon, tooltip: label, onTap: onTap, size: 46)
        .animate(target: onTap == null ? 0 : 1)
        .fade(begin: 0.35, end: 1, duration: LiveMotion.quick);
  }
}
