import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/live_format.dart';
import '../../domain/models/live_show_models.dart';
import 'live_stage_tokens.dart';

/// Full-stage moment for a win: the video blurs back, champagne sparks
/// burst on real gravity, and the piece is presented in a turning ring of
/// light with the price and the way to the order.
class LiveWonOverlay extends StatelessWidget {
  const LiveWonOverlay({
    required this.lot,
    required this.orderId,
    required this.onViewOrder,
    required this.onClose,
    super.key,
  });

  final LiveAuctionLot lot;
  final String? orderId;
  final ValueChanged<String> onViewOrder;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final hasOrder = orderId != null && orderId!.isNotEmpty;

    Widget enter(Widget w, int i) => still
        ? w
        : w
              .animate(delay: (140 + i * 90).ms)
              .fadeIn(duration: 380.ms)
              .moveY(
                begin: 16,
                end: 0,
                duration: 520.ms,
                curve: LiveMotion.emphasized,
              );

    Widget hero = _HaloImage(url: lot.image);
    if (!still) {
      hero = hero
          .animate()
          .scaleXY(
            begin: 0.4,
            end: 1,
            duration: 760.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: 240.ms);
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        hero,
        const SizedBox(height: 26),
        enter(
          Text(
            'SOLD TO YOU',
            style: LiveType.eyebrow(color: LiveStage.champagne, size: 11),
          ),
          0,
        ),
        const SizedBox(height: 8),
        enter(Text("It's yours.", style: LiveType.display(52)), 1),
        const SizedBox(height: 10),
        enter(
          Text(
            lot.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: LiveType.body(15, color: LiveStage.ink),
          ),
          2,
        ),
        const SizedBox(height: 6),
        enter(
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (r) => LiveStage.champagneGradient.createShader(r),
            child: Text(
              liveInr(lot.currentBid ?? 0),
              style: LiveType.display(34),
            ),
          ),
          3,
        ),
        const SizedBox(height: 12),
        enter(
          Text(
            'Paid from your wallet. The seller ships it to your delivery address.',
            textAlign: TextAlign.center,
            style: LiveType.body(12.5, color: LiveStage.inkFaint),
          ),
          4,
        ),
        const SizedBox(height: 28),
        enter(
          AnimatedSwitcher(
            duration: LiveMotion.base,
            child: LiveButton(
              key: ValueKey(hasOrder),
              label: hasOrder ? 'View order' : 'Creating your order…',
              icon: hasOrder ? Icons.receipt_long_outlined : null,
              busy: !hasOrder,
              onTap: hasOrder ? () => onViewOrder(orderId!) : null,
            ),
          ),
          5,
        ),
        const SizedBox(height: 10),
        enter(
          LiveButton(
            label: 'Keep watching',
            kind: LiveButtonKind.ghost,
            onTap: onClose,
          ),
          6,
        ),
      ],
    );

    Widget backdrop = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.25),
            radius: 1.1,
            colors: [
              const Color(0xFF2A2114).withValues(alpha: 0.82),
              Colors.black.withValues(alpha: 0.92),
            ],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
    if (!still) backdrop = backdrop.animate().fadeIn(duration: 300.ms);

    return Positioned.fill(
      child: Semantics(
        liveRegion: true,
        label: 'You won ${lot.title} for ${liveInr(lot.currentBid ?? 0)}',
        child: GestureDetector(
          onTap: onClose,
          child: Stack(
            fit: StackFit.expand,
            children: [
              backdrop,
              if (!still) const IgnorePointer(child: _Sparks()),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: GestureDetector(onTap: () {}, child: content),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lot image inside a slowly turning champagne ring.
class _HaloImage extends StatelessWidget {
  const _HaloImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    Widget ring = Container(
      width: 148,
      height: 148,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            LiveStage.champagneDeep,
            LiveStage.champagneLight,
            LiveStage.champagne,
            Colors.white,
            LiveStage.champagneDeep,
          ],
        ),
      ),
    );
    if (!still) {
      ring = ring
          .animate(onPlay: (c) => c.repeat())
          .rotate(duration: 6.seconds, begin: 0, end: 1);
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: LiveStage.champagne.withValues(alpha: 0.4),
            blurRadius: 60,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ring,
          Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: LiveStage.void_,
            ),
          ),
          ClipOval(child: LiveThumb(url: url, size: 128, radius: 64)),
        ],
      ),
    );
  }
}

class _Spark {
  _Spark._(
    this.x,
    this.y,
    this.vx,
    this.vy,
    this.spin,
    this.size,
    this.kind,
    this.tint,
    this.delay,
  );

  /// Mostly upward fan from just above the halo.
  factory _Spark(math.Random r, Size size) {
    final a = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.2;
    final speed = 380 + r.nextDouble() * 720;
    return _Spark._(
      size.width / 2 + (r.nextDouble() - 0.5) * 40,
      size.height * 0.36,
      math.cos(a) * speed,
      math.sin(a) * speed,
      (r.nextDouble() - 0.5) * 10,
      3 + r.nextDouble() * 6,
      r.nextInt(3),
      r.nextInt(4),
      r.nextDouble() * 0.25,
    );
  }

  double x;
  double y;
  double vx;
  double vy;
  double rot = 0;
  final double spin;
  final double size;
  final int kind;
  final int tint;
  final double delay;
}

class _Sparks extends StatefulWidget {
  const _Sparks();

  @override
  State<_Sparks> createState() => _SparksState();
}

class _SparksState extends State<_Sparks> with SingleTickerProviderStateMixin {
  static const _life = 2.8;
  final _rng = math.Random();
  final _clock = ValueNotifier<double>(0);
  List<_Spark>? _sparks;
  late final Ticker _ticker = createTicker(_tick);
  double _last = 0;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  void _tick(Duration e) {
    final t = e.inMicroseconds / 1e6;
    final dt = (t - _last).clamp(0.0, 1 / 30);
    _last = t;
    final sparks = _sparks;
    if (sparks != null) {
      for (final s in sparks) {
        if (t < s.delay) continue;
        s
          ..vy += 980 * dt
          ..vx *= math.pow(0.35, dt).toDouble()
          ..vy *= math.pow(0.55, dt).toDouble()
          ..x += s.vx * dt
          ..y += s.vy * dt
          ..rot += s.spin * dt;
      }
    }
    _clock.value = t;
    if (t > _life) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        _sparks ??= List.generate(110, (_) => _Spark(_rng, box.biggest));
        return RepaintBoundary(
          child: CustomPaint(
            painter: _SparkPainter(_sparks!, _clock, _life),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.sparks, this.clock, this.life) : super(repaint: clock);

  final List<_Spark> sparks;
  final ValueNotifier<double> clock;
  final double life;

  static const _tints = [
    LiveStage.champagne,
    LiveStage.champagneLight,
    Colors.white,
    LiveStage.champagneDeep,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final fade = (1 - (t - 1.6) / (life - 1.6)).clamp(0.0, 1.0);
    for (final s in sparks) {
      if (t < s.delay) continue;
      final paint = Paint()..color = _tints[s.tint].withValues(alpha: fade);
      canvas
        ..save()
        ..translate(s.x, s.y)
        ..rotate(s.rot);
      final r = s.size;
      switch (s.kind) {
        case 0:
          // Four-point glint.
          final p = Path()
            ..moveTo(0, -r * 1.6)
            ..quadraticBezierTo(0, 0, r * 1.6, 0)
            ..quadraticBezierTo(0, 0, 0, r * 1.6)
            ..quadraticBezierTo(0, 0, -r * 1.6, 0)
            ..quadraticBezierTo(0, 0, 0, -r * 1.6)
            ..close();
          canvas.drawPath(p, paint);
        case 1:
          // Little diamond.
          final p = Path()
            ..moveTo(0, -r)
            ..lineTo(r * 0.7, 0)
            ..lineTo(0, r)
            ..lineTo(-r * 0.7, 0)
            ..close();
          canvas.drawPath(p, paint);
        default:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: r * 0.6,
              height: r * 1.6,
            ),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => false;
}
