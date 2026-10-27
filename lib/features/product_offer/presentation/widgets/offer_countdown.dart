import 'dart:async';

import 'package:flutter/widgets.dart';

/// Short "time left" label for the 24-hour offer clocks, e.g. `23h 05m`,
/// `42m`, `<1m`.
String formatOfferTimeLeft(Duration left) {
  if (left <= Duration.zero) return '0m';
  final hours = left.inHours;
  final minutes = left.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  if (left.inMinutes > 0) return '${left.inMinutes}m';
  return '<1m';
}

/// Rebuilds every [interval] with the time left until [expiresAt], and calls
/// [onExpired] once when it runs out.
class OfferCountdown extends StatefulWidget {
  const OfferCountdown({
    required this.expiresAt,
    required this.builder,
    this.onExpired,
    this.interval = const Duration(seconds: 30),
    super.key,
  });

  final DateTime? expiresAt;
  final Widget Function(BuildContext context, Duration left) builder;
  final VoidCallback? onExpired;
  final Duration interval;

  @override
  State<OfferCountdown> createState() => _OfferCountdownState();
}

class _OfferCountdownState extends State<OfferCountdown> {
  Timer? _timer;
  bool _expiredFired = false;

  Duration get _left {
    final expires = widget.expiresAt;
    if (expires == null) return Duration.zero;
    final left = expires.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(OfferCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _expiredFired = false;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    if (widget.expiresAt == null) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() {});
      if (_left == Duration.zero && !_expiredFired) {
        _expiredFired = true;
        _timer?.cancel();
        widget.onExpired?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _left);
}
