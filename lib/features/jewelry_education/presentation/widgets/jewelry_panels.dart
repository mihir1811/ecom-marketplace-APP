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
enum JewelryTool { metal, stone, setting, accents, band, style, chain }

extension JewelryToolsOf on JewelryDesign {
  List<JewelryTool> get tools => switch (type) {
    JewelryType.ring => const [
      JewelryTool.metal,
      JewelryTool.stone,
      JewelryTool.setting,
      JewelryTool.accents,
      JewelryTool.band,
    ],
    JewelryType.earrings => [
      JewelryTool.metal,
      JewelryTool.style,
      if (hasCentreStone) ...[JewelryTool.stone, JewelryTool.setting],
      JewelryTool.accents,
    ],
    JewelryType.necklace => const [
      JewelryTool.metal,
      JewelryTool.stone,
      JewelryTool.setting,
      JewelryTool.accents,
      JewelryTool.chain,
    ],
    JewelryType.bracelet => [
      JewelryTool.metal,
      JewelryTool.style,
      if (braceletStyle == BraceletStyle.tennis) JewelryTool.stone,
      if (braceletStyle == BraceletStyle.bangle) JewelryTool.accents,
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
        if (d.takesTwoTone) ...[
          _gap,
          SimLabel(context.tr(JewelryEduL10n.settingMetal)),
          SimChoiceChips<JewelryMetal?>(
            options: [
              null,
              for (final m in JewelryMetal.values)
                if (m != d.metal) m,
            ],
            selected: d.headMetal,
            labelOf: (m) => m == null
                ? context.tr(JewelryEduL10n.sameMetal)
                : context.metalName(m),
            swatchOf: (m) => MetalSwatch.of(m ?? d.metal),
            onSelected: (m) => _c(ref).update(
              (d) => m == null
                  ? d.copyWith(clearHeadMetal: true)
                  : d.copyWith(headMetal: m),
            ),
          ),
          const SizedBox(height: 8),
          SimNote(context.tr(JewelryEduL10n.twoToneNote)),
        ],
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

/// How the centre stone is held: the head, its prongs and gallery, how
/// high it sits, which way the stone points, a ring's side stones and a
/// pendant's bail.
class JewelrySettingPanel extends ConsumerWidget {
  const JewelrySettingPanel({super.key});

  static const _pointed = {
    SimShape.pear,
    SimShape.marquise,
    SimShape.heart,
    SimShape.princess,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = _watch(ref);
    final c = _c(ref);
    final prongs = !d.headSpec.isBezel;
    final ring = d.type == JewelryType.ring;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimLabel(context.tr(JewelryEduL10n.head)),
        SimChoiceChips<HeadStyle>(
          options: HeadStyle.values,
          selected: d.head,
          labelOf: context.headName,
          onSelected: (h) => c.update((d) => d.copyWith(head: h)),
        ),
        if (prongs) ...[
          _gap,
          SimLabel(context.tr(JewelryEduL10n.prongTip)),
          SimChoiceChips<ProngTip>(
            options: [
              for (final t in ProngTip.values)
                if (t != ProngTip.vTip || _pointed.contains(d.stone.shape)) t,
            ],
            selected: d.prongTip,
            labelOf: context.tipName,
            onSelected: (t) => c.update((d) => d.copyWith(prongTip: t)),
          ),
          _gap,
          SimLabel(context.tr(JewelryEduL10n.gallery)),
          SimChoiceChips<GalleryStyle>(
            options: GalleryStyle.values,
            selected: d.gallery,
            labelOf: context.galleryName,
            onSelected: (g) => c.update((d) => d.copyWith(gallery: g)),
          ),
        ],
        if (ring) ...[
          _gap,
          SimLabel(context.tr(JewelryEduL10n.settingHeight)),
          SimChoiceChips<SettingHeight>(
            options: SettingHeight.values,
            selected: d.settingHeight,
            labelOf: context.heightName,
            onSelected: (h) => c.update((d) => d.copyWith(settingHeight: h)),
          ),
          _gap,
          SimLabel(context.tr(JewelryEduL10n.orientation)),
          SimChoiceChips<bool>(
            options: const [false, true],
            selected: d.eastWest,
            labelOf: (ew) => context.tr(
              ew ? JewelryEduL10n.eastWest : JewelryEduL10n.northSouth,
            ),
            onSelected: (ew) => c.update((d) => d.copyWith(eastWest: ew)),
          ),
          const SizedBox(height: 8),
          SimSwitch(
            label: context.tr(JewelryEduL10n.threeStone),
            value: d.threeStone,
            onChanged: (v) => c.update((d) => d.copyWith(threeStone: v)),
          ),
        ],
        if (d.type == JewelryType.necklace) ...[
          _gap,
          SimLabel(context.tr(JewelryEduL10n.bail)),
          SimChoiceChips<BailStyle>(
            options: BailStyle.values,
            selected: d.bail,
            labelOf: context.bailName,
            onSelected: (b) => c.update((d) => d.copyWith(bail: b)),
          ),
        ],
        const SizedBox(height: 12),
        SimNote(context.tr(JewelryEduL10n.settingNote)),
        const SizedBox(height: 8),
        SimNote(context.tr(JewelryEduL10n.headNote)),
      ],
    );
  }
}

/// Small stones and detail: halo, hidden halo, stones along a band, hoop
/// or bangle and how they are set, and milgrain edges.
class JewelryAccentsPanel extends ConsumerWidget {
  const JewelryAccentsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = _watch(ref);
    final c = _c(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (d.takesHalo) ...[
          SimLabel(context.tr(JewelryEduL10n.halo)),
          SimChoiceChips<HaloStyle>(
            options: HaloStyle.values,
            selected: d.halo,
            labelOf: context.haloName,
            onSelected: (h) => c.update((d) => d.copyWith(halo: h)),
          ),
          const SizedBox(height: 8),
          SimSwitch(
            label: context.tr(JewelryEduL10n.hiddenHalo),
            value: d.hiddenHalo,
            onChanged: (v) => c.update((d) => d.copyWith(hiddenHalo: v)),
          ),
          _gap,
        ],
        if (d.takesBandStones) ...[
          SimLabel(
            context.tr(
              d.type == JewelryType.earrings
                  ? JewelryEduL10n.hoopStones
                  : JewelryEduL10n.bandStones,
            ),
          ),
          SimChoiceChips<BandAccent>(
            options: BandAccent.values,
            selected: d.bandAccent,
            labelOf: context.accentName,
            onSelected: (a) => c.update((d) => d.copyWith(bandAccent: a)),
          ),
          if (d.bandAccent != BandAccent.plain) ...[
            _gap,
            SimLabel(context.tr(JewelryEduL10n.accentSetting)),
            SimChoiceChips<AccentSetting>(
              options: AccentSetting.values,
              selected: d.accentSetting,
              labelOf: context.accentSettingName,
              onSelected: (a) => c.update((d) => d.copyWith(accentSetting: a)),
            ),
          ],
          _gap,
        ],
        SimSwitch(
          label: context.tr(JewelryEduL10n.milgrain),
          value: d.milgrain,
          onChanged: (v) => c.update((d) => d.copyWith(milgrain: v)),
        ),
        const SizedBox(height: 12),
        SimNote(context.tr(JewelryEduL10n.accentsNote)),
      ],
    );
  }
}

/// A ring's band: shank, cathedral, profile, width and size.
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
    final c = _c(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimLabel(context.tr(JewelryEduL10n.shank)),
        SimChoiceChips<ShankStyle>(
          options: ShankStyle.values,
          selected: d.shank,
          labelOf: context.shankName,
          onSelected: (s) => c.update((d) => d.copyWith(shank: s)),
        ),
        const SizedBox(height: 8),
        SimSwitch(
          label: context.tr(JewelryEduL10n.cathedral),
          value: d.cathedral,
          onChanged: (v) => c.update((d) => d.copyWith(cathedral: v)),
        ),
        _gap,
        SimLabel(context.tr(JewelryEduL10n.profile)),
        SimChoiceChips<BandProfile>(
          options: BandProfile.values,
          selected: d.bandProfile,
          labelOf: context.profileName,
          onSelected: (p) => c.update((d) => d.copyWith(bandProfile: p)),
        ),
        _gap,
        SimSlider(
          label: context.tr(JewelryEduL10n.bandWidth),
          valueText: '${d.bandWidthMm.toStringAsFixed(1)} mm',
          value: d.bandWidthMm,
          min: JewelryDesign.minBandWidth,
          max: JewelryDesign.maxBandWidth,
          divisions: 25,
          onChanged: (v) => c.update((d) => d.copyWith(bandWidthMm: v)),
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
          onChanged: (v) => c.update((d) => d.copyWith(ringSize: v)),
        ),
        const SizedBox(height: 12),
        SimNote(context.tr(JewelryEduL10n.bandNote)),
      ],
    );
  }
}

/// Earring or bracelet style and its own construction.
class JewelryStylePanel extends ConsumerWidget {
  const JewelryStylePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = _watch(ref);
    return d.type == JewelryType.earrings
        ? _earrings(context, ref, d)
        : _bracelet(context, ref, d);
  }

  Widget _earrings(BuildContext context, WidgetRef ref, JewelryDesign d) {
    final c = _c(ref);
    final hoop =
        d.earringStyle == EarringStyle.hoop ||
        d.earringStyle == EarringStyle.huggie;
    final huggie = d.earringStyle == EarringStyle.huggie;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SimChoiceChips<EarringStyle>(
          options: EarringStyle.values,
          selected: d.earringStyle,
          labelOf: context.earringName,
          onSelected: (e) => c.update(
            (d) => d.copyWith(
              earringStyle: e,
              // Keep the size in each style's own range.
              hoopDiameterMm: e == EarringStyle.huggie
                  ? 12
                  : e == EarringStyle.hoop && d.hoopDiameterMm < 14
                  ? 22
                  : null,
            ),
          ),
        ),
        if (d.earringStyle == EarringStyle.stud ||
            (d.earringStyle == EarringStyle.drop &&
                d.dropFitting == DropFitting.post)) ...[
          _gap,
          SimLabel(context.tr(JewelryEduL10n.earringBack)),
          SimChoiceChips<EarringBack>(
            options: EarringBack.values,
            selected: d.earringBack,
            labelOf: context.backName,
            onSelected: (b) => c.update((d) => d.copyWith(earringBack: b)),
          ),
        ],
        if (d.earringStyle == EarringStyle.drop) ...[
          _gap,
          SimLabel(context.tr(JewelryEduL10n.fitting)),
          SimChoiceChips<DropFitting>(
            options: DropFitting.values,
            selected: d.dropFitting,
            labelOf: context.fittingName,
            onSelected: (f) => c.update((d) => d.copyWith(dropFitting: f)),
          ),
          _gap,
          SimSlider(
            label: context.tr(JewelryEduL10n.dropLength),
            valueText: context.tr(JewelryEduL10n.linksValue, {
              'count': d.dropLinks,
            }),
            value: d.dropLinks.toDouble(),
            min: JewelryDesign.minDropLinks.toDouble(),
            max: JewelryDesign.maxDropLinks.toDouble(),
            divisions: JewelryDesign.maxDropLinks - JewelryDesign.minDropLinks,
            onChanged: (v) => c.update((d) => d.copyWith(dropLinks: v.round())),
          ),
        ],
        if (hoop) ...[
          _gap,
          SimSlider(
            label: context.tr(JewelryEduL10n.hoopSize),
            valueText: '${d.hoopDiameterMm.round()} mm',
            value: d.hoopDiameterMm,
            min: huggie ? JewelryDesign.minHuggie : JewelryDesign.minHoop,
            max: huggie ? JewelryDesign.maxHuggie : JewelryDesign.maxHoop,
            divisions: huggie ? 8 : 26,
            onChanged: (v) => c.update((d) => d.copyWith(hoopDiameterMm: v)),
          ),
          if (!huggie) ...[
            _gap,
            SimLabel(context.tr(JewelryEduL10n.shapeLabel)),
            SimChoiceChips<HoopShape>(
              options: HoopShape.values,
              selected: d.hoopShape,
              labelOf: context.hoopShapeName,
              onSelected: (s) => c.update((d) => d.copyWith(hoopShape: s)),
            ),
            _gap,
            SimSlider(
              label: context.tr(JewelryEduL10n.thickness),
              valueText: '${d.hoopWireMm.toStringAsFixed(1)} mm',
              value: d.hoopWireMm,
              min: JewelryDesign.minHoopWire,
              max: JewelryDesign.maxHoopWire,
              divisions: 14,
              onChanged: (v) => c.update((d) => d.copyWith(hoopWireMm: v)),
            ),
          ],
          _gap,
          SimLabel(context.tr(JewelryEduL10n.closure)),
          SimChoiceChips<HoopClosure>(
            options: HoopClosure.values,
            selected: d.hoopClosure,
            labelOf: context.closureName,
            onSelected: (h) => c.update((d) => d.copyWith(hoopClosure: h)),
          ),
        ],
        const SizedBox(height: 12),
        SimNote(context.tr(JewelryEduL10n.earringNote)),
      ],
    );
  }

  Widget _bracelet(BuildContext context, WidgetRef ref, JewelryDesign d) {
    final c = _c(ref);
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
        ...switch (d.braceletStyle) {
          BraceletStyle.tennis => [
            SimLabel(context.tr(JewelryEduL10n.accentSetting)),
            SimChoiceChips<TennisSetting>(
              options: TennisSetting.values,
              selected: d.tennisSetting,
              labelOf: context.tennisSettingName,
              onSelected: (t) => c.update((d) => d.copyWith(tennisSetting: t)),
            ),
            _gap,
            SimSlider(
              label: context.tr(JewelryEduL10n.stoneSize),
              valueText: '${d.accentStoneMm.toStringAsFixed(1)} mm',
              value: d.accentStoneMm,
              min: JewelryDesign.minAccent,
              max: JewelryDesign.maxAccent,
              divisions: 22,
              onChanged: (v) => c.update((d) => d.copyWith(accentStoneMm: v)),
            ),
            const SizedBox(height: 8),
            SimSwitch(
              label: context.tr(JewelryEduL10n.safetyLatch),
              value: d.safetyLatch,
              onChanged: (v) => c.update((d) => d.copyWith(safetyLatch: v)),
            ),
          ],
          BraceletStyle.bangle => [
            SimLabel(context.tr(JewelryEduL10n.bangleStyle)),
            SimChoiceChips<BangleStyle>(
              options: BangleStyle.values,
              selected: d.bangleStyle,
              labelOf: context.bangleName,
              onSelected: (b) => c.update((d) => d.copyWith(bangleStyle: b)),
            ),
            _gap,
            SimLabel(context.tr(JewelryEduL10n.shapeLabel)),
            SimChoiceChips<BangleShape>(
              options: BangleShape.values,
              selected: d.bangleShape,
              labelOf: context.bangleShapeName,
              onSelected: (s) => c.update((d) => d.copyWith(bangleShape: s)),
            ),
            _gap,
            SimSlider(
              label: context.tr(JewelryEduL10n.width),
              valueText: '${d.bangleWidthMm.toStringAsFixed(1)} mm',
              value: d.bangleWidthMm,
              min: JewelryDesign.minBangleWidth,
              max: JewelryDesign.maxBangleWidth,
              divisions: 16,
              onChanged: (v) => c.update((d) => d.copyWith(bangleWidthMm: v)),
            ),
            _gap,
            SimLabel(context.tr(JewelryEduL10n.profile)),
            SimChoiceChips<BandProfile>(
              options: BandProfile.values,
              selected: d.bandProfile,
              labelOf: context.profileName,
              onSelected: (p) => c.update((d) => d.copyWith(bandProfile: p)),
            ),
          ],
          BraceletStyle.chain => [
            SimLabel(context.tr(JewelryEduL10n.chainStyle)),
            SimChoiceChips<ChainStyle>(
              options: ChainStyle.values,
              selected: d.chainStyle,
              labelOf: context.chainName,
              onSelected: (s) => c.update((d) => d.copyWith(chainStyle: s)),
            ),
            _gap,
            SimSlider(
              label: context.tr(JewelryEduL10n.chainWidth),
              valueText: '${(d.chainWidthMm + 0.6).toStringAsFixed(1)} mm',
              value: d.chainWidthMm,
              min: JewelryDesign.minChainWidth,
              max: JewelryDesign.maxChainWidth,
              divisions: 20,
              onChanged: (v) => c.update((d) => d.copyWith(chainWidthMm: v)),
            ),
            _gap,
            SimLabel(context.tr(JewelryEduL10n.clasp)),
            SimChoiceChips<ClaspStyle>(
              options: ClaspStyle.values,
              selected: d.clasp,
              labelOf: context.claspName,
              onSelected: (s) => c.update((d) => d.copyWith(clasp: s)),
            ),
            _gap,
            SimLabel(context.tr(JewelryEduL10n.charms)),
            SimChoiceChips<int>(
              options: JewelryDesign.charmCounts,
              selected: d.charms,
              labelOf: (n) => n == 0 ? context.tr(JewelryEduL10n.none) : '$n',
              onSelected: (n) => c.update((d) => d.copyWith(charms: n)),
            ),
          ],
        },
        const SizedBox(height: 12),
        SimNote(context.tr(JewelryEduL10n.braceletNote)),
      ],
    );
  }
}

/// A necklace's chain: style, length (where it falls), width, a Y drop
/// and diamond stations.
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
        _gap,
        SimSlider(
          label: context.tr(JewelryEduL10n.yDrop),
          valueText: d.yDropMm <= 0
              ? context.tr(JewelryEduL10n.off)
              : '${d.yDropMm.round()} mm',
          value: d.yDropMm,
          min: 0,
          max: JewelryDesign.maxYDrop,
          divisions: 12,
          onChanged: (v) => c.update((d) => d.copyWith(yDropMm: v)),
        ),
        _gap,
        SimLabel(context.tr(JewelryEduL10n.stations)),
        SimChoiceChips<int>(
          options: JewelryDesign.stationCounts,
          selected: d.stations,
          labelOf: (n) => n == 0 ? context.tr(JewelryEduL10n.none) : '$n',
          onSelected: (n) => c.update((d) => d.copyWith(stations: n)),
        ),
        const SizedBox(height: 12),
        SimNote(context.tr(JewelryEduL10n.chainNote)),
      ],
    );
  }
}
