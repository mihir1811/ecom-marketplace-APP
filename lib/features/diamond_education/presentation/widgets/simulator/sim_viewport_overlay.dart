import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../sim_labels.dart';
import 'diamond_sim_viewport.dart';

/// HUD over the live stone: grade summary, true-scale bar, camera
/// presets and auto-rotate. Only the buttons take touches; everything
/// else lets gestures through to the stone.
class SimViewportOverlay extends StatelessWidget {
  const SimViewportOverlay({required this.controller, super.key});

  final SimViewportController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            left: 16,
            top: 12,
            right: 16,
            child: IgnorePointer(child: _Summary()),
          ),
          const Positioned.fill(child: IgnorePointer(child: _Hint())),
          Positioned(
            left: 16,
            bottom: 62,
            child: IgnorePointer(
              child: _ScaleBar(
                controller: controller,
                viewport: constraints.biggest,
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: _ViewControls(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(
      diamondSimulatorProvider.select(
        (s) => (
          cut: s.estimatedCut,
          carat: s.spec.carat,
          color: s.spec.fancyColor == null
              ? s.spec.colorGrade.label
              : context.fancyName(s.spec.fancyColor!),
          clarity: s.spec.clarity.label,
          shape: s.spec.shape,
        ),
      ),
    );
    final p = LuxePalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(EducationL10n.estimatedCut).toUpperCase(),
                style: LuxeType.eyebrow(p.inkFaint),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: LuxeMotion.fast,
                child: Text(
                  context.cutName(s.cut),
                  key: ValueKey(s.cut),
                  style: LuxeType.display(22, p.accent),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: Text(
            '${context.shapeName(s.shape)}\n'
            '${s.carat.toStringAsFixed(2)} ct · ${s.color} · ${s.clarity}',
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: LuxeType.label(p.inkMuted, size: 12.5),
          ),
        ),
      ],
    );
  }
}

/// Shows the gesture hint briefly, then gets out of the way.
class _Hint extends StatefulWidget {
  const _Hint();

  @override
  State<_Hint> createState() => _HintState();
}

class _HintState extends State<_Hint> {
  bool _show = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _show = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Align(
      alignment: const Alignment(0, 0.62),
      child: AnimatedOpacity(
        opacity: _show ? 1 : 0,
        duration: LuxeMotion.medium,
        child: Text(
          context.tr(EducationL10n.simHint),
          textAlign: TextAlign.center,
          style: LuxeType.label(p.inkFaint, size: 11.5),
        ),
      ),
    );
  }
}

/// A millimetre bar at the stone's true on-screen scale.
class _ScaleBar extends ConsumerWidget {
  const _ScaleBar({required this.controller, required this.viewport});

  final SimViewportController controller;

  /// Size of the stone's viewport, which sets its on-screen scale.
  final Size viewport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radiusMm = ref.watch(
      diamondSimulatorProvider.select((s) => s.mesh.radius * s.mmPerUnit),
    );
    final p = LuxePalette.of(context);
    return ValueListenableBuilder<double>(
      valueListenable: controller.zoom,
      builder: (context, zoom, _) {
        final pxPerMm = SimScale.pxPerMm(viewport, radiusMm) * zoom;
        var mm = 1;
        for (final c in const [1, 2, 5, 10]) {
          if (c * pxPerMm <= 120) mm = c;
        }
        final width = mm * pxPerMm;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$mm mm', style: LuxeType.figure(p.inkMuted, size: 11)),
            const SizedBox(height: 4),
            CustomPaint(size: Size(width, 8), painter: _BarPainter(p.inkMuted)),
          ],
        );
      },
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    final y = size.height / 2;
    canvas
      ..drawLine(Offset(0, y), Offset(size.width, y), paint)
      ..drawLine(Offset.zero, Offset(0, size.height), paint)
      ..drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.color != color;
}

class _ViewControls extends StatelessWidget {
  const _ViewControls({required this.controller});

  final SimViewportController controller;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    String label(SimViewPreset v) => context.tr(switch (v) {
      SimViewPreset.faceUp => EducationL10n.viewFaceUp,
      SimViewPreset.angled => EducationL10n.viewAngled,
      SimViewPreset.profile => EducationL10n.viewProfile,
      SimViewPreset.pavilion => EducationL10n.viewPavilion,
    });

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final v in SimViewPreset.values) ...[
                    _GlassPill(
                      label: label(v),
                      selected: controller.preset == v,
                      palette: p,
                      onTap: () {
                        AppHaptics.selection();
                        controller.show(v);
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: context.tr(EducationL10n.autoRotate),
            child: _GlassPill(
              icon: controller.autoRotate
                  ? Icons.pause_rounded
                  : Icons.threesixty_rounded,
              label: context.tr(EducationL10n.autoRotate),
              iconOnly: true,
              selected: controller.autoRotate,
              palette: p,
              onTap: () {
                AppHaptics.selection();
                controller.autoRotate = !controller.autoRotate;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
    this.icon,
    this.iconOnly = false,
  });

  final String label;
  final IconData? icon;
  final bool iconOnly, selected;
  final LuxePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final fg = selected ? p.accent : p.inkMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: LuxeMotion.fast,
          height: 40,
          constraints: const BoxConstraints(minWidth: 44),
          padding: EdgeInsets.symmetric(horizontal: iconOnly ? 10 : 14),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: LuxeStage.glass,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected
                    ? p.accent.withValues(alpha: 0.7)
                    : LuxeStage.glassBorder,
              ),
            ),
          ),
          child: iconOnly
              ? Icon(icon, size: 20, color: fg)
              : Text(label, style: LuxeType.label(fg, size: 12.5)),
        ),
      ),
    );
  }
}
