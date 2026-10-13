import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../diamond_projects/application/diamond_project_listing_pick_provider.dart';
import '../../../diamond_projects/application/diamond_selection.dart';
import '../../application/comparison_provider.dart';

/// Round compare button that sits in the dock's row, after Profile.
///
/// It fills the box the dock gives it (the dock sizes and folds it along
/// with itself). A ring of four arcs fills as pieces are selected. With one
/// to four selected it opens the comparison; with none, or more than four
/// (seller picks kept for the diamond project), it stays muted and a tap
/// explains why in a pill that rises above it.
class CompareDockButton extends ConsumerStatefulWidget {
  const CompareDockButton({
    required this.visible,
    required this.diamondListing,
    required this.onOpen,
    super.key,
  });

  final bool visible;

  /// Seller picks drive the count on diamond listings.
  final bool diamondListing;
  final VoidCallback onOpen;

  /// Diameter beside the expanded and the folded dock.
  static const double size = 56;
  static const double compactSize = 44;

  @override
  ConsumerState<CompareDockButton> createState() => _CompareDockButtonState();
}

class _CompareDockButtonState extends ConsumerState<CompareDockButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _pop = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.14,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.14,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_pulse);

  String? _hint;
  Timer? _hintTimer;

  @override
  void didUpdateWidget(CompareDockButton old) {
    super.didUpdateWidget(old);
    if (!widget.visible && _hint != null) _dismissHint();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _showHint(String text) {
    _hintTimer?.cancel();
    setState(() => _hint = text);
    _hintTimer = Timer(const Duration(milliseconds: 2600), _dismissHint);
  }

  void _dismissHint() {
    _hintTimer?.cancel();
    if (mounted && _hint != null) setState(() => _hint = null);
  }

  int _count() {
    final seller = ref.watch(canPickDiamondsProvider);
    if (widget.diamondListing && seller) {
      return ref.watch(
        diamondProjectListingPickProvider.select((s) => s.length),
      );
    }
    return ref.watch(comparisonProvider.select((s) => s.count));
  }

  void _pulseOnGrowth(int? prev, int next) {
    if (prev != null &&
        next > prev &&
        mounted &&
        !MediaQuery.disableAnimationsOf(context)) {
      _pulse.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final count = _count();
    final over = count > ComparisonState.maxItems;
    final ready = count > 0 && !over;

    ref.listen<int>(comparisonProvider.select((s) => s.count), _pulseOnGrowth);
    ref.listen<int>(diamondProjectListingPickProvider.select((s) => s.length), (
      prev,
      next,
    ) {
      if (widget.diamondListing) _pulseOnGrowth(prev, next);
    });

    final label = ready
        ? context.tr(AccountCommerceL10n.compareFabOpen, {'count': count})
        : over
        ? context.tr(AccountCommerceL10n.compareFabOver, {'count': count})
        : context.tr(AccountCommerceL10n.compareFabEmpty);

    return LayoutBuilder(
      builder: (context, box) {
        final size = math.min(box.maxWidth, box.maxHeight);
        return IgnorePointer(
          ignoring: !widget.visible,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 0,
                bottom: size + 12,
                child: _HintPill(text: _hint),
              ),
              Positioned.fill(
                child: Semantics(
                  button: true,
                  enabled: ready,
                  label: label,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (ready) {
                        AppHaptics.medium();
                        _dismissHint();
                        widget.onOpen();
                      } else {
                        AppHaptics.warning();
                        _showHint(label);
                      }
                    },
                    child: ScaleTransition(
                      scale: _pop,
                      child: _Face(
                        count: count,
                        ready: ready,
                        over: over,
                        palette: p,
                        compact: size < 50,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.count,
    required this.ready,
    required this.over,
    required this.palette,
    required this.compact,
  });

  final int count;
  final bool ready;
  final bool over;
  final LuxePalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(
            end: math.min(count, ComparisonState.maxItems).toDouble(),
          ),
          duration: LuxeMotion.medium,
          curve: LuxeMotion.settle,
          builder: (context, filled, _) => TweenAnimationBuilder<double>(
            tween: Tween(end: ready ? 1 : 0),
            duration: LuxeMotion.medium,
            curve: LuxeMotion.settle,
            builder: (context, live, _) => CustomPaint(
              painter: _FacePainter(
                filled: filled,
                live: live,
                over: over,
                palette: p,
              ),
            ),
          ),
        ),
        Positioned(
          top: compact ? -4 : -2,
          right: compact ? -4 : -2,
          child: AnimatedSwitcher(
            duration: LuxeMotion.fast,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: count == 0
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(count),
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: over ? p.caution : p.accent,
                      shape: StadiumBorder(
                        side: BorderSide(color: p.canvas, width: 2),
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: LuxeType.figure(
                        over ? Colors.white : p.onAccent,
                        size: 11,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Four-arc slot ring, the disc, and a glyph of two interlocking rings
/// whose shared lens lights up when the comparison is ready.
class _FacePainter extends CustomPainter {
  _FacePainter({
    required this.filled,
    required this.live,
    required this.over,
    required this.palette,
  });

  /// 0–4, fractional while animating.
  final double filled;

  /// 0 muted → 1 ready.
  final double live;
  final bool over;
  final LuxePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Slot ring.
    final ringR = r - 1.6;
    const gap = 0.32;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < ComparisonState.maxItems; i++) {
      final start = -math.pi / 2 + i * math.pi / 2 + gap / 2;
      const sweep = math.pi / 2 - gap;
      ring.color = over ? p.caution.withValues(alpha: 0.7) : p.hairline;
      final rect = Rect.fromCircle(center: c, radius: ringR);
      canvas.drawArc(rect, start, sweep, false, ring);
      if (!over) {
        final part = (filled - i).clamp(0.0, 1.0);
        if (part > 0) {
          ring.color = p.accent;
          canvas.drawArc(rect, start, sweep * part, false, ring);
        }
      }
    }

    // Disc.
    final discR = r - 5.5;
    final disc = Color.lerp(p.surface, p.ink, live)!;
    canvas.drawCircle(
      c.translate(0, 3),
      discR,
      Paint()
        ..color = Colors.black.withValues(alpha: p.isDark ? 0.5 : 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(c, discR, Paint()..color = disc);
    if (live < 1) {
      canvas.drawCircle(
        c,
        discR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = p.hairline.withValues(alpha: 1 - live),
      );
    }

    // Glyph.
    final g = discR * 0.36;
    final dx = discR * 0.2;
    final a = Rect.fromCircle(center: c.translate(-dx, 0), radius: g);
    final b = Rect.fromCircle(center: c.translate(dx, 0), radius: g);
    final lens = Path.combine(
      PathOperation.intersect,
      Path()..addOval(a),
      Path()..addOval(b),
    );
    canvas.drawPath(
      lens,
      Paint()..color = p.accent.withValues(alpha: 0.25 + 0.75 * live),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Color.lerp(p.inkMuted, p.canvas, live)!;
    canvas
      ..drawOval(a, stroke)
      ..drawOval(b, stroke);
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.filled != filled ||
      old.live != live ||
      old.over != over ||
      old.palette != palette;
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final text = this.text;
    return AnimatedSwitcher(
      duration: LuxeMotion.medium,
      switchInCurve: LuxeMotion.settle,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.25, 0),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: text == null
          ? const SizedBox.shrink()
          : ConstrainedBox(
              key: ValueKey(text),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.62,
              ),
              child: Material(
                color: p.ink,
                shape: const StadiumBorder(),
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  child: Text(
                    text,
                    maxLines: 2,
                    textAlign: TextAlign.right,
                    style: LuxeType.label(p.canvas, size: 12.5),
                  ),
                ),
              ),
            ),
    );
  }
}
