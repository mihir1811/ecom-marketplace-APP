import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../domain/models/auction_models.dart';

/// One shared one-second tick for every auction countdown on screen.
///
/// The timer only runs while something listens, so a list of 40 cards
/// costs one timer instead of 40, and only the countdown text rebuilds.
class AuctionClock extends ChangeNotifier {
  AuctionClock._();

  static final AuctionClock instance = AuctionClock._();

  Timer? _timer;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _timer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

/// "2d 04h 12m 09s"; "Ended" once past.
String auctionRemaining(DateTime deadline) {
  final diff = deadline.difference(DateTime.now());
  if (diff.isNegative) return 'Ended';
  final days = diff.inDays;
  final hours = diff.inHours.remainder(24);
  final minutes = diff.inMinutes.remainder(60);
  final seconds = diff.inSeconds.remainder(60);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${days}d ${two(hours)}h ${two(minutes)}m ${two(seconds)}s';
}

/// Short form for cards: "2d 4h", "3h 12m", "8m 05s".
String auctionRemainingShort(DateTime deadline) {
  final diff = deadline.difference(DateTime.now());
  if (diff.isNegative) return 'Ended';
  String two(int n) => n.toString().padLeft(2, '0');
  if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours.remainder(24)}h';
  if (diff.inHours > 0) {
    return '${diff.inHours}h ${two(diff.inMinutes.remainder(60))}m';
  }
  return '${diff.inMinutes}m ${two(diff.inSeconds.remainder(60))}s';
}

/// The deadline a countdown should track: start for upcoming, end otherwise.
DateTime? auctionDeadline(AuctionListing a) =>
    a.isUpcoming ? a.startTime : a.endTime;

/// Live countdown text driven by [AuctionClock]; rebuilds only itself.
class AuctionCountdown extends StatelessWidget {
  const AuctionCountdown({
    required this.deadline,
    required this.style,
    super.key,
    this.short = false,
  });

  final DateTime deadline;
  final TextStyle style;
  final bool short;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuctionClock.instance,
      builder: (context, _) => Text(
        short ? auctionRemainingShort(deadline) : auctionRemaining(deadline),
        maxLines: 1,
        style: style.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Toned phase pill: a breathing dot for Live, quiet tones otherwise.
class AuctionPhaseBadge extends StatelessWidget {
  const AuctionPhaseBadge({
    required this.auction,
    super.key,
    this.glass = true,
  });

  final AuctionListing auction;

  /// Frosted fill for use over imagery.
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final a = auction;
    final tone = a.isLive
        ? p.positive
        : a.awaitingSellerDecision
        ? p.caution
        : a.isUpcoming
        ? p.accent
        : p.inkMuted;
    Widget dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(shape: BoxShape.circle, color: tone),
    );
    if (a.isLive && !MediaQuery.disableAnimationsOf(context)) {
      dot = dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade(begin: 1, end: 0.25, duration: 900.ms, curve: Curves.easeInOut);
    }
    final bg = glass
        ? (p.isDark ? const Color(0x99000000) : const Color(0xEBFFFFFF))
        : tone.withValues(alpha: 0.1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 5),
          Text(
            a.phaseLabel.toUpperCase(),
            style: LuxeType.eyebrow(tone).copyWith(fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}
