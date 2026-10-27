import 'package:flutter/material.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/luxe/press_tilt.dart';
import '../../domain/live_format.dart';
import '../../domain/models/live_show_models.dart';
import 'live_stage_tokens.dart';

/// Portrait show card: cover image, LIVE + viewers on top, seller and
/// title over a scrim at the bottom. Taps open the show.
class LiveShowCard extends StatelessWidget {
  const LiveShowCard({required this.show, super.key, this.featured = false});

  final LiveShow show;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final poster = show.posterUrl;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return PressTilt(
      semanticLabel:
          '${show.title}, ${show.seller.companyName}, live, '
          '${show.viewerCount} watching',
      onTap: () => context.openRoute(AppRouteNames.liveShowPath(show.id)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(featured ? 26 : 20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: const Color(0xFF1B1A1F),
              child: poster == null
                  ? Icon(
                      Icons.videocam_rounded,
                      size: 42,
                      color: Colors.white.withValues(alpha: 0.3),
                    )
                  : AppNetworkImage(
                      url: poster,
                      memCacheWidth: ((featured ? 420 : 220) * dpr).round(),
                    ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 160,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: LiveStage.bottomScrim),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Row(
                children: [
                  LiveBadge(compact: !featured),
                  const SizedBox(width: 6),
                  LiveViewerPill(label: liveCount(show.viewerCount)),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: featured ? 13 : 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundImage: show.seller.logo == null
                            ? null
                            : NetworkImage(show.seller.logo!),
                        child: Text(
                          show.seller.companyName.isEmpty
                              ? '?'
                              : show.seller.companyName[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: featured ? 12 : 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          show.seller.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: LiveStage.inkMuted,
                            fontSize: featured ? 13 : 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    show.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: featured ? 19 : 14,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (featured && !show.isStreaming) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reconnecting…',
                      style: TextStyle(color: LiveStage.inkFaint, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
