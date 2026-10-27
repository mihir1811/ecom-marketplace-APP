import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../domain/diamond_grades.dart';
import '../../diamond_labels.dart';
import 'edu_blocks.dart';
import 'light_path_diagram.dart';

/// The 4Cs as a two-by-two grid; choosing one shows only that C's
/// section below it.
class EduFourCsOverview extends StatefulWidget {
  const EduFourCsOverview({super.key});

  @override
  State<EduFourCsOverview> createState() => _EduFourCsOverviewState();
}

class _EduFourCsOverviewState extends State<EduFourCsOverview> {
  int _selected = 0;

  static const _sections = <Widget>[
    EduCutSection(key: ValueKey('cut')),
    EduColorSection(key: ValueKey('color')),
    EduClaritySection(key: ValueKey('clarity')),
    EduCaratSection(key: ValueKey('carat')),
  ];

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.diamond_outlined, EducationL10n.cut, EducationL10n.cutLead),
      (Icons.palette_outlined, EducationL10n.color, EducationL10n.colorLead),
      (
        Icons.blur_on_outlined,
        EducationL10n.clarity,
        EducationL10n.clarityLead,
      ),
      (Icons.scale_outlined, EducationL10n.carat, EducationL10n.caratLead),
    ];
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EduSection(
          children: [
            EduSectionHeader(
              eyebrow: context.tr(EducationL10n.c4Eyebrow),
              title: context.tr(EducationL10n.c4Title),
              body: context.tr(EducationL10n.c4Body),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 560 ? 4 : 2;
                final w = (c.maxWidth - 12 * (cols - 1)) / cols;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final (i, (icon, title, lead)) in items.indexed)
                      SizedBox(
                        width: w,
                        child: _CCard(
                          icon: icon,
                          title: context.tr(title),
                          lead: context.tr(lead),
                          selected: i == _selected,
                          palette: p,
                          onTap: () => setState(() => _selected = i),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: LuxeMotion.medium,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          child: _sections[_selected],
        ),
      ],
    );
  }
}

/// One of the 4Cs in the overview grid, picked to show its section.
class _CCard extends StatelessWidget {
  const _CCard({
    required this.icon,
    required this.title,
    required this.lead,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String lead;
  final bool selected;
  final LuxePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? p.accentSoft : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxeSpace.radius),
          side: BorderSide(
            color: selected ? p.accent : p.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selected ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: p.accent, size: 22),
                const SizedBox(height: 10),
                Text(title, style: LuxeType.display(22, p.ink)),
                const SizedBox(height: 6),
                Text(lead, style: LuxeType.body(p.inkMuted, size: 12.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cut: light performance and what proportions do to light.
class EduCutSection extends StatelessWidget {
  const EduCutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return EduSection(
      children: [
        EduSectionHeader(
          title: context.tr(EducationL10n.cut),
          body: context.tr(EducationL10n.cutLead),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr(EducationL10n.cutBody),
          style: LuxeType.body(p.inkMuted, size: 14),
        ),
        const SizedBox(height: 20),
        EduCard(
          child: Row(
            children: [
              Expanded(
                child: LightPathDiagram(
                  pavilionAngle: 37,
                  label: context.tr(EducationL10n.cutShallow),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LightPathDiagram(
                  pavilionAngle: 40.8,
                  label: context.tr(EducationL10n.cutIdeal),
                  highlight: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LightPathDiagram(
                  pavilionAngle: 45.5,
                  label: context.tr(EducationL10n.cutDeep),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        EduPoint(
          icon: Icons.wb_sunny_outlined,
          title: context.tr(EducationL10n.brightness),
          body: context.tr(EducationL10n.brightnessBody),
        ),
        const SizedBox(height: 14),
        EduPoint(
          icon: Icons.local_fire_department_outlined,
          title: context.tr(EducationL10n.fire),
          body: context.tr(EducationL10n.fireBody),
        ),
        const SizedBox(height: 14),
        EduPoint(
          icon: Icons.auto_awesome_outlined,
          title: context.tr(EducationL10n.sparkle),
          body: context.tr(EducationL10n.sparkleBody),
        ),
        const SizedBox(height: 22),
        EduSubhead(context.tr(EducationL10n.cutGrades)),
        const SizedBox(height: 12),
        for (final g in CutGrade.values) ...[
          _GradeRow(
            grade: context.cutName(g),
            body: context.cutBody(g),
            level: 1 - g.index / (CutGrade.values.length - 1),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({
    required this.grade,
    required this.body,
    required this.level,
  });

  final String grade, body;
  final double level;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(grade, style: LuxeType.label(p.ink, size: 13.5)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: 0.15 + 0.85 * level,
                  minHeight: 4,
                  backgroundColor: p.hairline,
                  color: p.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(body, style: LuxeType.body(p.inkMuted, size: 13))),
      ],
    );
  }
}

/// Color: the D–Z scale and its groups.
class EduColorSection extends StatelessWidget {
  const EduColorSection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return EduSection(
      children: [
        EduSectionHeader(
          title: context.tr(EducationL10n.color),
          body: context.tr(EducationL10n.colorLead),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr(EducationL10n.colorBody),
          style: LuxeType.body(p.inkMuted, size: 14),
        ),
        const SizedBox(height: 20),
        ExcludeSemantics(
          child: Row(
            children: [
              for (final g in ColorGrade.values)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        decoration: BoxDecoration(
                          color: colorGradeSwatch(g),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: p.hairline, width: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(g.label, style: LuxeType.label(p.inkFaint, size: 9)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final g in ColorGroup.values) ...[
          EduPoint(
            leading: _GradeChip(
              text:
                  '${ColorGrade.values.firstWhere((c) => c.group == g).label}'
                  '–${ColorGrade.values.lastWhere((c) => c.group == g).label}',
              color: colorGradeSwatch(
                ColorGrade.values.lastWhere((c) => c.group == g),
              ),
            ),
            title: context.colorGroupName(g),
            body: context.colorGroupBody(g),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        EduCard(
          child: Row(
            children: [
              for (final f in const [
                FancyColor.yellow,
                FancyColor.pink,
                FancyColor.blue,
                FancyColor.green,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.diamond,
                    size: 22,
                    color: Color.fromRGBO(
                      (f.swatch.r * 255).round(),
                      (f.swatch.g * 255).round(),
                      (f.swatch.b * 255).round(),
                      1,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr(EducationL10n.colorFancyBody),
                  style: LuxeType.body(p.inkMuted, size: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GradeChip extends StatelessWidget {
  const _GradeChip({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? p.accentSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.hairline),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: LuxeType.label(
          color == null ? p.accent : const Color(0xFF16140F),
          size: 12,
        ),
      ),
    );
  }
}

/// Clarity: the eleven grades and the characteristics behind them.
class EduClaritySection extends StatelessWidget {
  const EduClaritySection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final groups = [
      ('FL', ClarityGrade.fl),
      ('IF', ClarityGrade.internallyFlawless),
      ('VVS1–2', ClarityGrade.vvs1),
      ('VS1–2', ClarityGrade.vs1),
      ('SI1–2', ClarityGrade.si1),
      ('I1–I3', ClarityGrade.i1),
    ];
    final traits = [
      (Icons.circle, EducationL10n.incCrystal),
      (Icons.gesture, EducationL10n.incFeather),
      (Icons.grain, EducationL10n.incCloud),
      (Icons.fiber_manual_record_outlined, EducationL10n.incPinpoint),
      (Icons.horizontal_rule, EducationL10n.incNeedle),
      (Icons.texture, EducationL10n.incBlemish),
    ];
    return EduSection(
      children: [
        EduSectionHeader(
          title: context.tr(EducationL10n.clarity),
          body: context.tr(EducationL10n.clarityLead),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr(EducationL10n.clarityBody),
          style: LuxeType.body(p.inkMuted, size: 14),
        ),
        const SizedBox(height: 18),
        for (final (label, grade) in groups) ...[
          Row(
            children: [
              _GradeChip(text: label),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  context.clarityBody(grade),
                  style: LuxeType.body(p.inkMuted, size: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
        EduSubhead(context.tr(EducationL10n.characteristics)),
        const SizedBox(height: 12),
        for (final (icon, key) in traits) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(icon, size: 14, color: p.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr(key),
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

/// Carat: weight, with round sizes drawn to scale.
class EduCaratSection extends StatelessWidget {
  const EduCaratSection({super.key});

  /// Typical diameters of well cut round brilliants.
  static const sizes = [
    (0.25, 4.1),
    (0.5, 5.2),
    (0.75, 5.8),
    (1.0, 6.5),
    (1.5, 7.4),
    (2.0, 8.2),
    (3.0, 9.4),
  ];

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return EduSection(
      children: [
        EduSectionHeader(
          title: context.tr(EducationL10n.carat),
          body: context.tr(EducationL10n.caratLead),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr(EducationL10n.caratBody),
          style: LuxeType.body(p.inkMuted, size: 14),
        ),
        const SizedBox(height: 20),
        EduCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(EducationL10n.caratChart),
                style: LuxeType.label(p.ink, size: 13.5),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, c) {
                  // One scale for every stone so sizes compare truly;
                  // narrow screens wrap onto a second row.
                  final pxPerMm = (c.maxWidth / 62).clamp(4.5, 9.0);
                  return Wrap(
                    spacing: 14,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceAround,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      for (final (ct, mm) in sizes)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: mm * pxPerMm,
                              height: mm * pxPerMm,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    p.accent.withValues(alpha: 0.35),
                                    p.accent.withValues(alpha: 0.08),
                                  ],
                                ),
                                border: Border.all(color: p.accent),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${ct % 1 == 0 ? ct.toStringAsFixed(0) : ct} ct',
                              style: LuxeType.figure(p.ink, size: 11),
                            ),
                            Text(
                              '${mm.toStringAsFixed(1)} mm',
                              style: LuxeType.figure(p.inkFaint, size: 10),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        EduPoint(
          icon: Icons.lightbulb_outline,
          title: context.tr(EducationL10n.caratWeight),
          body: context.tr(EducationL10n.caratTip),
        ),
      ],
    );
  }
}

/// Face-up tint of a D–Z grade, for the scale bar.
Color colorGradeSwatch(ColorGrade g) {
  final a = g.absorption;
  int t(double v) => (math.exp(-v * 3.2) * 255).round();
  return Color.fromRGBO(t(a.r), t(a.g), t(a.b), 1);
}
