import 'package:flutter/material.dart';

import '../../../buyer/presentation/maison/maison_kit.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../domain/models/rewards.dart';
import '../rewards_format.dart';

/// The admin's current rates: how fast points come, what they're worth and
/// how much of an order they can pay.
class RewardsRatesStrip extends StatelessWidget {
  const RewardsRatesStrip({required this.settings, super.key});

  final RewardSettings settings;

  @override
  Widget build(BuildContext context) {
    return MaisonStatStrip(
      stats: [
        MaisonStat(
          label: 'Earn 1 pt',
          value: atelierMoney(settings.earnRupeesPerPoint, symbol: '₹'),
          caption: 'of item value',
        ),
        MaisonStat(
          label: '1 pt is worth',
          value: maisonInr(settings.pointValueInr),
          caption: 'at checkout',
          tone: AtelierTone.gold,
        ),
        MaisonStat(
          label: 'Pay up to',
          value: rewardPercentLabel(settings.maxRedeemPercent),
          caption: 'of an order',
        ),
      ],
    );
  }
}

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
              const SizedBox(width: 12),
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
                      'Points can be used once your balance reaches '
                      '${rewardPointsLabel(min)}.',
                      style: AtelierType.caption(p.muted, size: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AtelierMeter(value: progress, color: p.gold),
          const SizedBox(height: 8),
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
          ? 'Rewards are paused. Your ${rewardPointsLabel(balance)} are safe '
                'and never expire, but they can\'t be used and new orders '
                'don\'t earn until the programme is back.'
          : 'Rewards are paused. New orders don\'t earn points until the '
                'programme is back.',
    );
  }
}

/// The rules, written from the admin's live rates.
class RewardsHowItWorks extends StatelessWidget {
  const RewardsHowItWorks({required this.settings, super.key});

  final RewardSettings settings;

  @override
  Widget build(BuildContext context) {
    final perPoint = atelierMoney(settings.earnRupeesPerPoint, symbol: '₹');
    final value =
        '${rewardPointsLabel(settings.redeemPoints)} = '
        '${maisonInr(settings.redeemRupees)}';
    final min = settings.minRedeemPoints;
    final steps = [
      (
        icon: Icons.shopping_bag_outlined,
        title: 'Shop',
        body:
            'Earn 1 point for every $perPoint of item value, after '
            'promotions and before GST and fees. The part you pay with '
            'points doesn\'t earn.',
      ),
      (
        icon: Icons.verified_outlined,
        title: 'Order completes',
        body:
            'Points arrive once every seller has completed their part of '
            'the order. Rejected or returned items earn nothing.',
      ),
      (
        icon: Icons.redeem_outlined,
        title: 'Spend at checkout',
        body:
            'Turn on "Use reward points". $value, for up to '
            '${rewardPercentLabel(settings.maxRedeemPercent)} of an order'
            '${min > 0 ? ', once you have ${rewardPointsLabel(min)}' : ''}.',
      ),
      (
        icon: Icons.all_inclusive_rounded,
        title: 'Never expire',
        body:
            'Points stay until you use them. If an order is refunded, '
            'the points you spent come back.',
      ),
    ];

    final p = context.atelier;
    return AtelierPanel(
      overline: 'How it works',
      title: 'Earn as you collect',
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Reveal(
              index: i,
              offset: 8,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: i == steps.length - 1 ? 0 : AtelierSpace.s16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.sunken,
                        border: Border.all(color: p.hairline),
                      ),
                      child: Icon(steps[i].icon, size: 17, color: p.gold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].title,
                            style: AtelierType.label(p.ink, size: 13.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            steps[i].body,
                            style: AtelierType.caption(p.muted, size: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
