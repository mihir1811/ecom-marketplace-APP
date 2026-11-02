import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../application/live_shows_provider.dart';
import 'live_show_card.dart';
import 'live_stage_tokens.dart';

/// "Live now" band for home: a noir panel that reads as a window onto the
/// salon. Off air it shrinks to a quiet entry into the live list, so
/// everyone, signed in or not, can always find live shows.
class HomeLiveShows extends ConsumerWidget {
  const HomeLiveShows({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const LiveShowsPolling(child: _HomeLiveBand());
}

class _HomeLiveBand extends ConsumerWidget {
  const _HomeLiveBand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shows = ref.watch(liveShowsProvider.select((s) => s.shows));
    if (shows.isEmpty) return const _OffAirEntry();
    final still = MediaQuery.disableAnimationsOf(context);
    final count = shows.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LuxeSpace.gutter,
        40,
        LuxeSpace.gutter,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.only(top: 20, bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF16130E), LiveStage.void_],
          ),
          border: Border.all(
            color: LiveStage.champagne.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const LiveBadge(compact: true),
                            const SizedBox(width: 8),
                            Text(
                              '$count ON AIR',
                              style: LiveType.eyebrow(size: 9.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Live now', style: LiveType.display(30)),
                      ],
                    ),
                  ),
                  const _SeeAll(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 252,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: count.clamp(0, 10),
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  Widget card = SizedBox(
                    width: 164,
                    child: LiveShowCard(show: shows[i]),
                  );
                  if (!still && i < 4) {
                    card = card
                        .animate(delay: (70 * i).ms)
                        .fadeIn(duration: 380.ms)
                        .moveX(begin: 24, end: 0, curve: LiveMotion.emphasized);
                  }
                  return card;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Off-air home entry: same noir panel, one row, opens the live list.
class _OffAirEntry extends StatelessWidget {
  const _OffAirEntry();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LuxeSpace.gutter,
        40,
        LuxeSpace.gutter,
        0,
      ),
      child: LivePressable(
        semanticLabel: 'Live shows',
        onTap: () => context.openRoute(AppRouteNames.liveShows),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF16130E), LiveStage.void_],
            ),
            border: Border.all(
              color: LiveStage.champagne.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.live_tv_outlined,
                size: 26,
                color: LiveStage.champagne,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LIVE SHOWS', style: LiveType.eyebrow(size: 9.5)),
                    const SizedBox(height: 6),
                    Text(
                      'Watch sellers live and bid in real time',
                      style: LiveType.body(13.5, color: LiveStage.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: LiveStage.champagne,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeeAll extends StatelessWidget {
  const _SeeAll();

  @override
  Widget build(BuildContext context) {
    return LivePressable(
      semanticLabel: 'See all live shows',
      onTap: () => context.openRoute(AppRouteNames.liveShows),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: LiveStage.hairlineStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'See all',
              style: LiveType.label(12.5, color: LiveStage.champagne),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: LiveStage.champagne,
            ),
          ],
        ),
      ),
    );
  }
}
