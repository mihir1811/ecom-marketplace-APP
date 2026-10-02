import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../diamonds/application/diamond_search_provider.dart';
import '../../../diamonds/domain/models/diamond_filter_state.dart';
import '../home_content.dart';
import '../theme/home_tokens.dart';
import 'home_section.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';

/// Coverflow of diamond shapes; the centred shape opens matching results.
class HomeShapeAtelier extends ConsumerStatefulWidget {
  const HomeShapeAtelier({super.key});

  @override
  ConsumerState<HomeShapeAtelier> createState() => _HomeShapeAtelierState();
}

class _HomeShapeAtelierState extends ConsumerState<HomeShapeAtelier> {
  static const _initial = 1;
  final _controller = PageController(
    viewportFraction: 0.34,
    initialPage: _initial,
  );
  int _current = _initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _explore() {
    final shape = HomeContent.shapes[_current].name;
    ref
        .read(diamondSearchProvider.notifier)
        .replaceFilters(DiamondFilterState(shapes: [shape]));
    context.openRoute(AppRouteNames.diamondResults);
  }

  void _onTapItem(int index) {
    if (index == _current) {
      _explore();
      return;
    }
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 650),
      curve: HomeMotion.settle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final gutter = homeGutter(context);
    final shape = HomeContent.shapes[_current].name;

    return Padding(
      padding: const EdgeInsets.only(top: HomeSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: HomeSectionHeading(
              index: '03',
              eyebrow: context.tr(HomeL10n.shapesEyebrow),
              title: context.tr(HomeL10n.shapesTitle),
            ),
          ),
          const SizedBox(height: 12),
          ScrollReveal(
            child: SizedBox(
              height: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Loupe dial: turns with the carousel, scroll-linked.
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final page =
                            _controller.hasClients &&
                                _controller.position.haveDimensions
                            ? _controller.page ?? _initial.toDouble()
                            : _initial.toDouble();
                        return CustomPaint(
                          size: const Size.square(196),
                          painter: _DialPainter(
                            rotation: page * math.pi / 10,
                            color: palette.accent,
                            plate: palette.surface,
                            hairline: palette.hairline,
                          ),
                        );
                      },
                    ),
                  ),
                  PageView.builder(
                    controller: _controller,
                    itemCount: HomeContent.shapes.length,
                    onPageChanged: (i) {
                      AppHaptics.selection();
                      setState(() => _current = i);
                    },
                    itemBuilder: (context, i) => _ShapeItem(
                      controller: _controller,
                      index: i,
                      initial: _initial,
                      onTap: () => _onTapItem(i),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: HomeMotion.medium,
            switchInCurve: HomeMotion.settle,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              shape,
              key: ValueKey(shape),
              textAlign: TextAlign.center,
              style: HomeType.displayItalic(32, palette.ink),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: _explore,
              style: FilledButton.styleFrom(
                backgroundColor: palette.ink,
                foregroundColor: palette.canvas,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 16,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      context.tr(HomeL10n.exploreShape, {'shape': shape}),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeType.label(palette.canvas, size: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapeItem extends StatelessWidget {
  const _ShapeItem({
    required this.controller,
    required this.index,
    required this.initial,
    required this.onTap,
  });

  final PageController controller;
  final int index;
  final int initial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = HomeContent.shapes[index];
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final page = controller.hasClients && controller.position.haveDimensions
            ? controller.page ?? initial.toDouble()
            : initial.toDouble();
        final d = page - index;
        final ad = d.abs().clamp(0.0, 2.0);
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..translateByDouble(0.0, ad * 18, 0.0, 1.0)
          ..rotateY(d.clamp(-1.0, 1.0) * 0.6)
          ..scaleByDouble(1 - ad * 0.3, 1 - ad * 0.3, 1.0, 1.0);
        return Opacity(
          opacity: (1 - ad * 0.38).clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: m,
            child: child,
          ),
        );
      },
      child: Semantics(
        button: true,
        label: shape.name,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Image.asset(
              shape.image,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => const Icon(Icons.diamond_outlined),
            ),
          ),
        ),
      ),
    );
  }
}

/// Jeweller's-loupe dial: a plate with a ring of fine graduations.
class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.rotation,
    required this.color,
    required this.plate,
    required this.hairline,
  });

  final double rotation;
  final Color color;
  final Color plate;
  final Color hairline;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(
      c,
      r - 14,
      Paint()
        ..shader = RadialGradient(
          colors: [plate, plate.withValues(alpha: 0)],
          stops: const [0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r - 14)),
    );
    canvas.drawCircle(
      c,
      r - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = hairline,
    );
    final tick = Paint()
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.7);
    for (var i = 0; i < 72; i++) {
      final a = rotation + i * math.pi * 2 / 72;
      final major = i % 6 == 0;
      tick.strokeWidth = major ? 1.4 : 0.8;
      final inner = r - (major ? 12 : 8);
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * inner,
        c + Offset(math.cos(a), math.sin(a)) * (r - 3),
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.rotation != rotation || old.color != color || old.plate != plate;
}
