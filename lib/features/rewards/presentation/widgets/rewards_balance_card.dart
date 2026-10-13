import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../../core/widgets/gem3d/gem_view.dart';
import '../../../buyer/presentation/maison/maison_kit.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../domain/models/rewards.dart';
import '../rewards_format.dart';

/// The points balance as a dark vault card: scattered gold sparkles, a
/// turning brilliant, its rupee value and whether it can be spent yet.
class RewardsBalanceCard extends StatelessWidget {
  const RewardsBalanceCard({required this.rewards, super.key});

  final RewardsSummary rewards;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final soft = p.onOnyx.withValues(alpha: 0.6);
    final settings = rewards.settings;

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

    Widget card = AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AtelierRadius.xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [LuxeStage.vault, LuxeStage.vaultBottom],
          ),
          border: Border.all(color: p.gold.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: p.isDark ? 0.6 : 0.3),
              blurRadius: 40,
              spreadRadius: -18,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, c) {
            final gem = (c.maxHeight * 0.58).clamp(68.0, 140.0);
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SparklePainter(
                      color: p.gold.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Positioned(
                  right: c.maxWidth * 0.05,
                  top: c.maxHeight * 0.14,
                  child: GemView(
                    cut: GemCut.round,
                    look: GemLook.champagne,
                    size: gem,
                    spin: 0.35,
                    tilt: 0.45,
                    interactive: true,
                    semanticLabel: 'Rotating gem. Drag to turn it.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('GEMWORLD', style: AtelierType.overline(p.gold)),
                          const SizedBox(width: 8),
                          Container(width: 1, height: 10, color: soft),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'REWARD POINTS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AtelierType.overline(soft),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text('BALANCE', style: AtelierType.overline(soft)),
                      const SizedBox(height: 6),
                      Padding(
                        padding: EdgeInsets.only(right: gem * 0.55),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              CountUpText(
                                rewardPointsCount(rewards.balance),
                                duration: const Duration(milliseconds: 1500),
                                style: AtelierType.display(
                                  p.onOnyx,
                                  size: 46,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                rewards.balance == 1 ? 'pt' : 'pts',
                                style: AtelierType.label(p.gold, size: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Worth ${maisonInr(rewards.balanceValueInr)} at checkout',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.caption(soft, size: 12.5),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AtelierRadius.pill,
                          ),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                statusLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AtelierType.label(statusColor, size: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    if (!context.reduceMotion) {
      card = card
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            delay: 4200.ms,
            duration: 1900.ms,
            angle: 0.6,
            color: p.gold.withValues(alpha: 0.16),
          );
    }

    return Semantics(
      label:
          'Reward points balance ${rewardPointsLabel(rewards.balance)}, '
          'worth ${maisonInr(rewards.balanceValueInr)}. $statusLabel.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: TiltSurface(maxTilt: 0.09, child: card),
      ),
    );
  }
}

/// Four-point sparkles scattered from a fixed seed, so they never jump.
class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final paint = Paint()..color = color;
    for (var i = 0; i < 26; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = 1.2 + rnd.nextDouble() * (i % 6 == 0 ? 4.5 : 1.8);
      final alpha = 0.25 + rnd.nextDouble() * 0.75;
      paint.color = color.withValues(alpha: color.a * alpha);
      final path = Path()
        ..moveTo(x, y - r * 2)
        ..quadraticBezierTo(x, y, x + r * 2, y)
        ..quadraticBezierTo(x, y, x, y + r * 2)
        ..quadraticBezierTo(x, y, x - r * 2, y)
        ..quadraticBezierTo(x, y, x, y - r * 2)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}
