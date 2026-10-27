import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../application/live_show_room.dart';
import 'live_stage_tokens.dart';

/// Comments over the video, Instagram Live style: newest at the bottom,
/// older lines fade out towards the top. Auction moments are mixed in.
class LiveChatFeed extends StatelessWidget {
  const LiveChatFeed({required this.items, super.key});

  final List<LiveFeedItem> items;

  static const _visible = 30;

  @override
  Widget build(BuildContext context) {
    final shown = items.length > _visible
        ? items.sublist(items.length - _visible)
        : items;
    final still = MediaQuery.disableAnimationsOf(context);
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black, Colors.black],
        stops: [0, 0.28, 1],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.only(top: 40, bottom: 4),
        physics: const BouncingScrollPhysics(),
        itemCount: shown.length,
        itemBuilder: (context, i) {
          final item = shown[shown.length - 1 - i];
          Widget line = Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: item.isMoment ? _Moment(item: item) : _Comment(item: item),
            ),
          );
          if (!still && i == 0) {
            line = line
                .animate(key: ValueKey(item.id))
                .fadeIn(duration: 260.ms)
                .moveY(
                  begin: 12,
                  end: 0,
                  duration: 320.ms,
                  curve: Curves.easeOutCubic,
                );
          }
          return KeyedSubtree(key: ValueKey(item.id), child: line);
        },
      ),
    );
  }
}

class _Comment extends StatelessWidget {
  const _Comment({required this.item});

  final LiveFeedItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            if (item.isSeller)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: LiveStage.gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SELLER',
                    style: TextStyle(
                      color: Color(0xFF16140F),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            TextSpan(
              text: '${item.author ?? 'Guest'}  ',
              style: TextStyle(
                color: item.isSeller ? LiveStage.gold : LiveStage.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: item.body),
          ],
        ),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          height: 1.3,
          shadows: [Shadow(blurRadius: 6, color: Color(0x99000000))],
        ),
      ),
    );
  }
}

class _Moment extends StatelessWidget {
  const _Moment({required this.item});

  final LiveFeedItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LiveStage.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LiveStage.gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gavel_rounded, size: 14, color: LiveStage.gold),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              item.body,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
