import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../diamond_education/domain/diamond_grades.dart';
import '../../../diamond_education/domain/diamond_proportions.dart';
import '../../../diamond_education/domain/diamond_shape.dart';
import '../../../diamond_education/domain/diamond_spec.dart';
import '../../../diamond_education/presentation/sim_labels.dart';
import '../../../diamond_education/presentation/widgets/simulator/sim_controls.dart';
import '../../../diamond_education/presentation/widgets/simulator/sim_grade_panels.dart';
import '../../application/jewelry_simulator_controller.dart';
import '../../domain/jewelry_design.dart';
import '../../domain/jewelry_metal.dart';
import '../jewelry_labels.dart';

/// The simulator's tools; which ones a piece offers depends on its type.
enum JewelryTool { metal, stone, setting, band, style, chain }

extension JewelryToolsOf on JewelryDesign {
  List<JewelryTool> get tools => switch (type) {
    JewelryType.ring => const [
      JewelryTool.metal,
      JewelryTool.stone,
      JewelryTool.setting,
      JewelryTool.band,
    ],
    JewelryType.earrings => [
      JewelryTool.metal,
      JewelryTool.style,
      JewelryTool.stone,
      if (earringStyle != EarringStyle.hoop) JewelryTool.setting,
    ],
    JewelryType.necklace => const [
      JewelryTool.metal,
      JewelryTool.stone,
      JewelryTool.setting,
      JewelryTool.chain,
    ],
    JewelryType.bracelet => const [
      JewelryTool.metal,
      JewelryTool.style,
      JewelryTool.stone,
    ],
  };
}

const _gap = SizedBox(height: 16);

JewelrySimulatorController _c(WidgetRef ref) =>
    ref.read(jewelrySimulatorProvider.notifier);

JewelryDesign _watch(WidgetRef ref) =>
    ref.watch(jewelrySimulatorProvider.select((s) => s.design));

/// Metal, purity and finish.
class JewelryMetalPanel extends ConsumerWidget {
  const JewelryMetalPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = _watch(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimLabel(context.tr(JewelryEduL10n.toolMetal)),
        SimChoiceChips<JewelryMetal>(
          options: JewelryMetal.values,
          selected: d.metal,
          labelOf: context.metalName,
          swatchOf: MetalSwatch.of,
          onSelected: (m) => _c(ref).update((d) => d.copyWith(metal: m)),
        ),
        _gap,
        SimLabel(context.tr(JewelryEduL10n.purity)),
        SimChoiceChips<MetalPurity>(
          options: d.metal.purities,
          selected: d.purity,
          labelOf: (p) => '${p.label} · ${(p.fineness * 1000).round()}',
          onSelected: (p) => _c(ref).update((d) => d.copyWith(purity: p)),
        ),
        _gap,
        SimLabel(context.tr(JewelryEduL10n.finish)),
        SimChoiceChips<MetalFinish>(
          options: MetalFinish.values,
          selected: d.finish,
          labelOf: context.finishName,
          onSelected: (f) => _c(ref).update((d) => d.copyWith(finish: f)),
        ),
        const SizedBox(height: 12),
        SimNote(context.tr(JewelryEduL10n.metalNote)),
      ],
    );
  }
}

/// The centre stone: shape, carat, colour and clarity. A stone brought
/// from the diamond simulator keeps every other grade it was given.
class JewelryStonePanel extends ConsumerWidget {
  const JewelryStonePanel({super.key});

  static double _toSlider(double ct) => math.sqrt(
    (ct - DiamondSpec.minCarat) / (DiamondSpec.maxCarat - DiamondSpec.minCarat),
  );

  static double _fromSlider(double v) =>
      ((DiamondSpec.minCarat +
                  v * v * (DiamondSpec.maxCarat - DiamondSpec.minCarat)) *
              100)
          .round() /
      100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = _watch(ref);
    final handed = ref.watch(jewelryStoneHandoffProvider) != null;
    final s = d.stone;
    final p = LuxePalette.of(context);
    void stone(DiamondSpec Function(DiamondSpec s) f) =>
        _c(ref).update((d) => d.copyWith(stone: f(d.stone)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (handed) ...[
          Row(
            children: [
              Icon(Icons.diamond_outlined, size: 16, color: p.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr(JewelryEduL10n.yourDiamond),
                  style: LuxeType.label(p.accent, size: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (!d.hasCentreStone) ...[
          SimNote(context.tr(JewelryEduL10n.noCentreStone)),
          _gap,
        ] else ...[
          SimLabel(context.tr(EducationL10n.shape)),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: SimShape.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final shape = SimShape.values[i];
                final on = shape == s.shape;
                final color = on ? p.accent : p.inkMuted;
                return Semantics(
                  button: true,
                  selected: on,
                  label: context.shapeName(shape),
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (on) return;
                      AppHaptics.selection();
                      stone(
                        (s) => s.copyWith(
                          shape: shape,
                          proportions: DiamondProportions.ideal(shape),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: LuxeMotion.fast,
                      width: 58,
                      decoration: BoxDecoration(
                        color: on ? p.accentSoft : p.surface,
                        borderRadius: BorderRadius.circular(
                          LuxeSpace.radiusSmall,
                        ),
                        border: Border.all(color: on ? p.accent : p.hairline),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            shape.svgAsset,
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              color,
                              BlendMode.srcIn,
                            ),
                            placeholderBuilder: (_) =>
                                const SizedBox.square(dimension: 24),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            context.shapeName(shape),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuxeType.label(color, size: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _gap,
          SimSlider(
            label: context.tr(EducationL10n.carat),
            valueText: '${s.carat.toStringAsFixed(2)} ct',
            value: _toSlider(s.carat),
            min: 0,
            max: 1,
            onChanged: (v) => stone((s) => s.copyWith(carat: _fromSlider(v))),
          ),
          _gap,
        ],
        SimLabel(context.tr(EducationL10n.color)),
        SimChoiceChips<ColorGrade>(
          options: ColorGrade.values.take(10).toList(),
          selected: s.isFancy ? null : s.colorGrade,
          labelOf: (g) => g.label,
          swatchOf: colorGradeSwatch,
          onSelected: (g) =>
              stone((s) => s.copyWith(colorGrade: g, clearFancy: true)),
        ),
        _gap,
        SimLabel(context.tr(EducationL10n.clarity)),
        SimChoiceChips<ClarityGrade>(
          options: ClarityGrade.values,
          selected: s.clarity,
          labelOf: (g) => g.label,
          onSelected: (g) => stone((s) => s.copyWith(clarity: g)),
        ),
        const SizedBox(height: 12),
        SimNote(context.tr(JewelryEduL10n.stoneNote)),
      ],
    );
  }
}

/// How the centre stone is held, its halo, and a ring's extras.
class JewelrySettingPanel extends ConsumerWidget {
  const JewelrySettingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = _watch(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimLabel(context.tr(JewelryEduL10n.head)),
        SimChoiceChips<HeadStyle>(
          options: HeadStyle.values,
          selected: d.head,
          labelOf: context.headName,
          onSelected: (h) => _c(ref).update((d) => d.copyWith(head: h)),
        ),
        _gap,
        SimLabel(context.tr(JewelryEduL10n.halo)),
        SimChoiceChips<HaloStyle>(
          options: HaloStyle.values,
          selected: d.halo,
          labelOf: context.haloName,
          onSelected: (h) => _c(ref).update((d) => d.copyWith(halo: h)),
        ),
        if (d.type == JewelryType.ring) ...[
          const SizedBox(height: 8),
          SimSwitch(
            label: context.tr(JewelryEduL10n.threeStone),
            value: d.threeStone,
            onChanged: (v) => _c(ref).update((d) => d.copyWith(threeStone: v)),
          ),
          SimSwitch(
            label: context.tr(JewelryEduL10n.cathedral),
            value: d.cathedral,
            onChanged: (v) => _c(ref).update((d) => d.copyWith(cathedral: v)),
          ),
        ],
        const SizedBox(height: 12),
        SimNote(context.tr(JewelryEduL10n.settingNote)),
      ],
    );
  }
}

/// A ring's band: profile, width, size and band stones.
class JewelryBandPanel extends ConsumerWidget {
  const JewelryBandPanel({super.key});

  static String _size(double s) {
    final whole = s.floor();
    final frac = s - whole;
    final mark = switch ((frac * 4).round()) {
      1 => '¼',
      2 => '½',
      3 => '¾',
      _ => '',
    };
    return '$whole$mark';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = _watch(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimLabel(context.tr(JewelryEduL10n.profile)),
        SimChoiceChips<BandProfile>(
          options: BandProfile.values,
          selected: d.bandProfile,
          labelOf: context.profileName,
          onSelected: (p) => _c(ref).update((d) => d.copyWith(bandProfile: p)),
        ),
        _gap,
        SimSlider(
          label: context.tr(JewelryEduL10n.bandWidth),
          valueText: '${d.bandWidthMm.toStringAsFixed(1)} mm',
          value: d.bandWidthMm,
          min: JewelryDesign.minBandWidth,
          max: JewelryDesign.maxBandWidth,
          divisions: 25,
          onChanged: (v) => _c(ref).update((d) => d.copyWith(bandWidthMm: v)),
        ),
        _gap,
        SimSlider(
          label: context.tr(JewelryEduL10n.ringSize),
          valueText: context.tr(JewelryEduL10n.ringSizeValue, {
            'size': _size(d.ringSize),
            'mm': RingSizes.diameterMm(d.ringSize).toStringAsFixed(1),
          }),
          value: d.ringSize,
          min: RingSizes.min,
          max: RingSizes.max,
          divisions: 40,
          onChanged: (v) => _c(ref).update((d) => d.copyWith(ringSize: v)),
        ),
        _gap,
        SimLabel(context.tr(JewelryEduL10n.bandStones)),
        SimChoiceChips<BandAccent>(
          options: BandAccent.values,
          selected: d.bandAccent,
          labelOf: context.accentName,
          onSelected: (a) => _c(ref).update((d) => d.copyWith(bandAccent: a)),
        ),
      ],
    );
  }
}

/// Earring or bracelet style and its own options.
class JewelryStylePanel extends ConsumerWidget {
  const JewelryStylePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = _watch(ref);
    final c = _c(ref);
    if (d.type == JewelryType.earrings) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SimChoiceChips<EarringStyle>(
            options: EarringStyle.values,
            selected: d.earringStyle,
            labelOf: context.earringName,
            onSelected: (e) => c.update((d) => d.copyWith(earringStyle: e)),
          ),
          if (d.earringStyle == EarringStyle.hoop) ...[
            _gap,
            SimSlider(
              label: context.tr(JewelryEduL10n.hoopSize),
              valueText: '${d.hoopDiameterMm.round()} mm',
              value: d.hoopDiameterMm,
              min: JewelryDesign.minHoop,
              max: JewelryDesign.maxHoop,
              divisions: 26,
              onChanged: (v) => c.update((d) => d.copyWith(hoopDiameterMm: v)),
            ),
            _gap,
            SimLabel(context.tr(JewelryEduL10n.hoopStones)),
            SimChoiceChips<BandAccent>(
              options: BandAccent.values,
              selected: d.bandAccent,
              labelOf: context.accentName,
              onSelected: (a) => c.update((d) => d.copyWith(bandAccent: a)),
            ),
          ],
          const SizedBox(height: 12),
          SimNote(context.tr(JewelryEduL10n.earringNote)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimChoiceChips<BraceletStyle>(
          options: BraceletStyle.values,
          selected: d.braceletStyle,
          labelOf: context.braceletName,
          onSelected: (b) => c.update((d) => d.copyWith(braceletStyle: b)),
        ),
        _gap,
        SimSlider(
          label: context.tr(JewelryEduL10n.braceletLength),
          valueText:
              '${d.braceletLengthIn.toStringAsFixed(2)}" · ${(d.braceletLengthIn * 25.4).round()} mm',
          value: d.braceletLengthIn,
          min: JewelryDesign.minBracelet,
          max: JewelryDesign.maxBracelet,
          divisions: 8,
          onChanged: (v) => c.update((d) => d.copyWith(braceletLengthIn: v)),
        ),
        _gap,
        switch (d.braceletStyle) {
          BraceletStyle.tennis => SimSlider(
            label: context.tr(JewelryEduL10n.stoneSize),
            valueText: '${d.accentStoneMm.toStringAsFixed(1)} mm',
            value: d.accentStoneMm,
            min: JewelryDesign.minAccent,
            max: JewelryDesign.maxAccent,
            divisions: 22,
            onChanged: (v) => c.update((d) => d.copyWith(accentStoneMm: v)),
          ),
          BraceletStyle.bangle => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SimLabel(context.tr(JewelryEduL10n.bandStones)),
              SimChoiceChips<BandAccent>(
                options: BandAccent.values,
                selected: d.bandAccent,
                labelOf: context.accentName,
                onSelected: (a) => c.update((d) => d.copyWith(bandAccent: a)),
              ),
            ],
          ),
          BraceletStyle.chain => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SimLabel(context.tr(JewelryEduL10n.chainStyle)),
              SimChoiceChips<ChainStyle>(
                options: ChainStyle.values,
                selected: d.chainStyle,
                labelOf: context.chainName,
                onSelected: (s) => c.update((d) => d.copyWith(chainStyle: s)),
              ),
            ],
          ),
        },
        const SizedBox(height: 12),
        SimNote(context.tr(JewelryEduL10n.braceletNote)),
      ],
    );
  }
}

/// A necklace's chain: style, length (where it falls) and width.
class JewelryChainPanel extends ConsumerWidget {
  const JewelryChainPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = _watch(ref);
    final c = _c(ref);
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimLabel(context.tr(JewelryEduL10n.chainStyle)),
        SimChoiceChips<ChainStyle>(
          options: ChainStyle.values,
          selected: d.chainStyle,
          labelOf: context.chainName,
          onSelected: (s) => c.update((d) => d.copyWith(chainStyle: s)),
        ),
        _gap,
        SimLabel(context.tr(JewelryEduL10n.chainLength)),
        SimChoiceChips<ChainLength>(
          options: ChainLength.values,
          selected: d.chainLength,
          labelOf: (l) => '${l.inches}" · ${l.mm.round()} mm',
          onSelected: (l) => c.update((d) => d.copyWith(chainLength: l)),
        ),
        const SizedBox(height: 8),
        Text(
          context.lengthNote(d.chainLength),
          style: LuxeType.label(p.accent, size: 12.5),
        ),
        _gap,
        SimSlider(
          label: context.tr(JewelryEduL10n.chainWidth),
          valueText: '${d.chainWidthMm.toStringAsFixed(1)} mm',
          value: d.chainWidthMm,
          min: JewelryDesign.minChainWidth,
          max: JewelryDesign.maxChainWidth,
          divisions: 20,
          onChanged: (v) => c.update((d) => d.copyWith(chainWidthMm: v)),
        ),
      ],
    );
  }
}
