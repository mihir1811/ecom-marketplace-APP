import 'package:flutter/material.dart';

import '../../../../core/theme/luxe_tokens.dart';

/// Colours for the always-dark live stage drawn over video. Fixed values,
/// not theme tokens: the video behind is the same in light and dark mode.
abstract final class LiveStage {
  static const live = Color(0xFFFF3B4E);
  static const leading = Color(0xFF3DD68C);
  static const urgent = Color(0xFFFF5A5F);
  static const ink = Colors.white;
  static Color get inkMuted => Colors.white.withValues(alpha: 0.72);
  static Color get inkFaint => Colors.white.withValues(alpha: 0.5);
  static Color get glass => Colors.black.withValues(alpha: 0.42);
  static Color get glassStrong =>
      const Color(0xFF111114).withValues(alpha: 0.86);
  static Color get glassBorder => Colors.white.withValues(alpha: 0.14);
  static Color get gold => LuxeStage.goldLight;

  /// Scrims so overlays read on bright video.
  static const topScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xA6000000), Color(0x00000000)],
  );
  static const bottomScrim = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xE6000000), Color(0x8C000000), Color(0x00000000)],
    stops: [0, 0.45, 1],
  );
}

/// Pulsing red "LIVE" pill.
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key, this.compact = false});

  final bool compact;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Live',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 7 : 9,
          vertical: widget.compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: LiveStage.live,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: still
                  ? const AlwaysStoppedAnimation(1)
                  : Tween<double>(begin: 0.35, end: 1).animate(_pulse),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.compact ? 10 : 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eye + viewer count on a dark glass pill.
class LiveViewerPill extends StatelessWidget {
  const LiveViewerPill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LiveStage.glass,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
