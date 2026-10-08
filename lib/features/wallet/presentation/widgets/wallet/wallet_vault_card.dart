import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../../../core/widgets/gem3d/gem_view.dart';
import '../../../../buyer/presentation/maison/maison_kit.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../domain/models/wallet.dart';

/// The wallet balance as a dark vault card: brushed-gold engraving, a
/// slowly turning champagne stone, tilt under the finger and a passing
/// sheen.
class WalletVaultCard extends StatelessWidget {
  const WalletVaultCard({
    required this.wallet,
    this.label = 'Private wallet',
    super.key,
  });

  final Wallet wallet;

  /// Shown beside the brand mark ("Private wallet", "Business wallet").
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final soft = p.onOnyx.withValues(alpha: 0.6);
    final id = wallet.id.replaceAll('-', '');
    final tail = id.length >= 4 ? id.substring(id.length - 4) : id;

    Widget card = AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AtelierRadius.xl),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B15), Color(0xFF0B0A08)],
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
            final gem = (c.maxHeight * 0.62).clamp(72.0, 150.0);
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BrushedPainter(
                      color: p.gold.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                const Positioned.fill(child: AtelierAmbient(intensity: 0.8)),
                Positioned(
                  right: c.maxWidth * 0.04,
                  top: c.maxHeight * 0.12,
                  child: GemView(
                    cut: GemCut.cushion,
                    look: GemLook.champagne,
                    size: gem,
                    spin: 0.3,
                    tilt: 0.4,
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
                              label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AtelierType.overline(soft),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        context
                            .tr(RemainingL10n.availableBalance)
                            .toUpperCase(),
                        style: AtelierType.overline(soft),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: EdgeInsets.only(right: gem * 0.55),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: CountUpText(
                            maisonInr(wallet.balance),
                            duration: const Duration(milliseconds: 1500),
                            style: AtelierType.display(
                              p.onOnyx,
                              size: 46,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            '••••  ${tail.toUpperCase()}',
                            style: AtelierType.figure(soft, size: 13),
                          ),
                          const Spacer(),
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
                                color: p.gold.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Text(
                              wallet.currency,
                              style: AtelierType.label(p.gold, size: 11),
                            ),
                          ),
                        ],
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
            delay: 3600.ms,
            duration: 1900.ms,
            angle: 0.6,
            color: p.gold.withValues(alpha: 0.16),
          );
    }

    return Semantics(
      label: context.tr(RemainingL10n.walletBalanceAmount, {
        'amount': maisonInr(wallet.balance),
      }),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: TiltSurface(maxTilt: 0.09, child: card),
      ),
    );
  }
}

/// Fine diagonal strokes, like brushed metal.
class _BrushedPainter extends CustomPainter {
  _BrushedPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.6;
    const gap = 7.0;
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
    final arc = Paint()
      ..color = color.withValues(alpha: color.a * 2.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final center = Offset(size.width * 0.82, size.height * 0.42);
    for (var r = 40.0; r < size.width * 0.5; r += 14) {
      canvas.drawCircle(center, r, arc);
    }
  }

  @override
  bool shouldRepaint(_BrushedPainter old) => old.color != color;
}
