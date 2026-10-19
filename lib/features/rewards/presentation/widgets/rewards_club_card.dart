import 'package:flutter/material.dart';

import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 14),
          AtelierMeter(
            value: status.progress,
            color: next == null ? accent : Color(next.color),
          ),
          const SizedBox(height: 8),
          Text(
            next == null
                ? "You're in the top club"
                : '${rewardPointsLabel(toNext < 0 ? 0 : toNext)} to ${next.name}',
            style: AtelierType.label(p.inkSoft, size: 12.5),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final club in status.clubs)
                _ClubChip(
                  club: club,
                  selected: club.id == current?.id,
                  showBonus: showBonus,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Clubs go by lifetime points. Spending never lowers them.',
            style: AtelierType.caption(p.muted, size: 11.5),
          ),
        ],
      ),
    );
  }
}

class _ClubChip extends StatelessWidget {
  const _ClubChip({
    required this.club,
    required this.selected,
    required this.showBonus,
  });

  final RewardClub club;
  final bool selected;
  final bool showBonus;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final color = Color(club.color);
    final parts = [
      club.name,
      '${rewardPointsCount(club.minPoints)}+',
      if (showBonus && club.hasBonus)
        rewardMultiplierLabel(club.earnMultiplier),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.14) : p.sunken,
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        border: Border.all(
          color: selected ? color.withValues(alpha: 0.7) : p.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            parts.join(' · '),
            style: AtelierType.label(selected ? p.ink : p.inkSoft, size: 11.5),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
