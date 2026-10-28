import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../application/live_show_room.dart';
import 'live_stage_tokens.dart';

/// Comments over the video, newest at the bottom, older lines dissolving
/// toward the top. Auction moments (bids, sales) sit inline as champagne
/// notes so the story of the auction reads alongside the conversation.
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
    if (shown.isEmpty) {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Say hello — the seller reads every comment.',
            style: LiveType.body(12.5, color: LiveStage.inkFaint),
          ),
        ),
      );
    }
    return RepaintBoundary(
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black, Colors.black],
          stops: [0, 0.32, 1],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          reverse: true,
          padding: const EdgeInsets.only(top: 48, bottom: 2),
          physics: const BouncingScrollPhysics(),
          itemCount: shown.length,
          itemBuilder: (context, i) {
            final item = shown[shown.length - 1 - i];
            Widget line = Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: item.isMoment
                    ? _Moment(item: item)
                    : _Comment(item: item),
              ),
            );
            if (!still && i == 0) {
              line = line
                  .animate(key: ValueKey(item.id))
                  .fadeIn(duration: 280.ms)
                  .moveY(
                    begin: 14,
                    end: 0,
                    duration: 380.ms,
                    curve: Curves.easeOutCubic,
                  );
            }
            return KeyedSubtree(key: ValueKey(item.id), child: line);
          },
        ),
      ),
    );
  }
}

class _Comment extends StatelessWidget {
  const _Comment({required this.item});

  final LiveFeedItem item;

  @override
  Widget build(BuildContext context) {
    final name = item.author?.trim().isNotEmpty == true
        ? item.author!
        : 'Guest';
    final seller = item.isSeller;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: seller ? LiveStage.champagneGradient : null,
            color: seller ? null : LiveStage.ink.withValues(alpha: 0.14),
          ),
          child: Text(
            name[0].toUpperCase(),
            style: LiveType.label(
              11,
              color: seller ? LiveStage.onChampagne : LiveStage.ink,
              weight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LiveType.label(
                        11.5,
                        color: seller
                            ? LiveStage.champagne
                            : LiveStage.ink.withValues(alpha: 0.6),
                      ).copyWith(shadows: _shadow),
                    ),
                  ),
                  if (seller) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: LiveStage.champagne.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Text(
                        'SELLER',
                        style: LiveType.eyebrow(
                          color: LiveStage.champagne,
                          size: 8,
                        ).copyWith(letterSpacing: 1),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 1),
              Text(
                item.body,
                style: LiveType.body(
                  13.5,
                  color: LiveStage.ink,
                  weight: FontWeight.w500,
                  height: 1.3,
                ).copyWith(shadows: _shadow),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// A crisp drop rather than a blurred halo: a blurred shadow is one
// offscreen pass per line, redrawn with every video frame.
const _shadow = [Shadow(offset: Offset(0, 1), color: Color(0xCC000000))];

class _Moment extends StatelessWidget {
  const _Moment({required this.item});

  final LiveFeedItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LiveStage.champagne.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LiveStage.champagneGradient,
            ),
            child: const Icon(
              Icons.gavel_rounded,
              size: 11,
              color: LiveStage.onChampagne,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              item.body,
              style: LiveType.label(12.5, color: LiveStage.champagneLight),
            ),
          ),
        ],
      ),
    );
  }
}
