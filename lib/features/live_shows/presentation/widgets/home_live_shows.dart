import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../application/live_shows_provider.dart';
import 'live_show_card.dart';
import 'live_stage_tokens.dart';

/// "Live now" rail for home. Shows nothing unless a seller is on air, so
/// home never carries an empty or error block for it.
class HomeLiveShows extends ConsumerWidget {
  const HomeLiveShows({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shows = ref.watch(liveShowsProvider.select((s) => s.shows));
    if (shows.isEmpty) return const SizedBox.shrink();
    final p = LuxePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LuxeSpace.gutter),
            child: Row(
              children: [
                const LiveBadge(),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Live now', style: LuxeType.display(26, p.ink)),
                ),
                TextButton(
                  onPressed: () => context.openRoute(AppRouteNames.liveShows),
                  child: Text(
                    'See all',
                    style: LuxeType.label(p.accent, size: 13.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: LuxeSpace.gutter),
              itemCount: shows.length.clamp(0, 10),
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) =>
                  SizedBox(width: 160, child: LiveShowCard(show: shows[i])),
            ),
          ),
        ],
      ),
    );
  }
}
