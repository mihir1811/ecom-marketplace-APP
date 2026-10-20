import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../domain/diamond_grades.dart';
import '../../../simulation/sim_inclusion_shader.dart';
import '../../../simulation/sim_inclusions.dart';
import '../../../simulation/sim_renderer.dart';
import '../../sim_labels.dart';
import 'diamond_sim_viewport.dart';
import 'sim_inclusion_callouts.dart';

/// Kinds wholly inside the stone, then those reaching its surface, in the
/// picker's order.
final _closed = [
  for (final t in InclusionType.values)
    if (!t.isOpen) t,
];
final _open = [
  for (final t in InclusionType.values)
    if (t.isOpen) t,
];

/// The inclusion picker: any number of kinds at once, closed ones (wholly
/// inside) and open ones (reaching the surface) in their own rows, each
/// shown as itself, and a card on the one last picked or tapped: what it
/// is, how it is classed and how much it matters. The stone above shows
/// them in the line drawing, each labelled outside it.
class SimInclusionsPanel extends ConsumerWidget {
  const SimInclusionsPanel({required this.viewport, super.key});

  final SimViewportController viewport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(
      diamondSimulatorProvider.select(
        (s) => (clarity: s.spec.clarity, types: s.spec.inclusionTypes),
      ),
    );
    final c = ref.read(diamondSimulatorProvider.notifier);
    final flawless = s.clarity.index <= ClarityGrade.internallyFlawless.index;
    final p = LuxePalette.of(context);

    void toggle(InclusionType t) {
      AppHaptics.selection();
      // A flawless stone has none: picking one lowers the grade to where
      // inclusions begin to show.
      if (flawless) c.setClarity(ClarityGrade.si1);
      c.toggleInclusionType(t);
      viewport.focus.value = t;
    }

    Widget row(List<InclusionType> types) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (i, t) in types.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            _TypeChip(
              type: t,
              selected: s.types?.contains(t) ?? false,
              palette: p,
              onTap: () => toggle(t),
            ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr(
                  flawless
                      ? EducationL10n.incPickToSee
                      : EducationL10n.incExplorerHint,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LuxeType.label(p.inkMuted, size: 12),
              ),
            ),
            const SizedBox(width: 8),
            _GradedChip(
              selected: s.types == null,
              palette: p,
              onTap: () {
                AppHaptics.selection();
                c.setInclusionTypes(null);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _GroupTitle(
          label: context.tr(EducationL10n.incClosedTitle),
          color: SimInclusionCallouts.closedColor,
          palette: p,
        ),
        const SizedBox(height: 6),
        row(_closed),
        const SizedBox(height: 12),
        _GroupTitle(
          label: context.tr(EducationL10n.incOpenTitle),
          color: SimInclusionCallouts.openColor,
          palette: p,
        ),
        const SizedBox(height: 6),
        row(_open),
        const SizedBox(height: 12),
        ValueListenableBuilder<InclusionType?>(
          valueListenable: viewport.focus,
          builder: (context, focus, _) {
            final shown =
                focus ??
                (s.types == null || s.types!.isEmpty
                    ? InclusionType.feather
                    : InclusionType.values.firstWhere(s.types!.contains));
            return AnimatedSwitcher(
              duration: LuxeMotion.fast,
              child: _InfoCard(key: ValueKey(shown), type: shown, palette: p),
            );
          },
        ),
      ],
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({
    required this.label,
    required this.color,
    required this.palette,
  });

  final String label;
  final Color color;
  final LuxePalette palette;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const SizedBox.square(dimension: 8),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LuxeType.label(palette.ink, size: 12.5),
        ),
      ),
    ],
  );
}

class _GradedChip extends StatelessWidget {
  const _GradedChip({
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final bool selected;
  final LuxePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final label = context.tr(EducationL10n.asGraded);
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
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: ShapeDecoration(
            color: selected ? p.accent : p.surfaceRaised,
            shape: StadiumBorder(
              side: BorderSide(color: selected ? p.accent : p.hairline),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: LuxeType.label(selected ? p.onAccent : p.ink, size: 12.5),
          ),
        ),
      ),
    );
  }
}

/// A kind's chip: a small render of it, its name, and the open or closed
/// key colour.
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final InclusionType type;
  final bool selected;
  final LuxePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final key = type.isOpen
        ? SimInclusionCallouts.openColor
        : SimInclusionCallouts.closedColor;
    final name = context.inclusionName(type);
    return Semantics(
      button: true,
      selected: selected,
      label: '$name, ${context.inclusionReachName(type.info.reach)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: LuxeMotion.fast,
          curve: LuxeMotion.press,
          height: 44,
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          decoration: ShapeDecoration(
            color: selected ? key.withValues(alpha: 0.16) : p.surfaceRaised,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected ? key : p.hairline,
                width: selected ? 1.4 : 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: ColoredBox(
                  color: const Color(0xFF050607),
                  child: SimInclusionThumb(type: type, size: 36),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                maxLines: 1,
                style: LuxeType.label(
                  selected ? p.ink : p.inkMuted,
                  size: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a kind is and how it is classed, compact enough to sit under the
/// picker on a phone.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.type, required this.palette, super.key});

  final InclusionType type;
  final LuxePalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final info = type.info;
    final key = type.isOpen
        ? SimInclusionCallouts.openColor
        : SimInclusionCallouts.closedColor;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                  color: const Color(0xFF050607),
                  child: SimInclusionThumb(type: type, size: 58),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.inclusionName(type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.display(16, p.ink),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _Tag(
                          label: context.inclusionReachName(info.reach),
                          color: key,
                          strong: true,
                        ),
                        _Tag(
                          label: context.inclusionFamilyName(info.family),
                          color: p.inkMuted,
                        ),
                        _Tag(
                          label: context.inclusionOriginName(info.origin),
                          color: p.inkMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.inclusionBody(type),
            style: LuxeType.body(p.inkMuted, size: 12.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Meter(
                  label: context.tr(EducationL10n.incClarityImpact),
                  level: info.clarity,
                  palette: p,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Meter(
                  label: context.tr(EducationL10n.incDurability),
                  level: info.durability,
                  palette: p,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.strong = false});

  final String label;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: ShapeDecoration(
      color: color.withValues(alpha: strong ? 0.16 : 0.08),
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: strong ? 0.7 : 0.3)),
      ),
    ),
    child: Text(label, style: LuxeType.label(color, size: 10.5)),
  );
}

/// A three step bar for how much something matters, under its name.
class _Meter extends StatelessWidget {
  const _Meter({
    required this.label,
    required this.level,
    required this.palette,
  });

  final String label;
  final InclusionLevel level;
  final LuxePalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final n = level.index;
    final color = switch (level) {
      InclusionLevel.high => const Color(0xFFFF7A6B),
      InclusionLevel.medium => const Color(0xFFFFC266),
      _ => const Color(0xFF7FDDA0),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LuxeType.label(p.inkMuted, size: 11),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 1; i <= 3; i++)
              Container(
                margin: const EdgeInsets.only(right: 3),
                width: 14,
                height: 5,
                decoration: BoxDecoration(
                  color: i <= n ? color : p.hairline,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                context.inclusionLevelName(level),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuxeType.label(n == 0 ? p.inkMuted : color, size: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A kind drawn on its own by the line drawing's inclusion shader, lit
/// and turned as it is inside the stone: the picker shows each as it
/// really looks, not as a symbol.
class SimInclusionThumb extends StatefulWidget {
  const SimInclusionThumb({required this.type, required this.size, super.key});

  final InclusionType type;
  final double size;

  @override
  State<SimInclusionThumb> createState() => _SimInclusionThumbState();
}

class _SimInclusionThumbState extends State<SimInclusionThumb> {
  final _shader = SimInclusionShader();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    SimInclusionShader.loadProgram()
        .then((program) {
          if (!mounted) return;
          setState(() {
            _shader.shader = program.fragmentShader();
            _ready = true;
          });
        })
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    _shader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: _ready
        ? RepaintBoundary(
            child: CustomPaint(painter: _ThumbPainter(_shader, widget.type)),
          )
        : null,
  );
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.shader, this.type);

  final SimInclusionShader shader;
  final InclusionType type;

  static final _rot = () {
    final r = Float64List(9);
    const SimView(tilt: 0.5, spin: 0.55).rotationInto(r);
    return r;
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final items = SimInclusions.specimen(type);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    shader.paint(
      canvas,
      items,
      rot: _rot,
      scale: size.shortestSide * 0.46,
      centre: size.center(Offset.zero),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter old) =>
      old.type != type || !identical(old.shader, shader);
}
