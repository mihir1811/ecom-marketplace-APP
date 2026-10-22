import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/widgets/luxe/luxe_button.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../domain/cut_grade_estimator.dart';
import '../../../domain/diamond_grades.dart';
import '../../../domain/diamond_proportions.dart';
import '../../sim_labels.dart';
import '../diamond_profile_diagram.dart';
import 'diamond_sim_viewport.dart';
import 'sim_controls.dart';

/// Cut grade presets, then every cutting proportion to customise the cut.
/// Round brilliants get the grades and the hearts & arrows scope; other
/// shapes, which carry no cut grade, the proportions alone.
class SimCutPanel extends ConsumerWidget {
  const SimCutPanel({required this.viewport, super.key});

  final SimViewportController viewport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grade = ref.watch(
      diamondSimulatorProvider.select((s) => s.estimatedCut),
    );
    final round = ref.watch(
      diamondSimulatorProvider.select((s) => s.spec.shape.showsHeartsArrows),
    );
    // A scope cannot sit on a finger.
    final onHand = ref.watch(simHandProvider.select((h) => h.onHand));
    if (!round) return const SimProportionsPanel();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimChoiceChips<CutGrade>(
          options: CutGrade.values,
          selected: grade,
          labelOf: context.cutName,
          onSelected: ref.read(diamondSimulatorProvider.notifier).applyCutGrade,
        ),
        if (!onHand) ...[
          const SizedBox(height: 6),
          _HeartsArrows(viewport: viewport),
        ],
        const SizedBox(height: 14),
        SimLabel(context.tr(EducationL10n.proportions)),
        const SimProportionsPanel(),
      ],
    );
  }
}

/// One switch puts the stone in a hearts & arrows scope, held still face
/// up for the arrows; the Pavilion view turns it over for the hearts.
/// Round brilliants only.
class _HeartsArrows extends ConsumerWidget {
  const _HeartsArrows({required this.viewport});

  final SimViewportController viewport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(
      diamondSimulatorProvider.select(
        (s) => s.lighting == SimLighting.heartsArrows,
      ),
    );
    void toggle(bool on) {
      ref.read(diamondSimulatorProvider.notifier).setHeartsArrows(on);
      // The patterns read only with the stone held still, square on.
      viewport
        ..autoRotate = !on
        ..show(on ? SimViewPreset.faceUp : SimViewPreset.angled);
    }

    return SimSwitch(
      label: context.tr(EducationL10n.heartsArrows),
      value: on,
      onChanged: toggle,
    );
  }
}

String _pct(double v) => '${v.toStringAsFixed(1)}%';
String _deg(double v) => '${v.toStringAsFixed(1)}°';

/// Every cutting proportion, live, with the stone's profile drawn to
/// scale above the sliders.
class SimProportionsPanel extends ConsumerWidget {
  const SimProportionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(
      diamondSimulatorProvider.select(
        (s) => (
          shape: s.spec.shape,
          p: s.spec.proportions,
          depth: s.mesh.totalDepthPct,
          crown: s.mesh.crownHeightPct,
          pavilion: s.mesh.pavilionDepthPct,
        ),
      ),
    );
    final c = ref.read(diamondSimulatorProvider.notifier);
    final pr = s.p;
    final family = s.shape.family;
    final ideal = CutGradeEstimator.idealWindow(s.shape);
    String range((double, double) r, String Function(double) f) => context.tr(
      EducationL10n.idealRange,
      {'range': '${f(r.$1).replaceAll(RegExp('[%°]'), '')}–${f(r.$2)}'},
    );
    bool within((double, double) r, double v) => v >= r.$1 && v <= r.$2;
    final (chLo, chHi) = pr.crownHeightRange();
    final (pdLo, pdHi) = pr.pavilionDepthRange(family);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiamondProfileDiagram(
          proportions: pr,
          family: family,
          height: 112,
          labels: DiamondProfileLabels(
            table: _pct(pr.tablePct),
            crownAngle: _deg(pr.crownAngle),
            pavilionAngle: _deg(pr.pavilionAngle),
            depth: _pct(s.depth),
            crown: _pct(s.crown),
            pavilion: _pct(s.pavilion),
          ),
        ),
        const SizedBox(height: 8),
        SimSlider(
          label: context.tr(EducationL10n.table),
          valueText: _pct(pr.tablePct),
          value: pr.tablePct,
          min: ProportionLimits.tableMin,
          max: ProportionLimits.tableMax,
          hint: range(ideal.table, _pct),
          inIdeal: within(ideal.table, pr.tablePct),
          onChanged: c.setTable,
        ),
        SimSlider(
          label: context.tr(EducationL10n.depth),
          valueText: _pct(s.depth),
          value: s.depth,
          min: 40,
          max: 85,
          hint: range(ideal.depth, _pct),
          inIdeal: within(ideal.depth, s.depth),
          onChanged: c.setTotalDepth,
        ),
        SimSlider(
          label: context.tr(EducationL10n.crownAngle),
          valueText: _deg(pr.crownAngle),
          value: pr.crownAngle,
          min: ProportionLimits.crownAngleMin,
          max: ProportionLimits.crownAngleMax,
          hint: range(ideal.crownAngle, _deg),
          inIdeal: within(ideal.crownAngle, pr.crownAngle),
          onChanged: c.setCrownAngle,
        ),
        SimSlider(
          label: context.tr(EducationL10n.crownHeight),
          valueText: _pct(s.crown),
          value: s.crown,
          min: chLo,
          max: chHi,
          onChanged: c.setCrownHeight,
        ),
        SimSlider(
          label: context.tr(EducationL10n.pavilionAngle),
          valueText: _deg(pr.pavilionAngle),
          value: pr.pavilionAngle,
          min: ProportionLimits.pavilionAngleMin,
          max: ProportionLimits.pavilionAngleMax,
          hint: range(ideal.pavilionAngle, _deg),
          inIdeal: within(ideal.pavilionAngle, pr.pavilionAngle),
          onChanged: c.setPavilionAngle,
        ),
        SimSlider(
          label: context.tr(EducationL10n.pavilionDepth),
          valueText: _pct(s.pavilion),
          value: s.pavilion,
          min: pdLo,
          max: pdHi,
          onChanged: c.setPavilionDepth,
        ),
        SimSlider(
          label: context.tr(EducationL10n.girdle),
          valueText: context.girdleName(pr.girdle),
          value: pr.girdle.index.toDouble(),
          min: 0,
          max: GirdleThickness.values.length - 1.0,
          divisions: GirdleThickness.values.length - 1,
          inIdeal:
              pr.girdle.index >= GirdleThickness.thin.index &&
              pr.girdle.index <= GirdleThickness.slightlyThick.index,
          onChanged: (v) => c.setGirdle(GirdleThickness.values[v.round()]),
        ),
        SimSlider(
          label: context.tr(EducationL10n.culet),
          valueText: context.culetName(pr.culet),
          value: pr.culet.index.toDouble(),
          min: 0,
          max: CuletSize.values.length - 1.0,
          divisions: CuletSize.values.length - 1,
          inIdeal: pr.culet.index <= CuletSize.small.index,
          onChanged: (v) => c.setCulet(CuletSize.values[v.round()]),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: LuxeButton(
            label: context.tr(EducationL10n.resetIdeal),
            icon: Icons.auto_fix_high_outlined,
            variant: LuxeButtonVariant.secondary,
            height: 44,
            onPressed: pr == DiamondProportions.ideal(s.shape)
                ? null
                : c.resetProportions,
          ),
        ),
      ],
    );
  }
}
