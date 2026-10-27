import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../application/live_shows_provider.dart';
import '../widgets/live_show_card.dart';
import '../widgets/live_stage_tokens.dart';

/// Shows on air, most watched first: the top show as a large card, the
/// rest in a portrait grid. Refreshes every 30 s and on pull.
class LiveShowsScreen extends ConsumerWidget {
  const LiveShowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LuxeScope(
      child: Builder(builder: (context) => _build(context, ref)),
    );
  }

  Widget _build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final state = ref.watch(liveShowsProvider);
    final notifier = ref.read(liveShowsProvider.notifier);
    final shows = state.shows;

    final Widget body;
    if (state.isLoading && shows.isEmpty) {
      body = const _Skeleton();
    } else if (shows.isEmpty) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          state.errorMessage != null
              ? LuxeStateView(
                  icon: Icons.cloud_off_rounded,
                  tone: LuxeTone.error,
                  title: 'Live shows unavailable',
                  message: state.errorMessage!,
                  actionLabel: 'Try again',
                  onAction: notifier.refresh,
                )
              : const LuxeStateView(
                  icon: Icons.videocam_outlined,
                  title: 'No one is live right now',
                  message:
                      'Shows appear here the moment a seller goes live. '
                      'Pull down to check again.',
                ),
        ],
      );
    } else {
      final featured = shows.first;
      final rest = shows.skip(1).toList();
      body = CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              LuxeSpace.gutter,
              8,
              LuxeSpace.gutter,
              4,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const LiveBadge(),
                  const SizedBox(width: 10),
                  Text(
                    '${shows.length} ${shows.length == 1 ? 'show' : 'shows'} '
                    'on air',
                    style: LuxeType.label(p.inkMuted, size: 13.5),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              LuxeSpace.gutter,
              12,
              LuxeSpace.gutter,
              16,
            ),
            sliver: SliverToBoxAdapter(
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: LiveShowCard(show: featured, featured: true),
              ),
            ),
          ),
          if (rest.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LuxeSpace.gutter,
                0,
                LuxeSpace.gutter,
                120,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 9 / 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => LiveShowCard(show: rest[i]),
                  childCount: rest.length,
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      );
    }

    return AppScaffold(
      safeBottom: false,
      backgroundColor: p.canvas,
      appBar: const LuxeTopBar(title: 'Live shows'),
      body: RefreshIndicator(
        color: p.accent,
        onRefresh: notifier.refresh,
        child: body,
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(LuxeSpace.gutter),
      children: const [
        AspectRatio(aspectRatio: 4 / 5, child: LuxeSkeleton(radius: 26)),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: LuxeSkeleton(height: 260, radius: 20)),
            SizedBox(width: 12),
            Expanded(child: LuxeSkeleton(height: 260, radius: 20)),
          ],
        ),
      ],
    );
  }
}
