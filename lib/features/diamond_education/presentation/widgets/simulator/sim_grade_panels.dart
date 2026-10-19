import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../domain/diamond_grades.dart';
import '../../../domain/diamond_spec.dart';
import '../../sim_labels.dart';
import 'sim_controls.dart';

Color _rgb(SimRgb c) => Color.fromRGBO(
  (c.r * 255).round(),
  (c.g * 255).round(),
  (c.b * 255).round(),
  1,
);

/// Face-up tint of a D–Z grade, for the scale bar.
Color colorGradeSwatch(ColorGrade g) {
  final a = g.absorption;
  double t(double v) => math.exp(-v * 3.2);
  return _rgb((r: t(a.r), g: t(a.g), b: t(a.b)));
}

/// D–Z grade or a natural fancy colour.
class SimColorPanel extends ConsumerWidget {
  const SimColorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(
      diamondSimulatorProvider.select(
        (s) => (
          grade: s.spec.colorGrade,
          fancy: s.spec.fancyColor,
          intensity: s.spec.fancyIntensity,
        ),
      ),
    );
    final c = ref.read(diamondSimulatorProvider.notifier);
    final p = LuxePalette.of(context);
    final fancy = s.fancy != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuxeSegmented<bool>(
          options: const [false, true],
          selected: fancy,
          dense: true,
          height: 40,
          labelOf: (v) => context.tr(
            v ? EducationL10n.fancyColors : EducationL10n.colorScale,
          ),
          onChanged: (v) => v
              ? c.setFancyColor(s.fancy ?? FancyColor.yellow)
              : c.useColorScale(),
        ),
        const SizedBox(height: 12),
        if (!fancy) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(s.grade.label, style: LuxeType.display(28, p.ink)),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    context.colorGroupName(s.grade.group),
                    style: LuxeType.label(p.accent, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ColorScaleBar(selected: s.grade),
          Slider(
            value: s.grade.index.toDouble(),
            max: ColorGrade.values.length - 1.0,
            divisions: ColorGrade.values.length - 1,
            activeColor: p.accent,
            inactiveColor: p.hairline,
            semanticFormatterCallback: (v) =>
                ColorGrade.values[v.round()].label,
            onChanged: (v) => c.setColorGrade(ColorGrade.values[v.round()]),
          ),
        ] else ...[
          SimLabel(context.tr(EducationL10n.color)),
          SimChoiceChips<FancyColor>(
            options: FancyColor.values,
            selected: s.fancy,
            labelOf: context.fancyName,
            swatchOf: (f) => _rgb(f.swatch),
            onSelected: c.setFancyColor,
          ),
          const SizedBox(height: 18),
          SimLabel(context.tr(EducationL10n.intensity)),
          SimChoiceChips<FancyIntensity>(
            options: FancyIntensity.values,
            selected: s.intensity,
            labelOf: context.fancyIntensityName,
            onSelected: c.setFancyIntensity,
          ),
        ],
      ],
    );
  }
}

/// The D–Z scale as a strip of swatches with its group bands.
class _ColorScaleBar extends StatelessWidget {
  const _ColorScaleBar({required this.selected});

  final ColorGrade selected;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return ExcludeSemantics(
      child: Column(
        children: [
          SizedBox(
            height: 22,
            child: Row(
              children: [
                for (final g in ColorGrade.values)
                  Expanded(
                    child: AnimatedContainer(
                      duration: LuxeMotion.fast,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        color: colorGradeSwatch(g),
                        borderRadius: BorderRadius.circular(2),
                        border: g == selected
                            ? Border.all(color: p.accent, width: 2)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final g in ColorGroup.values)
                Expanded(
                  flex: ColorGrade.values.where((c) => c.group == g).length,
                  child: Text(
                    '${ColorGrade.values.firstWhere((c) => c.group == g).label}'
                    '–${ColorGrade.values.lastWhere((c) => c.group == g).label}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: LuxeType.label(
                      g == selected.group ? p.ink : p.inkFaint,
                      size: 10.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// FL to I3, with what each grade means.
class SimClarityPanel extends ConsumerWidget {
  const SimClarityPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grade = ref.watch(
      diamondSimulatorProvider.select((s) => s.spec.clarity),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimChoiceChips<ClarityGrade>(
          options: ClarityGrade.values,
          selected: grade,
          labelOf: (g) => g.label,
          onSelected: ref.read(diamondSimulatorProvider.notifier).setClarity,
        ),
      ],
    );
  }
}

/// Carat weight with true-to-scale size and millimetre dimensions.
class SimCaratPanel extends ConsumerWidget {
  const SimCaratPanel({super.key});

  // A square-root slider gives fine control over small stones.
  static double _toSlider(double ct) => math.sqrt(
    (ct - DiamondSpec.minCarat) / (DiamondSpec.maxCarat - DiamondSpec.minCarat),
  );
  static double _fromSlider(double v) {
    final ct =
        DiamondSpec.minCarat +
        v * v * (DiamondSpec.maxCarat - DiamondSpec.minCarat);
    return (ct * 100).round() / 100;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(
      diamondSimulatorProvider.select(
        (s) => (carat: s.spec.carat, l: s.lengthMm, w: s.widthMm, d: s.depthMm),
      ),
    );
    final c = ref.read(diamondSimulatorProvider.notifier);
    final p = LuxePalette.of(context);
    String mm(double v) => v.toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              s.carat.toStringAsFixed(2),
              style: LuxeType.display(28, p.ink),
            ),
            const SizedBox(width: 6),
            Text('ct', style: LuxeType.label(p.inkMuted, size: 16)),
            const Spacer(),
            Flexible(
              child: Text(
                '${mm(s.l)} × ${mm(s.w)} × ${mm(s.d)} mm',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuxeType.figure(p.accent, size: 13),
              ),
            ),
          ],
        ),
        Slider(
          value: _toSlider(s.carat).clamp(0.0, 1.0),
          activeColor: p.accent,
          inactiveColor: p.hairline,
          semanticFormatterCallback: (v) =>
              '${_fromSlider(v).toStringAsFixed(2)} ct',
          onChanged: (v) => c.setCarat(_fromSlider(v)),
        ),
        SimChoiceChips<double>(
          options: const [0.5, 1.0, 1.5, 2.0, 3.0, 5.0],
          selected: s.carat,
          labelOf: (v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} ct',
          onSelected: c.setCarat,
        ),
      ],
    );
  }
}

/// Glow strength and colour, and the light to see it in.
class SimFluorescencePanel extends ConsumerWidget {
  const SimFluorescencePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(
      diamondSimulatorProvider.select(
        (s) => (
          intensity: s.spec.fluorescence,
          color: s.spec.fluorescenceColor,
          lighting: s.lighting,
        ),
      ),
    );
    final c = ref.read(diamondSimulatorProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimLabel(context.tr(EducationL10n.lighting)),
        LuxeSegmented<SimLighting>(
          options: const [SimLighting.daylight, SimLighting.ultraviolet],
          // The hearts & arrows scope is chosen from the cut panel.
          selected: s.lighting == SimLighting.ultraviolet
              ? SimLighting.ultraviolet
              : SimLighting.daylight,
          dense: true,
          height: 40,
          labelOf: (l) => context.tr(
            l == SimLighting.daylight
                ? EducationL10n.daylight
                : EducationL10n.uvLight,
          ),
          onChanged: c.setLighting,
        ),
        const SizedBox(height: 18),
        SimLabel(context.tr(EducationL10n.intensity)),
        SimChoiceChips<FluorescenceIntensity>(
          options: FluorescenceIntensity.values,
          selected: s.intensity,
          labelOf: context.fluorescenceName,
          onSelected: c.setFluorescence,
        ),
        const SizedBox(height: 18),
        SimLabel(context.tr(EducationL10n.glowColor)),
        SimChoiceChips<FluorescenceColor>(
          options: FluorescenceColor.values,
          selected: s.color,
          enabled: s.intensity != FluorescenceIntensity.none,
          labelOf: context.fluorescenceColorName,
          swatchOf: (f) => _rgb((r: f.r, g: f.g, b: f.b)),
          onSelected: c.setFluorescenceColor,
        ),
      ],
    );
  }
}
