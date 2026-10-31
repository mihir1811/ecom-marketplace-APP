import 'package:flutter/material.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../../buyer/presentation/maison/maison_kit.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../domain/models/rewards.dart';
import '../rewards_format.dart';

/// Everything about the buyer's points in one compact dark card: balance
/// and its rupee value, spend status, club progress and the current rates.
class RewardsBalanceCard extends StatelessWidget {
  const RewardsBalanceCard({required this.rewards, super.key});

  final RewardsSummary rewards;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final soft = p.onOnyx.withValues(alpha: 0.6);
    final settings = rewards.settings;
    final club = rewards.club;

    final (statusLabel, statusColor, statusIcon) = !settings.enabled
        ? ('Paused', p.amber, Icons.pause_circle_outline_rounded)
        : rewards.canSpend
        ? ('Ready to use', p.emerald, Icons.check_circle_outline_rounded)
        : rewards.balance <= 0
        ? ('Start earning', p.gold, Icons.auto_awesome_outlined)
        : (
            '${rewardPointsLabel(rewards.pointsToUnlock)} to unlock',
            p.gold,
            Icons.lock_outline_rounded,
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LuxeStage.vault, LuxeStage.vaultBottom],
        ),
        border: Border.all(color: p.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Balance + status.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REWARD POINTS', style: AtelierType.overline(soft)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          CountUpText(
                            rewardPointsCount(rewards.balance),
                            duration: const Duration(milliseconds: 1200),
                            style: AtelierType.display(
                              p.onOnyx,
                              size: 34,
                              weight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            rewards.balance == 1 ? 'pt' : 'pts',
                            style: AtelierType.label(p.gold, size: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Worth ${maisonInr(rewards.balanceValueInr)} at checkout',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.caption(soft, size: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(
                label: statusLabel,
                color: statusColor,
                icon: statusIcon,
              ),
            ],
          ),
          if (club.hasClubs) ...[
            const SizedBox(height: 12),
            _ClubLine(status: club, soft: soft),
          ],
          if (settings.enabled) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: p.onOnyx.withValues(alpha: 0.1)),
            const SizedBox(height: 10),
            Text(
              'Earn 1 pt per '
              '${atelierMoney(settings.earnRupeesPerPoint, symbol: '₹')}'
              '  ·  1 pt = ${maisonInr(settings.pointValueInr)}',
              maxLines: 2,
              style: AtelierType.caption(soft, size: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Silver club · 12 pts lifetime" with a thin bar to the next club.
class _ClubLine extends StatelessWidget {
  const _ClubLine({required this.status, required this.soft});

  final RewardClubStatus status;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final current = status.current;
    final next = status.next;
    final accent = Color(current?.color ?? next?.color ?? 0xFFA8A9AD);
    final toNext =
        status.pointsToNext ??
        (next == null ? 0 : next.minPoints - status.lifetimePoints);
    final trailing = next == null
        ? 'Top club'
        : '${rewardPointsLabel(toNext < 0 ? 0 : toNext)} to ${next.name}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 15,
              color: current == null ? soft : accent,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${current == null ? 'No club yet' : '${current.name} club'}'
                ' · ${rewardPointsLabel(status.lifetimePoints)} lifetime',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.label(p.onOnyx, size: 12.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(trailing, style: AtelierType.caption(soft, size: 11.5)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AtelierRadius.pill),
          child: LinearProgressIndicator(
            value: status.progress.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: p.onOnyx.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(accent),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtelierType.label(color, size: 11),
            ),
          ),
        ],
      ),
    );
  }
}
