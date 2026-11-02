import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../application/live_shows_provider.dart';
import '../../domain/models/live_show_models.dart';
import '../widgets/live_aurora.dart';
import '../widgets/live_show_card.dart';
import '../widgets/live_stage_tokens.dart';

/// The live lobby: an aurora-lit noir room. The most watched show is the
/// hero, the rest follow in a portrait grid. Refreshes every 30 s and on
/// pull.
class LiveShowsScreen extends ConsumerWidget {
  const LiveShowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveShowsProvider);
    final notifier = ref.read(liveShowsProvider.notifier);
    final shows = state.shows;
    final top = MediaQuery.paddingOf(context).top;

    final List<Widget> slivers;
    if (state.isLoading && shows.isEmpty) {
      slivers = const [SliverToBoxAdapter(child: _Skeleton())];
    } else if (shows.isEmpty) {
      slivers = [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyOrError(
            error: state.errorMessage,
            onRetry: notifier.refresh,
          ),
        ),
      ];
    } else {
      slivers = _content(context, shows);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LiveShowsPolling(
        child: AppScaffold(
          safeTop: false,
          safeBottom: false,
          backgroundColor: LiveStage.void_,
          body: Stack(
            children: [
              const Positioned.fill(child: LiveAurora()),
              RefreshIndicator(
                color: LiveStage.onChampagne,
                backgroundColor: LiveStage.champagne,
                edgeOffset: top + 60,
                onRefresh: notifier.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Header(top: top, count: shows.length),
                    ),
                    ...slivers,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, List<LiveShow> shows) {
    final still = MediaQuery.disableAnimationsOf(context);
    final featured = shows.first;
    final rest = shows.skip(1).toList();
    Widget hero = AspectRatio(
      aspectRatio: 4 / 5,
      child: LiveShowCard(
        key: ValueKey(featured.id),
        show: featured,
        featured: true,
      ),
    );
    if (!still) {
      hero = hero
          .animate()
          .fadeIn(duration: 500.ms)
          .scaleXY(
            begin: 0.94,
            end: 1,
            duration: 700.ms,
            curve: LiveMotion.emphasized,
          )
          .moveY(
            begin: 24,
            end: 0,
            duration: 700.ms,
            curve: LiveMotion.emphasized,
          );
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        sliver: SliverToBoxAdapter(child: hero),
      ),
      if (rest.isNotEmpty) ...[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          sliver: SliverToBoxAdapter(
            child: Text('More shows', style: LiveType.label(15)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 9 / 14,
            ),
            delegate: SliverChildBuilderDelegate((context, i) {
              Widget card = LiveShowCard(
                key: ValueKey(rest[i].id),
                show: rest[i],
              );
              if (!still) {
                card = card
                    .animate(delay: (120 + 60 * (i % 6)).ms)
                    .fadeIn(duration: 420.ms)
                    .moveY(
                      begin: 28,
                      end: 0,
                      duration: 600.ms,
                      curve: LiveMotion.emphasized,
                    );
              }
              return card;
            }, childCount: rest.length),
          ),
        ),
      ] else
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.top, required this.count});

  final double top;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, top + 8, 16, 12),
      child: Row(
        children: [
          LiveIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            size: 40,
            onTap: () => context.goBack(fallbackLocation: AppRouteNames.home),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Live shows',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LiveType.display(26),
            ),
          ),
          // Live count only when something is on air; off air stays blank.
          AnimatedSwitcher(
            duration: LiveMotion.base,
            child: count == 0
                ? const SizedBox.shrink()
                : Row(
                    key: ValueKey(count),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LiveBadge(compact: true),
                      const SizedBox(width: 8),
                      Text(
                        '$count on air',
                        style: LiveType.label(13, weight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    Widget block(double radius) {
      Widget b = Container(
        decoration: BoxDecoration(
          color: LiveStage.graphite.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: LiveStage.hairline),
        ),
      );
      if (!still) {
        b = b
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: 1600.ms,
              color: LiveStage.champagne.withValues(alpha: 0.08),
            );
      }
      return b;
    }

    return Semantics(
      label: 'Loading live shows',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [
            AspectRatio(aspectRatio: 4 / 5, child: block(30)),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: SizedBox(height: 250, child: block(22))),
                const SizedBox(width: 14),
                Expanded(child: SizedBox(height: 250, child: block(22))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrError extends StatefulWidget {
  const _EmptyOrError({required this.error, required this.onRetry});

  final String? error;
  final Future<void> Function() onRetry;

  @override
  State<_EmptyOrError> createState() => _EmptyOrErrorState();
}

class _EmptyOrErrorState extends State<_EmptyOrError> {
  var _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    await widget.onRetry();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    final still = MediaQuery.disableAnimationsOf(context);
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Beacon(error: error != null),
        const SizedBox(height: 16),
        Text(
          error != null ? 'We lost the signal' : 'No live shows right now',
          textAlign: TextAlign.center,
          style: LiveType.label(17),
        ),
        const SizedBox(height: 6),
        Text(
          error ?? 'Pull down to refresh',
          textAlign: TextAlign.center,
          style: LiveType.body(13, color: LiveStage.inkFaint),
        ),
        if (error != null) ...[
          const SizedBox(height: 18),
          LiveButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            expand: false,
            busy: _busy,
            onTap: _retry,
          ),
        ],
      ],
    );
    if (!still) {
      content = content
          .animate()
          .fadeIn(duration: 500.ms)
          .moveY(begin: 16, end: 0, curve: LiveMotion.emphasized);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 96),
      child: Center(child: content),
    );
  }
}

/// Broadcast beacon: concentric rings breathing out from a centre mark.
class _Beacon extends StatelessWidget {
  const _Beacon({required this.error});

  final bool error;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final color = error ? LiveStage.urgent : LiveStage.champagne;
    Widget ring(int i) {
      Widget r = Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
      );
      if (!still) {
        r = r
            .animate(onPlay: (c) => c.repeat(), delay: (i * 1400).ms)
            .scaleXY(
              begin: 0.5,
              end: 1,
              duration: 2800.ms,
              curve: Curves.easeOut,
            )
            .fade(begin: 0.8, end: 0, duration: 2800.ms, curve: Curves.easeIn);
      }
      return r;
    }

    return SizedBox.square(
      dimension: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 2; i++) ring(i),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LiveStage.obsidian,
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Icon(
              error ? Icons.wifi_off_rounded : Icons.sensors_rounded,
              color: color,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
