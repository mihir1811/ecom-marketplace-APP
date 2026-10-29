/// Caps how many model-backed turns one app session may start, so a stuck
/// input, a script or an abusive user cannot run up model costs. Turns the
/// local router answers are free and never counted.
///
/// This is a client-side courtesy limit; the proxy / backend must enforce
/// its own per-user quota as well.
class TurnLimiter {
  TurnLimiter({
    this.perMinute = 10,
    this.perDay = 200,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int perMinute;
  final int perDay;
  final DateTime Function() _clock;
  final List<DateTime> _turns = [];

  /// Records a turn and returns true, or returns false when over a limit.
  bool tryAcquire() {
    final now = _clock();
    _turns.removeWhere((t) => now.difference(t) > const Duration(days: 1));
    final lastMinute = _turns
        .where((t) => now.difference(t) < const Duration(minutes: 1))
        .length;
    if (lastMinute >= perMinute || _turns.length >= perDay) return false;
    _turns.add(now);
    return true;
  }

  void reset() => _turns.clear();
}
