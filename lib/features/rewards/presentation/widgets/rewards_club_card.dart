import 'package:flutter/material.dart';

import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../domain/models/rewards.dart';
import '../rewards_format.dart';

/// The buyer's club, progress to the next one and every club in one row.
class RewardsClubCard extends StatelessWidget {
  const RewardsClubCard({
    required this.status,
    required this.showBonus,
    super.key,
  });

  final RewardClubStatus status;

  /// False while the programme is off: bonus text is hidden.
  final bool showBonus;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final current = status.current;
    final next = status.next;
    final accent = Color(current?.color ?? next?.color ?? 0xFFA8A9AD);
    final toNext =
        status.pointsToNext ??
        (next == null ? 0 : next.minPoints - status.lifetimePoints);

    return AtelierCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.16),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  size: 19,
                  color: current == null ? p.muted : accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current == null ? 'No club yet' : '${current.name} club',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.title(p.ink, size: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${rewardPointsLabel(status.lifetimePoints)} lifetime',
                      style: AtelierType.caption(p.muted, size: 12),
                    ),
                  ],
                ),
              ),
              if (showBonus && current != null && current.hasBonus)
                _Pill(
                  text:
                      '${rewardMultiplierLabel(current.earnMultiplier)} points',
                  color: accent,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ClubTrack(status: status, showBonus: showBonus),
          const SizedBox(height: 10),
          Text(
            next == null
                ? "You're in the top club"
                : '${rewardPointsLabel(toNext < 0 ? 0 : toNext)} to ${next.name}',
            style: AtelierType.label(p.inkSoft, size: 12.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Clubs go by lifetime points. Spending never lowers them.',
            style: AtelierType.caption(p.muted, size: 11.5),
          ),
        ],
      ),
    );
  }
}

/// Every club as a stop on one track, filled up to the buyer's lifetime
/// points, with a "You" marker. Stops are evenly spaced so small and large
/// thresholds both stay readable.
class _ClubTrack extends StatelessWidget {
  const _ClubTrack({required this.status, required this.showBonus});

  final RewardClubStatus status;
  final bool showBonus;

  static const _trackY = 24.0;
  static const _labelWidth = 76.0;

  /// 0..1 along the track: equal-width segments between 0 and each club.
  double get _position {
    final clubs = status.clubs;
    final points = status.lifetimePoints;
    if (points >= clubs.last.minPoints) return 1;
    var start = 0;
    for (var i = 0; i < clubs.length; i++) {
      final end = clubs[i].minPoints;
      if (points < end) {
        final span = end - start;
        final within = span <= 0 ? 1.0 : (points - start) / span;
        return (i + within.clamp(0.0, 1.0)) / clubs.length;
      }
      start = end;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final clubs = status.clubs;
    final fill = Color(
      status.current?.color ?? status.next?.color ?? clubs.first.color,
    );
    final position = _position;

    return LayoutBuilder(
      builder: (context, c) {
        const inset = _labelWidth / 2;
        final width = c.maxWidth - inset * 2;
        double xAt(double t) => inset + width * t;
        final youX = xAt(position);

        return SizedBox(
          height: _trackY + 46,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Track and fill.
              Positioned(
                left: xAt(0),
                width: width,
                top: _trackY - 3,
                height: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.sunken,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                left: xAt(0),
                width: width * position,
                top: _trackY - 3,
                height: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Start stop.
              _stop(
                context,
                x: xAt(0),
                color: p.muted,
                reached: true,
                title: 'Start',
                caption: '0',
              ),
              for (var i = 0; i < clubs.length; i++)
                _stop(
                  context,
                  x: xAt((i + 1) / clubs.length),
                  color: Color(clubs[i].color),
                  reached: status.lifetimePoints >= clubs[i].minPoints,
                  title: clubs[i].name,
                  caption: [
                    rewardPointsCount(clubs[i].minPoints),
                    if (showBonus && clubs[i].hasBonus)
                      rewardMultiplierLabel(clubs[i].earnMultiplier),
                  ].join(' · '),
                  bold: clubs[i].id == status.current?.id,
                ),
              // "You" marker above the track.
              Positioned(
                left: youX - 20,
                width: 40,
                top: 0,
                child: Column(
                  children: [
                    Text('You', style: AtelierType.label(p.ink, size: 10.5)),
                    Icon(Icons.arrow_drop_down_rounded, size: 16, color: p.ink),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stop(
    BuildContext context, {
    required double x,
    required Color color,
    required bool reached,
    required String title,
    required String caption,
    bool bold = false,
  }) {
    final p = context.atelier;
    return Positioned(
      left: x - _labelWidth / 2,
      width: _labelWidth,
      top: _trackY - 7,
      child: Column(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: reached ? color : p.surface,
              border: Border.all(color: color, width: 2),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtelierType.label(
              bold ? p.ink : p.inkSoft,
              size: bold ? 11.5 : 11,
            ),
          ),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtelierType.caption(p.muted, size: 10.5),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: AtelierType.label(context.atelier.ink, size: 11.5),
      ),
    );
  }
}
