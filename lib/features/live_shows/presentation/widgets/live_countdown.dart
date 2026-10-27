import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/live_format.dart';
import 'live_stage_tokens.dart';

/// Lot countdown on the server's clock, redrawn 4 times a second. Red
/// under 10 s; "Closing…" at 0 until the result push lands.
class LiveCountdown extends StatefulWidget {
  const LiveCountdown({
    required this.endsAt,
    required this.serverNow,
    super.key,
    this.large = false,
  });

  final DateTime? endsAt;
  final DateTime Function() serverNow;
  final bool large;

  @override
  State<LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<LiveCountdown> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ends = widget.endsAt;
    final left = ends == null
        ? Duration.zero
        : ends.difference(widget.serverNow());
    final closing = ends != null && left <= Duration.zero;
    final urgent = !closing && left < const Duration(seconds: 10);
    final label = ends == null
        ? '--:--'
        : closing
        ? 'Closing…'
        : liveClock(left + const Duration(milliseconds: 999));
    final color = urgent || closing ? LiveStage.urgent : Colors.white;
    return Semantics(
      liveRegion: urgent,
      label: closing ? 'Closing' : 'Time left $label',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: widget.large ? 12 : 9,
          vertical: widget.large ? 7 : 5,
        ),
        decoration: BoxDecoration(
          color: urgent || closing
              ? LiveStage.urgent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: urgent || closing
                ? LiveStage.urgent.withValues(alpha: 0.7)
                : LiveStage.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: widget.large ? 16 : 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: widget.large ? 16 : 13,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
