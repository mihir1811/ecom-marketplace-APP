import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../domain/average_hand.dart';
import '../../sim_labels.dart';
import 'diamond_sim_viewport.dart';

/// Pieces laid over the full-screen stone. Only buttons take touches;
/// everything else lets gestures through to the stone.

/// Estimated cut and the selected stone's grades, top left.
class SimSummary extends ConsumerWidget {
  const SimSummary({super.key});

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
    final finger = ref.watch(
      simHandProvider.select((h) => h.onHand ? h.active : null),
    );
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr(EducationL10n.estimatedCut).toUpperCase(),
          style: LuxeType.eyebrow(p.inkFaint),
        ),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: LuxeMotion.fast,
          child: Text(
            context.cutName(s.cut),
            key: ValueKey(s.cut),
            style: LuxeType.display(20, p.accent),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          [
            if (finger != null) context.fingerName(finger),
            context.shapeName(s.shape),
            '${s.carat.toStringAsFixed(2)} ct',
            s.color,
            s.clarity,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LuxeType.label(p.inkMuted, size: 12),
        ),
      ],
    );
  }
}

/// A millimetre bar at the stone's true on-screen scale.
class SimScaleBar extends ConsumerWidget {
  const SimScaleBar({
    required this.controller,
    required this.viewport,
    super.key,
  });

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

/// Average hand measurements, for reference in the hand view.
class SimHandFacts extends StatelessWidget {
  const SimHandFacts({super.key});

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final size = AverageHand.ring.usRingSize;
    final half = (size * 2).round() / 2;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x99101010),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LuxeStage.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr(EducationL10n.handTitle),
              style: LuxeType.label(p.ink, size: 11.5),
            ),
            const SizedBox(height: 2),
            Text(
              context.tr(EducationL10n.handFacts, {
                'length': AverageHand.lengthCm.toStringAsFixed(1),
                'palm': AverageHand.palmCm.toStringAsFixed(1),
                'size': half % 1 == 0
                    ? half.toStringAsFixed(0)
                    : half.toStringAsFixed(1),
              }),
              style: LuxeType.label(p.inkMuted, size: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Camera presets, auto-spin and the hand view, as words; in the hand
/// view, the way back to 3D and the hand's scale.
class SimViewControls extends ConsumerWidget {
  const SimViewControls({required this.controller, super.key});

  final SimViewportController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final onHand = ref.watch(simHandProvider.select((h) => h.onHand));
    final hand = ref.read(simHandProvider.notifier);
    String label(SimViewPreset v) => context.tr(switch (v) {
      SimViewPreset.faceUp => EducationL10n.viewFaceUp,
      SimViewPreset.angled => EducationL10n.viewAngled,
      SimViewPreset.profile => EducationL10n.viewProfile,
      SimViewPreset.pavilion => EducationL10n.viewPavilion,
    });

    List<Widget> pills() {
      if (onHand) {
        return [
          SimGlassPill(
            label: context.tr(EducationL10n.goBack),
            selected: false,
            palette: p,
            onTap: () => hand.show(false),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: controller.lifeSize,
            builder: (context, life, _) => SimGlassPill(
              label: context.tr(
                life ? EducationL10n.fitHand : EducationL10n.lifeSize,
              ),
              selected: life,
              palette: p,
              onTap: () => controller.lifeSize.value = !life,
            ),
          ),
        ];
      }
      return [
        for (final v in SimViewPreset.values)
          SimGlassPill(
            label: label(v),
            selected: controller.preset == v,
            palette: p,
            onTap: () => controller.show(v),
          ),
        SimGlassPill(
          label: context.tr(EducationL10n.autoSpin),
          selected: controller.autoRotate,
          palette: p,
          onTap: () => controller.autoRotate = !controller.autoRotate,
        ),
        SimGlassPill(
          label: context.tr(EducationL10n.onHand),
          selected: false,
          palette: p,
          onTap: () => hand.show(true),
        ),
      ];
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (final pill in pills()) ...[pill, const SizedBox(width: 6)],
          ],
        ),
      ),
    );
  }
}

/// A frosted pill of text over the stage.
class SimGlassPill extends StatelessWidget {
  const SimGlassPill({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
    this.height = 36,
    super.key,
  });

  final String label;
  final bool selected;
  final LuxePalette palette;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final fg = selected ? p.accent : p.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: LuxeMotion.fast,
          height: height,
          constraints: const BoxConstraints(minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: const Color(0x8C101010),
            shape: StadiumBorder(
              side: BorderSide(
                color: selected
                    ? p.accent.withValues(alpha: 0.8)
                    : LuxeStage.glassBorder,
              ),
            ),
          ),
          child: Text(label, style: LuxeType.label(fg, size: 12.5)),
        ),
      ),
    );
  }
}
