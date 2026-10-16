import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../../../core/widgets/luxe/luxe_button.dart';
import '../../../domain/diamond_grades.dart';
import '../../../domain/diamond_proportions.dart';
import '../../../domain/diamond_shape.dart';
import '../../sim_labels.dart';
import '../diamond_profile_diagram.dart';
import 'edu_blocks.dart';

/// Parts of a diamond on a labelled profile.
class EduAnatomySection extends StatelessWidget {
  const EduAnatomySection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final parts = [
      (EducationL10n.table, EducationL10n.partTable),
      (EducationL10n.crown, EducationL10n.partCrown),
      (EducationL10n.girdle, EducationL10n.partGirdle),
      (EducationL10n.pavilion, EducationL10n.partPavilion),
      (EducationL10n.culet, EducationL10n.partCulet),
      (EducationL10n.depth, EducationL10n.partDepth),
    ];
    return EduSection(
      children: [
        EduSectionHeader(
          eyebrow: context.tr(EducationL10n.anatomyEyebrow),
          title: context.tr(EducationL10n.anatomyTitle),
          body: context.tr(EducationL10n.anatomyBody),
        ),
        const SizedBox(height: 18),
        EduCard(
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 12),
          child: DiamondProfileDiagram(
            height: 210,
            proportions: DiamondProportions.ideal(
              SimShape.round,
            ).copyWith(girdle: GirdleThickness.slightlyThick),
            labels: DiamondProfileLabels(
              table: context.tr(EducationL10n.table),
              crown: context.tr(EducationL10n.crown),
              girdle: context.tr(EducationL10n.girdle),
              pavilion: context.tr(EducationL10n.pavilion),
              culet: context.tr(EducationL10n.culet),
              depth: context.tr(EducationL10n.depth),
              crownAngle: context.tr(EducationL10n.crownAngle),
              pavilionAngle: context.tr(EducationL10n.pavilionAngle),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final (name, body) in parts) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  context.tr(name),
                  style: LuxeType.label(p.accent, size: 13.5),
                ),
              ),
              Expanded(
                child: Text(
                  context.tr(body),
                  style: LuxeType.body(p.inkMuted, size: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Ideal round brilliant proportions as a reference table.
class EduProportionsSection extends StatelessWidget {
  const EduProportionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final rows = [
      (EducationL10n.table, '54 – 58%'),
      (EducationL10n.depth, '59 – 62.5%'),
      (EducationL10n.crownAngle, '33.5 – 35.5°'),
      (EducationL10n.crownHeight, '14 – 16%'),
      (EducationL10n.pavilionAngle, '40.6 – 41°'),
      (EducationL10n.pavilionDepth, '42.5 – 43.5%'),
      (
        EducationL10n.girdle,
        '${context.girdleName(GirdleThickness.thin)} – '
            '${context.girdleName(GirdleThickness.slightlyThick)}',
      ),
      (
        EducationL10n.culet,
        '${context.culetName(CuletSize.none)} – '
            '${context.culetName(CuletSize.verySmall)}',
      ),
    ];
    return EduSection(
      children: [
        EduSectionHeader(
          eyebrow: context.tr(EducationL10n.propEyebrow),
          title: context.tr(EducationL10n.propTitle),
          body: context.tr(EducationL10n.propBody),
        ),
        const SizedBox(height: 16),
        EduCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: i == rows.length - 1
                        ? null
                        : Border(bottom: BorderSide(color: p.hairline)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(rows[i].$1),
                          style: LuxeType.label(p.ink, size: 13.5),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          rows[i].$2,
                          textAlign: TextAlign.end,
                          style: LuxeType.figure(p.accent, size: 13.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The ten shapes; each opens the simulator cut in that shape.
class EduShapesSection extends StatelessWidget {
  const EduShapesSection({required this.onOpenShape, super.key});

  final ValueChanged<SimShape> onOpenShape;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return EduSection(
      children: [
        EduSectionHeader(
          eyebrow: context.tr(EducationL10n.shapesEyebrow),
          title: context.tr(EducationL10n.shapesTitle),
          body: context.tr(EducationL10n.shapesBody),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 620 ? 3 : 2;
            final w = (c.maxWidth - 12 * (cols - 1)) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final shape in SimShape.values)
                  SizedBox(
                    width: w,
                    child: Semantics(
                      button: true,
                      label: context.shapeName(shape),
                      child: Material(
                        color: p.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(LuxeSpace.radius),
                          side: BorderSide(color: p.hairline),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => onOpenShape(shape),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      shape.svgAsset,
                                      width: 36,
                                      height: 36,
                                      colorFilter: ColorFilter.mode(
                                        p.accent,
                                        BlendMode.srcIn,
                                      ),
                                      placeholderBuilder: (_) =>
                                          const SizedBox.square(dimension: 36),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.view_in_ar_outlined,
                                      size: 16,
                                      color: p.inkFaint,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  context.shapeName(shape),
                                  style: LuxeType.display(19, p.ink),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.tr(EducationL10n.ratio, {
                                    'ratio': shape.ratio.toStringAsFixed(2),
                                  }),
                                  style: LuxeType.figure(p.inkFaint, size: 11),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  context.shapeNote(shape),
                                  style: LuxeType.body(p.inkMuted, size: 12.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Fluorescence: the scale and how to see it.
class EduFluorescenceSection extends StatelessWidget {
  const EduFluorescenceSection({required this.onOpenSimulator, super.key});

  final VoidCallback onOpenSimulator;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    const blue = FluorescenceColor.blue;
    return EduSection(
      children: [
        EduSectionHeader(
          eyebrow: context.tr(EducationL10n.fluorEyebrow),
          title: context.tr(EducationL10n.fluorTitle),
          body: context.tr(EducationL10n.fluorBody),
        ),
        const SizedBox(height: 18),
        DecoratedBox(
          decoration: BoxDecoration(
            color: LuxeStage.obsidian,
            borderRadius: BorderRadius.circular(LuxeSpace.radius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            child: Row(
              children: [
                for (final f in FluorescenceIntensity.values)
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.lerp(
                              const Color(0xFF1C1C22),
                              Color.fromRGBO(
                                (blue.r * 255).round(),
                                (blue.g * 255).round(),
                                (blue.b * 255).round(),
                                1,
                              ),
                              f.strength,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF4A80FF,
                                ).withValues(alpha: 0.7 * f.strength),
                                blurRadius: 18 * f.strength,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.fluorescenceName(f),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: LuxeType.label(LuxeStage.inkMuted, size: 11),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr(EducationL10n.fluorTip),
                style: LuxeType.body(p.inkMuted, size: 13),
              ),
            ),
            const SizedBox(width: 12),
            LuxeButton(
              label: context.tr(EducationL10n.uvLight),
              icon: Icons.light_mode_outlined,
              variant: LuxeButtonVariant.secondary,
              height: 44,
              onPressed: onOpenSimulator,
            ),
          ],
        ),
      ],
    );
  }
}

/// Natural and lab-grown, side by side.
class EduOriginSection extends StatelessWidget {
  const EduOriginSection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final rows = [
      (
        EducationL10n.rowOrigin,
        EducationL10n.rowOriginNatural,
        EducationL10n.rowOriginLab,
      ),
      (
        EducationL10n.rowMaterial,
        EducationL10n.rowMaterialNatural,
        EducationL10n.rowMaterialLab,
      ),
      (
        EducationL10n.rowPrice,
        EducationL10n.rowPriceNatural,
        EducationL10n.rowPriceLab,
      ),
      (
        EducationL10n.rowReport,
        EducationL10n.rowReportNatural,
        EducationL10n.rowReportLab,
      ),
    ];
    Widget cell(String text, {bool head = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Text(
        text,
        style: head
            ? LuxeType.label(p.ink, size: 13)
            : LuxeType.body(p.inkMuted, size: 12.5),
      ),
    );
    return EduSection(
      children: [
        EduSectionHeader(
          eyebrow: context.tr(EducationL10n.labEyebrow),
          title: context.tr(EducationL10n.labTitle),
          body: context.tr(EducationL10n.labBody),
        ),
        const SizedBox(height: 16),
        EduCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(0.8),
              1: FlexColumnWidth(1.1),
              2: FlexColumnWidth(1.1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.hairline)),
                ),
                children: [
                  const SizedBox.shrink(),
                  cell(context.tr(EducationL10n.natural), head: true),
                  cell(context.tr(EducationL10n.labGrown), head: true),
                ],
              ),
              for (final (label, natural, lab) in rows)
                TableRow(
                  children: [
                    cell(context.tr(label), head: true),
                    cell(context.tr(natural)),
                    cell(context.tr(lab)),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Grading reports and the major laboratories.
class EduCertificationSection extends StatelessWidget {
  const EduCertificationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final labs = [
      ('GIA', EducationL10n.certGia),
      ('IGI', EducationL10n.certIgi),
      ('HRD', EducationL10n.certHrd),
    ];
    final p = LuxePalette.of(context);
    return EduSection(
      children: [
        EduSectionHeader(
          eyebrow: context.tr(EducationL10n.certEyebrow),
          title: context.tr(EducationL10n.certTitle),
          body: context.tr(EducationL10n.certBody),
        ),
        const SizedBox(height: 16),
        for (final (name, body) in labs) ...[
          EduPoint(
            leading: Container(
              width: 52,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(name, style: LuxeType.label(p.accent, size: 12.5)),
            ),
            title: name,
            body: context.tr(body),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Buying tips and care.
class EduTipsSection extends StatelessWidget {
  const EduTipsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final tips = [
      EducationL10n.tip1,
      EducationL10n.tip2,
      EducationL10n.tip3,
      EducationL10n.tip4,
      EducationL10n.tip5,
    ];
    return EduSection(
      children: [
        EduSectionHeader(
          eyebrow: context.tr(EducationL10n.tipsEyebrow),
          title: context.tr(EducationL10n.tipsTitle),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < tips.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: Text('0${i + 1}', style: LuxeType.display(20, p.accent)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    context.tr(tips[i]),
                    style: LuxeType.body(p.ink, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 8),
        EduCard(
          child: EduPoint(
            icon: Icons.cleaning_services_outlined,
            title: context.tr(EducationL10n.careTitle),
            body: context.tr(EducationL10n.careBody),
          ),
        ),
      ],
    );
  }
}

/// Closing call to action.
class EduFinalCta extends StatelessWidget {
  const EduFinalCta({
    required this.onOpenSimulator,
    required this.onBrowse,
    super.key,
  });

  final VoidCallback onOpenSimulator;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return EduSection(
      children: [
        EduDarkScope(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [LuxeStage.vaultTop, LuxeStage.vaultBottom],
              ),
              borderRadius: BorderRadius.circular(LuxeSpace.radius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(EducationL10n.ctaTitle),
                    style: LuxeType.display(28, LuxeStage.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(EducationL10n.ctaBody),
                    style: LuxeType.body(LuxeStage.inkMuted),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      LuxeButton(
                        label: context.tr(EducationL10n.simCta),
                        icon: Icons.view_in_ar_outlined,
                        variant: LuxeButtonVariant.accent,
                        onPressed: onOpenSimulator,
                      ),
                      LuxeButton(
                        label: context.tr(EducationL10n.ctaBrowse),
                        variant: LuxeButtonVariant.ghost,
                        trailingIcon: Icons.arrow_forward_rounded,
                        onPressed: onBrowse,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
