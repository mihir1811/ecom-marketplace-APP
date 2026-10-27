/// Rupee and count formatting for live shows.
library;

/// `₹1,52,000` (Indian grouping); paise shown only when present.
String liveInr(num amount) {
  final whole = amount == amount.roundToDouble();
  final fixed = amount.abs().toStringAsFixed(whole ? 0 : 2);
  final parts = fixed.split('.');
  final digits = parts.first;
  var grouped = digits;
  if (digits.length > 3) {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final chunks = <String>[];
    while (rest.length > 2) {
      chunks.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) chunks.insert(0, rest);
    grouped = '${chunks.join(',')},$last3';
  }
  final sign = amount < 0 ? '-' : '';
  final paise = parts.length > 1 ? '.${parts[1]}' : '';
  return '$sign₹$grouped$paise';
}

/// `1.2K` style viewer counts.
String liveCount(int n) {
  if (n < 1000) return '$n';
  if (n < 100000) {
    final k = n / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
  }
  final l = n / 100000;
  return '${l.toStringAsFixed(l >= 10 ? 0 : 1)}L';
}

/// `09:41` / `1:02:05` for a countdown.
String liveClock(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}
