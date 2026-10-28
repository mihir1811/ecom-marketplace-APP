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
                    child: _Header(
                      top: top,
                      count: shows.length,
                      loading: state.isLoading && shows.isEmpty,
                    ),
                  ),
                  ...slivers,
                ],
              ),
            ),
          ],
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        sliver: SliverToBoxAdapter(child: hero),
      ),
      if (rest.isNotEmpty) ...[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text('ALSO ON AIR', style: LiveType.eyebrow()),
                const SizedBox(width: 12),
                const Expanded(child: LiveRule()),
                const SizedBox(width: 12),
                Text(
                  '${rest.length}',
                  style: LiveType.figure(12, color: LiveStage.inkFaint),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
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
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.top,
    required this.count,
    required this.loading,
  });

  final double top;
  final int count;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    Widget title = Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Live '),
          TextSpan(
            text: 'shows',
            style: LiveType.display(
              52,
              italic: true,
              color: LiveStage.champagne,
            ),
          ),
        ],
      ),
      style: LiveType.display(52),
    );
    if (!still) {
      title = title
          .animate()
          .fadeIn(duration: 500.ms)
          .moveY(
            begin: 12,
            end: 0,
            duration: 600.ms,
            curve: LiveMotion.emphasized,
          );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(12, top + 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiveIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => context.goBack(fallbackLocation: AppRouteNames.home),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: LiveMotion.base,
                  child: Row(
                    key: ValueKey(count),
                    children: [
                      if (count > 0) ...[
                        const LiveBadge(compact: true),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        loading
                            ? 'TUNING IN'
                            : count == 0
                            ? 'OFF AIR'
                            : '$count ${count == 1 ? 'SHOW' : 'SHOWS'} ON AIR',
                        style: LiveType.eyebrow(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                title,
                const SizedBox(height: 8),
                Text(
                  'Sellers present each piece on camera. Ask, bid and win in real time.',
                  style: LiveType.body(14),
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
        const SizedBox(height: 28),
        Text(
          error != null ? 'We lost the signal' : 'Nobody is live just now',
          textAlign: TextAlign.center,
          style: LiveType.display(32),
        ),
        // Empty state stays quiet: polling and pull-to-refresh pick up
        // new shows, so only a lost signal gets a message and a retry.
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error, textAlign: TextAlign.center, style: LiveType.body(14)),
          const SizedBox(height: 26),
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
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 160),
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
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
      );
      if (!still) {
        r = r
            .animate(onPlay: (c) => c.repeat(), delay: (i * 900).ms)
            .scaleXY(
              begin: 0.3,
              end: 1,
              duration: 2700.ms,
              curve: Curves.easeOut,
            )
            .fade(begin: 1, end: 0, duration: 2700.ms, curve: Curves.easeIn);
      }
      return r;
    }

    return SizedBox.square(
      dimension: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 3; i++) ring(i),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LiveStage.obsidian,
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Icon(
              error ? Icons.wifi_off_rounded : Icons.sensors_rounded,
              color: color,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
