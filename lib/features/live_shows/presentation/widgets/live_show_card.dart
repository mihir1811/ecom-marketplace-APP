import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/live_format.dart';
import '../../domain/models/live_show_models.dart';
import 'live_stage_tokens.dart';

/// Portrait show card. The cover drifts in a slow push-in so the card
/// feels live before it is opened; seller, title and the way in sit on a
/// deep scrim at the foot. [featured] is the hero of the lobby.
class LiveShowCard extends StatelessWidget {
  const LiveShowCard({required this.show, super.key, this.featured = false});

  final LiveShow show;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final poster = show.posterUrl;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final radius = featured ? 30.0 : 22.0;

    Widget cover = poster == null
        ? const _NoCover()
        : AppNetworkImage(
            url: poster,
            memCacheWidth: ((featured ? 460 : 240) * dpr).round(),
          );
    if (!still && poster != null) {
      cover = cover
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1,
            end: featured ? 1.08 : 1.05,
            duration: (featured ? 14 : 11).seconds,
            curve: Curves.easeInOut,
          );
    }

    final description = show.description?.trim();
    return LivePressable(
      scale: 0.97,
      semanticLabel:
          '${show.title}, ${show.seller.companyName}, live, '
          '${show.viewerCount} watching',
      onTap: () => context.openRoute(AppRouteNames.liveShowPath(show.id)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: featured ? 40 : 20,
              offset: Offset(0, featured ? 18 : 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: LiveStage.graphite, child: cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000),
                      Color(0x00000000),
                      Color(0x33000000),
                      Color(0xE6000000),
                    ],
                    stops: [0, 0.25, 0.5, 1],
                  ),
                ),
              ),
              // Hairline frame.
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: LiveStage.champagne.withValues(
                      alpha: featured ? 0.28 : 0.14,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: featured ? 16 : 10,
                left: featured ? 16 : 10,
                right: featured ? 16 : 10,
                child: Row(
                  children: [
                    LiveBadge(compact: !featured, solid: !featured),
                    const SizedBox(width: 6),
                    LiveViewerPill(
                      label: liveCount(show.viewerCount),
                      compact: !featured,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: featured ? 20 : 12,
                right: featured ? 20 : 12,
                bottom: featured ? 20 : 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        LiveAvatar(
                          name: show.seller.companyName,
                          logo: show.seller.logo,
                          size: featured ? 26 : 18,
                          ring: featured,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            show.seller.companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LiveType.label(
                              featured ? 13 : 11,
                              color: LiveStage.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: featured ? 10 : 6),
                    Text(
                      show.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LiveType.display(featured ? 32 : 18, height: 1.05),
                    ),
                    if (featured &&
                        description != null &&
                        description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LiveType.body(13),
                      ),
                    ],
                    if (featured) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(18, 11, 14, 11),
                            decoration: BoxDecoration(
                              gradient: LiveStage.champagneGradient,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Join the show',
                                  style: LiveType.label(
                                    14,
                                    color: LiveStage.onChampagne,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 17,
                                  color: LiveStage.onChampagne,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (!show.isStreaming)
                            Flexible(
                              child: Text(
                                'Reconnecting…',
                                style: LiveType.body(
                                  12,
                                  color: LiveStage.inkFaint,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoCover extends StatelessWidget {
  const _NoCover();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 0.9,
          colors: [Color(0xFF2A2318), LiveStage.obsidian],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.diamond_outlined,
          size: 40,
          color: LiveStage.champagne.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
