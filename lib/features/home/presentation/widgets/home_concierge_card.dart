import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../theme/home_tokens.dart';
import 'home_section.dart';
import 'motion/press_tilt.dart';
import 'motion/scroll_reveal.dart';

/// Gem AI entry: an obsidian card with a travelling gold edge and a
/// typewriter demo of the kinds of requests the concierge understands.
class HomeConciergeCard extends StatefulWidget {
  const HomeConciergeCard({required this.onAsk, super.key});

  final VoidCallback onAsk;

  @override
  State<HomeConciergeCard> createState() => _HomeConciergeCardState();
}

class _HomeConciergeCardState extends State<HomeConciergeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _edge = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _edge.stop();
    } else if (!_edge.isAnimating) {
      _edge.repeat();
    }
  }

  @override
  void dispose() {
    _edge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gutter = homeGutter(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, HomeSpace.section, gutter, 0),
      child: ScrollReveal(
        offsetY: 40,
        child: PressTilt(
          maxTilt: 0.04,
          semanticLabel: context.tr(HomeL10n.conciergeCta),
          onTap: widget.onAsk,
          child: CustomPaint(
            foregroundPainter: _EdgePainter(_edge),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(HomeSpace.radius + 4),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF15141A), HomeStage.obsidian],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Orb(animation: _edge),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr(HomeL10n.conciergeEyebrow).toUpperCase(),
                          style: HomeType.eyebrow(HomeStage.gold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr(HomeL10n.conciergeTitle),
                    style: HomeType.display(36, HomeStage.ink),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr(HomeL10n.conciergeBody),
                    style: HomeType.body(HomeStage.inkMuted, size: 14),
                  ),
                  const SizedBox(height: 22),
                  const _TypewriterField(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          context.tr(HomeL10n.conciergeCta),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeType.label(HomeStage.gold, size: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: HomeStage.gold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gold light travelling around the card edge.
class _EdgePainter extends CustomPainter {
  _EdgePainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.6);
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(HomeSpace.radius + 4),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x22FFFFFF),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = SweepGradient(
          transform: GradientRotation(animation.value * math.pi * 2),
          colors: const [
            Color(0x00DDBF88),
            Color(0x00DDBF88),
            Color(0xFFF1DDB5),
            Color(0x00DDBF88),
          ],
          stops: const [0, 0.62, 0.8, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_EdgePainter old) => old.animation != animation;
}

/// Small breathing light orb that marks the AI.
class _Orb extends StatelessWidget {
  const _Orb({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = math.sin(animation.value * math.pi * 6) * 0.5 + 0.5;
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              transform: GradientRotation(animation.value * math.pi * 4),
              colors: const [
                Color(0xFFF1DDB5),
                Color(0xFF8FA6E8),
                Color(0xFFE6A4B4),
                Color(0xFFF1DDB5),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: HomeStage.gold.withValues(alpha: 0.25 + t * 0.25),
                blurRadius: 10 + t * 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 14,
            color: HomeStage.obsidian,
          ),
        );
      },
    );
  }
}

/// Glass field that types, holds and erases sample requests in a loop.
class _TypewriterField extends StatefulWidget {
  const _TypewriterField();

  @override
  State<_TypewriterField> createState() => _TypewriterFieldState();
}

class _TypewriterFieldState extends State<_TypewriterField> {
  static const _prompts = [
    HomeL10n.conciergePrompt1,
    HomeL10n.conciergePrompt2,
    HomeL10n.conciergePrompt3,
  ];
  Timer? _timer;
  int _prompt = 0;
  int _chars = 0;
  bool _erasing = false;
  int _hold = 0;
  bool _static = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _static = MediaQuery.disableAnimationsOf(context);
    _timer?.cancel();
    if (!_static) {
      _timer = Timer.periodic(const Duration(milliseconds: 42), _step);
    }
  }

  void _step(Timer _) {
    if (!mounted) return;
    final full = context.tr(_prompts[_prompt]).characters.length;
    setState(() {
      if (_hold > 0) {
        _hold--;
      } else if (!_erasing) {
        _chars++;
        if (_chars >= full) {
          _chars = full;
          _erasing = true;
          _hold = 45;
        }
      } else {
        _chars -= 2;
        if (_chars <= 0) {
          _chars = 0;
          _erasing = false;
          _prompt = (_prompt + 1) % _prompts.length;
          _hold = 8;
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final full = context.tr(_prompts[_prompt]);
    final shown = _static ? full : full.characters.take(_chars).toString();
    final caretOn =
        _static || (DateTime.now().millisecondsSinceEpoch ~/ 500).isEven;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: HomeStage.glass,
        borderRadius: BorderRadius.circular(HomeSpace.radiusSmall),
        border: Border.all(color: HomeStage.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            // Reserve two lines so typing never shifts the card's layout.
            child: SizedBox(
              height: 42,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: shown),
                      TextSpan(
                        text: '|',
                        style: TextStyle(
                          color: caretOn ? HomeStage.gold : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: HomeType.body(HomeStage.ink, size: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.arrow_upward_rounded,
            size: 18,
            color: HomeStage.inkMuted,
          ),
        ],
      ),
    );
  }
}
