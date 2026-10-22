import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../domain/hand_ring.dart';
import 'diamond_sim_viewport.dart';

/// Pieces laid over the full-screen stone. Only buttons take touches;
/// everything else lets gestures through to the stone.

/// In the hand view, the way back to 3D, the hand's scale, and the ring
/// the stones are set in.
class SimViewControls extends ConsumerStatefulWidget {
  const SimViewControls({required this.controller, super.key});

  final SimViewportController controller;

  @override
  ConsumerState<SimViewControls> createState() => _SimViewControlsState();
}

class _SimViewControlsState extends ConsumerState<SimViewControls> {
  bool _ringOpen = false;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final hand = ref.read(simHandProvider.notifier);
    final controller = widget.controller;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: LuxeMotion.fast,
          alignment: Alignment.bottomCenter,
          child: _ringOpen
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RingOptions(palette: p),
                )
              : const SizedBox(width: double.infinity),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              SimGlassPill(
                label: context.tr(EducationL10n.goBack),
                selected: false,
                palette: p,
                onTap: () => hand.show(false),
              ),
              const SizedBox(width: 6),
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
              const SizedBox(width: 6),
              SimGlassPill(
                label: context.tr(EducationL10n.ringStyle),
                selected: _ringOpen,
                palette: p,
                onTap: () => setState(() => _ringOpen = !_ringOpen),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: controller.handTurned,
                builder: (context, turned, _) => !turned
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: SimGlassPill(
                          label: context.tr(EducationL10n.resetView),
                          selected: false,
                          palette: p,
                          onTap: () => controller.handRecentre.value++,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The ring's metal, claws and band width.
class _RingOptions extends ConsumerWidget {
  const _RingOptions({required this.palette});

  final LuxePalette palette;

  static String _metalKey(RingMetal m) => switch (m) {
    RingMetal.yellowGold => EducationL10n.ringYellowGold,
    RingMetal.whiteGold => EducationL10n.ringWhiteGold,
    RingMetal.roseGold => EducationL10n.ringRoseGold,
    RingMetal.platinum => EducationL10n.ringPlatinum,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = palette;
    final ring = ref.watch(simHandProvider.select((h) => h.ring));
    final hand = ref.read(simHandProvider.notifier);
    void set(RingStyle r) => hand.setRing(r);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final m in RingMetal.values) ...[
            _MetalSwatch(
              metal: m,
              label: context.tr(_metalKey(m)),
              selected: ring.metal == m,
              palette: p,
              onTap: () => set(ring.copyWith(metal: m)),
            ),
            const SizedBox(width: 6),
          ],
          const SizedBox(width: 4),
          for (final c in RingProngs.values) ...[
            SimGlassPill(
              label: context.tr(
                c == RingProngs.four
                    ? EducationL10n.ringClaws4
                    : EducationL10n.ringClaws6,
              ),
              selected: ring.prongs == c,
              palette: p,
              onTap: () => set(ring.copyWith(prongs: c)),
            ),
            const SizedBox(width: 6),
          ],
          const SizedBox(width: 4),
          _BandStepper(ring: ring, palette: p, onChanged: set),
        ],
      ),
    );
  }
}

class _MetalSwatch extends StatelessWidget {
  const _MetalSwatch({
    required this.metal,
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final RingMetal metal;
  final String label;
  final bool selected;
  final LuxePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppHaptics.selection();
            onTap();
          },
          child: AnimatedContainer(
            duration: LuxeMotion.fast,
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(5),
            decoration: ShapeDecoration(
              color: const Color(0x8C101010),
              shape: CircleBorder(
                side: BorderSide(
                  color: selected
                      ? palette.accent.withValues(alpha: 0.9)
                      : LuxeStage.glassBorder,
                  width: selected ? 1.6 : 1,
                ),
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(metal.swatch, const Color(0xFFFFFFFF), 0.45)!,
                    metal.swatch,
                    Color.lerp(metal.swatch, const Color(0xFF000000), 0.35)!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Band width, a quarter millimetre a step.
class _BandStepper extends StatelessWidget {
  const _BandStepper({
    required this.ring,
    required this.palette,
    required this.onChanged,
  });

  final RingStyle ring;
  final LuxePalette palette;
  final ValueChanged<RingStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    Widget step(IconData icon, String label, double delta, bool enabled) =>
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: !enabled
                ? null
                : () {
                    AppHaptics.selection();
                    onChanged(ring.copyWith(bandWidth: ring.bandWidth + delta));
                  },
            child: SizedBox(
              width: 34,
              height: 36,
              child: Icon(
                icon,
                size: 16,
                color: enabled ? p.ink : p.ink.withValues(alpha: 0.3),
              ),
            ),
          ),
        );
    return Container(
      height: 36,
      decoration: const ShapeDecoration(
        color: Color(0x8C101010),
        shape: StadiumBorder(side: BorderSide(color: LuxeStage.glassBorder)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          step(
            Icons.remove,
            context.tr(EducationL10n.ringBandNarrower),
            -0.25,
            ring.bandWidth > RingStyle.minBandWidth + 1e-6,
          ),
          Text(
            '${context.tr(EducationL10n.ringBand)} '
            '${ring.bandWidth.toStringAsFixed(2).replaceFirst(RegExp(r"0$"), "")} mm',
            style: LuxeType.label(p.ink, size: 12.5),
          ),
          step(
            Icons.add,
            context.tr(EducationL10n.ringBandWider),
            0.25,
            ring.bandWidth < RingStyle.maxBandWidth - 1e-6,
          ),
        ],
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
