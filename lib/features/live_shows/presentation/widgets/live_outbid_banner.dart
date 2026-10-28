import 'package:flutter/material.dart';

import '../../domain/live_format.dart';
import '../../domain/models/live_show_models.dart';
import 'live_stage_tokens.dart';

/// Ruby alert under the header when someone tops the viewer's bid. A thin
/// bar along its foot drains over [duration] so the viewer can tell it will
/// go away on its own.
class LiveOutbidBanner extends StatelessWidget {
  const LiveOutbidBanner({
    required this.lot,
    required this.onClose,
    super.key,
    this.duration = const Duration(seconds: 6),
  });

  final LiveAuctionLot lot;
  final VoidCallback onClose;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF4D63), Color(0xFFB8143A)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "You've been outbid",
                              style: LiveType.label(
                                14.5,
                                color: Colors.white,
                                weight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${lot.title} is at ${liveInr(lot.currentBid ?? 0)}. '
                              'Bid ${liveInr(lot.minNextBid)} to lead again.',
                              style: LiveType.body(
                                12.5,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Dismiss',
                        onPressed: onClose,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: 0),
                  duration: duration,
                  builder: (context, v, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        height: 3,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
