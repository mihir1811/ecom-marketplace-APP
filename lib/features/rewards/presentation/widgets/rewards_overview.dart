import 'package:flutter/material.dart';

import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../domain/models/rewards.dart';
import '../rewards_format.dart';

/// Progress toward the smallest spendable balance.
class RewardsUnlockCard extends StatelessWidget {
  const RewardsUnlockCard({required this.rewards, super.key});

  final RewardsSummary rewards;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final min = rewards.settings.minRedeemPoints;
    final progress = min <= 0 ? 1.0 : rewards.balance / min;
    return AtelierCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.goldSoft,
                ),
                child: Icon(Icons.lock_open_rounded, size: 18, color: p.gold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collect ${rewardPointsLabel(rewards.pointsToUnlock)} more',
                      style: AtelierType.title(p.ink, size: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Usable from ${rewardPointsLabel(min)}.',
                      style: AtelierType.caption(p.muted, size: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AtelierMeter(value: progress, color: p.gold),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                rewardPointsLabel(rewards.balance),
                style: AtelierType.figure(p.ink, size: 12),
              ),
              const Spacer(),
              Text(
                rewardPointsLabel(min),
                style: AtelierType.figure(p.muted, size: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown while the admin has switched the programme off.
class RewardsPausedNotice extends StatelessWidget {
  const RewardsPausedNotice({required this.balance, super.key});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return AtelierNotice(
      tone: AtelierTone.amber,
      icon: Icons.pause_circle_outline_rounded,
      text: balance > 0
          ? 'Rewards paused. Your ${rewardPointsLabel(balance)} are safe.'
          : 'Rewards paused. New orders don\'t earn for now.',
    );
  }
}
