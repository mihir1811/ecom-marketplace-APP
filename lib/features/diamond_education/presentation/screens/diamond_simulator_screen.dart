import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../jewelry_education/application/jewelry_simulator_controller.dart';
import '../../application/diamond_simulator_controller.dart';
import '../../domain/average_hand.dart';
import '../../domain/diamond_proportions.dart';
import '../sim_labels.dart';
import '../widgets/sim_stone_view.dart';
import '../widgets/simulator/diamond_sim_viewport.dart';
import '../widgets/simulator/sim_cut_panels.dart';
import '../widgets/simulator/sim_grade_panels.dart';
import '../widgets/simulator/sim_hand_stage.dart';
import '../widgets/simulator/sim_quality_panels.dart';
import '../widgets/simulator/sim_shape_strip.dart';
import '../widgets/simulator/sim_viewport_overlay.dart';

/// Whether the stone can be taken into the jewelry simulator from here.
/// Hidden for now; the handoff and the jewelry engine stay in place.
const _showJewelryHandoff = false;

enum _SimTool {
  shape,
  cut,
  color,
  clarity,
  inclusions,
  bgm,
  milky,
  enhancement,
  carat,
  fluorescence,
  proportions,
}

/// Full-screen 3D diamond simulator. The stone fills the screen; a slim
/// rail of tools sits at the side, and choosing one opens only that
/// tool's controls in a compact sheet, out of the stone's way. Carat
/// brings an average hand up from below with the stones on its fingers.
/// Always dark, whatever the app theme, so the stone's light reads truly.
class DiamondSimulatorScreen extends ConsumerStatefulWidget {
  const DiamondSimulatorScreen({super.key});

  @override
  ConsumerState<DiamondSimulatorScreen> createState() =>
      _DiamondSimulatorScreenState();
}

class _DiamondSimulatorScreenState
    extends ConsumerState<DiamondSimulatorScreen> {
  final _viewport = SimViewportController();
  _SimTool? _open;
  ThemeData? _theme;
  Object? _themeFor;

  @override
  void dispose() {
    _viewport.dispose();
    super.dispose();
  }

  String _toolLabel(_SimTool t) => context.tr(switch (t) {
    _SimTool.shape => EducationL10n.shape,
    _SimTool.cut => EducationL10n.cut,
    _SimTool.color => EducationL10n.color,
    _SimTool.clarity => EducationL10n.clarity,
    _SimTool.inclusions => EducationL10n.inclusions,
    _SimTool.bgm => EducationL10n.bgm,
    _SimTool.milky => EducationL10n.milky,
    _SimTool.enhancement => EducationL10n.enhancement,
    _SimTool.carat => EducationL10n.carat,
    _SimTool.fluorescence => EducationL10n.fluorescence,
    _SimTool.proportions => EducationL10n.proportions,
  });

  Widget _panel(_SimTool t) => switch (t) {
    _SimTool.shape => const SimShapeStrip(),
    _SimTool.cut => SimCutPanel(viewport: _viewport),
    _SimTool.color => const SimColorPanel(),
    _SimTool.clarity => const SimClarityPanel(),
    _SimTool.inclusions => const SimInclusionsPanel(),
    _SimTool.bgm => const SimBgmPanel(),
    _SimTool.milky => const SimMilkyPanel(),
    _SimTool.enhancement => const SimEnhancementPanel(),
    _SimTool.carat => const SimCaratPanel(),
    _SimTool.fluorescence => const SimFluorescencePanel(),
    _SimTool.proportions => const SimProportionsPanel(),
  };

  void _openTool(_SimTool t) {
    AppHaptics.selection();
    setState(() => _open = t);
    // Carat is judged on a hand.
    if (t == _SimTool.carat) ref.read(simHandProvider.notifier).show(true);
  }

  void _close() => setState(() => _open = null);

  /// Takes the stone as it is now into the jewelry simulator.
  void _useInJewelry() {
    AppHaptics.selection();
    ref.read(jewelryStoneHandoffProvider.notifier).state = ref
        .read(diamondSimulatorProvider)
        .spec;
    context.openRoute(AppRouteNames.jewelrySimulator);
  }

  void _toggleVector() {
    _viewport.mode = _viewport.vector
        ? SimRenderMode.realistic
        : SimRenderMode.vector;
  }

  void _reset() {
    AppHaptics.light();
    ref.read(simHandProvider.notifier).reset();
    ref.read(diamondSimulatorProvider.notifier).reset();
    _viewport
      ..autoRotate = true
      ..show(SimViewPreset.angled);
  }

  @override
  Widget build(BuildContext context) {
    // Built once per palette, not on every tool switch.
    final palette = AppPalette.resolve(context).night;
    if (!identical(palette, _themeFor)) {
      _themeFor = palette;
      _theme = AppTheme.build(palette);
    }
    return Theme(
      data: _theme!,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Builder(builder: _build),
      ),
    );
  }

  Widget _build(BuildContext context) {
    final onHand = ref.watch(simHandProvider.select((h) => h.onHand));
    final pad = MediaQuery.paddingOf(context);
    final open = _open;

    return AppScaffold(
      enableAppDrawer: false,
      backgroundColor: LuxeStage.obsidian,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final wide =
              size.width >= 860 ||
              (size.width > size.height && size.width >= 640);
          final panelWidth = size.width >= 1100 ? 420.0 : 380.0;
          final maxPanel = math.min(size.height * 0.44, 400.0);
          final barTop = pad.top + 6;
          final contentTop = barTop + 50;

          return Stack(
            fit: StackFit.expand,
            children: [
              // A line drawing reads best on plain black; the traced stone
              // on its lit studio grey.
              ListenableBuilder(
                listenable: _viewport,
                builder: (context, _) => AnimatedSwitcher(
                  duration: LuxeMotion.medium,
                  child: _viewport.vector
                      ? const ColoredBox(
                          key: ValueKey('vector'),
                          color: Color(0xFF000000),
                          child: SizedBox.expand(),
                        )
                      : const DecoratedBox(
                          key: ValueKey('realistic'),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(0, -0.1),
                              radius: 1.05,
                              colors: [
                                SimStageTones.lit,
                                SimStageTones.mid,
                                Color(0xFF0B0C0E),
                              ],
                              stops: [0, 0.5, 1],
                            ),
                          ),
                          child: SizedBox.expand(),
                        ),
                ),
              ),
              // The stone keeps the whole screen and stays centred, whatever
              // is open over it.
              Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Paused and hidden under the hand, keeping its pose.
                    Offstage(
                      offstage: onHand,
                      child: TickerMode(
                        enabled: !onHand,
                        child: DiamondSimViewport(controller: _viewport),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: LuxeMotion.medium,
                      child: onHand
                          ? SimHandStage(
                              key: const ValueKey('hand'),
                              controller: _viewport,
                              topInset: contentTop,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              // Keeps the top bar legible over the stone or the hand.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: contentTop + 24,
                child: const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xB3000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 12,
                top: barTop,
                child: _TopBar(
                  viewport: _viewport,
                  onReset: _reset,
                  onToggleVector: _toggleVector,
                  onUseInJewelry: _useInJewelry,
                ),
              ),
              if (open == null) ...[
                // One swipeable row along the bottom, clear of the stone.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: pad.bottom + (onHand ? 56 : 12),
                  child: _ToolRail(labelOf: _toolLabel, onOpen: _openTool),
                ),
                if (onHand)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: pad.bottom + 12,
                    child: SimViewControls(controller: _viewport),
                  ),
              ],
              if (open != null)
                wide
                    ? Positioned(
                        right: 16,
                        top: contentTop,
                        bottom: 16 + pad.bottom,
                        width: panelWidth,
                        child: _ToolSheet(
                          key: ValueKey(open),
                          title: _toolLabel(open),
                          onDone: _close,
                          rounded: BorderRadius.circular(LuxeSpace.radius),
                          padBottom: 0,
                          child: _panel(open),
                        ),
                      )
                    : Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: maxPanel + pad.bottom,
                          ),
                          child: _ToolSheet(
                            key: ValueKey(open),
                            title: _toolLabel(open),
                            onDone: _close,
                            rounded: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            padBottom: pad.bottom,
                            child: _panel(open),
                          ),
                        ),
                      ),
            ],
          );
        },
      ),
    );
  }
}

/// Back, title, the realistic / vector switch and reset, floating over
/// the stage.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.viewport,
    required this.onReset,
    required this.onToggleVector,
    required this.onUseInJewelry,
  });

  final SimViewportController viewport;
  final VoidCallback onReset, onToggleVector, onUseInJewelry;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Row(
      children: [
        LuxeIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          size: 40,
          glass: true,
          onPressed: () => context.goBack(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.tr(EducationL10n.simTitle),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LuxeType.display(19, p.ink),
          ),
        ),
        // Into the jewelry simulator with this stone: a labelled pill
        // where there is room, an icon on narrow phones.
        if (_showJewelryHandoff) ...[
          if (MediaQuery.sizeOf(context).width >= 440)
            SimGlassPill(
              label: context.tr(JewelryEduL10n.useInJewelry),
              selected: true,
              palette: p,
              height: 34,
              onTap: onUseInJewelry,
            )
          else
            LuxeIconButton(
              icon: Icons.diamond_outlined,
              tooltip: context.tr(JewelryEduL10n.useInJewelry),
              size: 36,
              glass: true,
              onPressed: onUseInJewelry,
            ),
          const SizedBox(width: 6),
        ],
        ListenableBuilder(
          listenable: viewport,
          builder: (context, _) => _RenderModeSwitch(
            vector: viewport.vector,
            onToggle: onToggleVector,
          ),
        ),
        const SizedBox(width: 6),
        SimGlassPill(
          label: context.tr(EducationL10n.reset),
          selected: false,
          palette: p,
          height: 34,
          onTap: onReset,
        ),
      ],
    );
  }
}

/// The tools in one swipeable row, each with a glimpse of its setting.
class _ToolRail extends ConsumerWidget {
  const _ToolRail({required this.labelOf, required this.onOpen});

  final String Function(_SimTool) labelOf;
  final ValueChanged<_SimTool> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(diamondSimulatorProvider.select((s) => s.spec));
    final cut = ref.watch(
      diamondSimulatorProvider.select((s) => s.estimatedCut),
    );
    final p = LuxePalette.of(context);

    String valueOf(_SimTool t) => switch (t) {
      _SimTool.shape => context.shapeName(s.shape),
      _SimTool.cut => context.cutName(cut),
      _SimTool.color =>
        s.fancyColor == null
            ? s.colorGrade.label
            : context.fancyName(s.fancyColor!),
      _SimTool.clarity => s.clarity.label,
      _SimTool.inclusions =>
        s.inclusionTypes == null
            ? context.tr(EducationL10n.asGraded)
            : context.tr(EducationL10n.typesCount, {
                'count': s.inclusionTypes!.length,
              }),
      _SimTool.bgm =>
        s.brown == s.green
            ? context.tingeName(s.brown)
            : [
                if (s.brown.index > 0)
                  '${context.tr(EducationL10n.brown)} ${context.tingeName(s.brown)}',
                if (s.green.index > 0)
                  '${context.tr(EducationL10n.green)} ${context.tingeName(s.green)}',
              ].join(' · '),
      _SimTool.milky => context.milkyName(s.milky),
      _SimTool.enhancement => context.enhancementName(s.enhancement),
      _SimTool.carat => '${s.carat.toStringAsFixed(2)} ct',
      _SimTool.fluorescence => context.fluorescenceName(s.fluorescence),
      _SimTool.proportions => context.tr(
        s.proportions == DiamondProportions.ideal(s.shape)
            ? EducationL10n.ideal
            : EducationL10n.custom,
      ),
    };

    Widget? visualOf(_SimTool t) => switch (t) {
      _SimTool.shape => SvgPicture.asset(
        s.shape.svgAsset,
        width: 18,
        height: 18,
        colorFilter: ColorFilter.mode(p.ink, BlendMode.srcIn),
        placeholderBuilder: (_) => const SizedBox.square(dimension: 18),
      ),
      _SimTool.color when s.fancyColor == null => _Dot(
        colorGradeSwatch(s.colorGrade),
      ),
      _ => null,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final t in _SimTool.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _RailItem(
                label: labelOf(t),
                value: valueOf(t),
                visual: visualOf(t),
                onTap: () => onOpen(t),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: LuxeStage.glassBorder),
    ),
    child: const SizedBox.square(dimension: 14),
  );
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.label,
    required this.value,
    required this.onTap,
    this.visual,
  });

  final String label, value;
  final Widget? visual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Semantics(
      button: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const ShapeDecoration(
            color: Color(0x8C101010),
            shape: StadiumBorder(
              side: BorderSide(color: LuxeStage.glassBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (visual != null) ...[visual!, const SizedBox(width: 6)],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    style: LuxeType.label(p.ink, size: 11.5),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    style: LuxeType.label(p.accent, size: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The open tool's controls: its name, Done, and on the hand which
/// finger's stone they change.
class _ToolSheet extends ConsumerWidget {
  const _ToolSheet({
    required this.title,
    required this.onDone,
    required this.rounded,
    required this.padBottom,
    required this.child,
    super.key,
  });

  final String title;
  final VoidCallback onDone;
  final BorderRadius rounded;
  final double padBottom;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final onHand = ref.watch(simHandProvider.select((h) => h.onHand));
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: LuxeMotion.fast,
      curve: LuxeMotion.press,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 24),
          child: child,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface.withValues(alpha: 0.95),
          borderRadius: rounded,
          border: Border.all(color: p.hairline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 6, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.display(19, p.ink),
                    ),
                  ),
                  TextButton(
                    onPressed: onDone,
                    style: TextButton.styleFrom(
                      foregroundColor: p.accent,
                      minimumSize: const Size(64, 40),
                    ),
                    child: Text(
                      context.tr(EducationL10n.done),
                      style: LuxeType.label(p.accent, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            if (onHand) const _FingerPicker(),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 8, 16, 14 + padBottom),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Which finger's stone the controls change; bare fingers offer one.
class _FingerPicker extends ConsumerWidget {
  const _FingerPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hand = ref.watch(simHandProvider);
    final carat = ref.watch(
      diamondSimulatorProvider.select((s) => s.spec.carat),
    );
    final c = ref.read(simHandProvider.notifier);
    final p = LuxePalette.of(context);
    String worn(HandFinger f) {
      final ct = f == hand.active ? carat : hand.parked[f]?.spec.carat;
      return ct == null
          ? context.tr(EducationL10n.addStone)
          : '${ct.toStringAsFixed(2)} ct';
    }

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Center(
              child: Text(
                context.tr(EducationL10n.editingFinger).toUpperCase(),
                style: LuxeType.eyebrow(p.inkFaint),
              ),
            ),
            const SizedBox(width: 8),
            for (final f in HandFinger.values) ...[
              Center(
                child: SimGlassPill(
                  label: '${context.fingerName(f)} · ${worn(f)}',
                  selected: f == hand.active,
                  palette: p,
                  height: 32,
                  onTap: () => c.select(f),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (hand.count > 1)
              Center(
                child: TextButton(
                  onPressed: () {
                    AppHaptics.light();
                    c.remove(hand.active);
                  },
                  style: TextButton.styleFrom(foregroundColor: p.inkMuted),
                  child: Text(
                    context.tr(EducationL10n.removeStone),
                    style: LuxeType.label(p.inkMuted, size: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Realistic or vector: a switch whose thumb shows the current look, a
/// faceted, lit stone for realistic and a line drawing for vector.
class _RenderModeSwitch extends StatelessWidget {
  const _RenderModeSwitch({required this.vector, required this.onToggle});

  final bool vector;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final label = context.tr(EducationL10n.vectorView);
    return Semantics(
      toggled: vector,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppHaptics.selection();
            onToggle();
          },
          child: Container(
            width: 66,
            height: 34,
            padding: const EdgeInsets.all(3),
            decoration: ShapeDecoration(
              color: const Color(0x8C101010),
              shape: StadiumBorder(
                side: BorderSide(
                  color: vector
                      ? p.accent.withValues(alpha: 0.8)
                      : LuxeStage.glassBorder,
                ),
              ),
            ),
            child: Stack(
              children: [
                // The other look, faint, on the free side of the track.
                Align(
                  alignment: vector
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: SizedBox.square(
                    dimension: 28,
                    child: Center(
                      child: _ModeGlyph(
                        vector: !vector,
                        size: 15,
                        color: p.inkFaint,
                      ),
                    ),
                  ),
                ),
                AnimatedAlign(
                  duration: LuxeMotion.fast,
                  curve: LuxeMotion.press,
                  alignment: vector
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: p.accent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: LuxeMotion.fast,
                      child: _ModeGlyph(
                        key: ValueKey(vector),
                        vector: vector,
                        size: 18,
                        color: p.onAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A brilliant seen from the side: filled and lit for realistic, as
/// outlined facets for vector.
class _ModeGlyph extends StatelessWidget {
  const _ModeGlyph({
    required this.vector,
    required this.size,
    required this.color,
    super.key,
  });

  final bool vector;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _ModeGlyphPainter(vector: vector, color: color),
  );
}

class _ModeGlyphPainter extends CustomPainter {
  _ModeGlyphPainter({required this.vector, required this.color});

  final bool vector;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Table, girdle corners and culet of a brilliant's profile.
    final tl = Offset(w * 0.3, h * 0.16), tr = Offset(w * 0.7, h * 0.16);
    final gl = Offset(w * 0.04, h * 0.4), gr = Offset(w * 0.96, h * 0.4);
    final culet = Offset(w * 0.5, h * 0.94);
    final outline = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(gr.dx, gr.dy)
      ..lineTo(culet.dx, culet.dy)
      ..lineTo(gl.dx, gl.dy)
      ..close();
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, w / 16)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    if (vector) {
      // Wireframe: outline, girdle and the facet lines.
      final mid = Offset(w * 0.5, h * 0.4);
      canvas
        ..drawPath(outline, line)
        ..drawLine(gl, gr, line)
        ..drawLine(tl, Offset(w * 0.3, h * 0.4), line)
        ..drawLine(tr, Offset(w * 0.7, h * 0.4), line)
        ..drawLine(Offset(w * 0.3, h * 0.4), culet, line)
        ..drawLine(Offset(w * 0.7, h * 0.4), culet, line)
        ..drawLine(mid, culet, line);
      return;
    }
    // Realistic: a solid stone with lit and shaded facets and a glint.
    canvas.drawPath(outline, Paint()..color = color);
    final shade = Paint()..color = const Color(0x55000000);
    canvas
      ..drawPath(
        Path()
          ..moveTo(gl.dx, gl.dy)
          ..lineTo(w * 0.5, h * 0.4)
          ..lineTo(culet.dx, culet.dy)
          ..close(),
        shade,
      )
      ..drawPath(
        Path()
          ..moveTo(tr.dx, tr.dy)
          ..lineTo(gr.dx, gr.dy)
          ..lineTo(w * 0.7, h * 0.4)
          ..close(),
        shade,
      );
    final glint = Paint()..color = const Color(0xCCFFFFFF);
    final g = Offset(w * 0.78, h * 0.1);
    final r = w * 0.13;
    canvas.drawPath(
      Path()
        ..moveTo(g.dx, g.dy - r)
        ..lineTo(g.dx + r * 0.3, g.dy - r * 0.3)
        ..lineTo(g.dx + r, g.dy)
        ..lineTo(g.dx + r * 0.3, g.dy + r * 0.3)
        ..lineTo(g.dx, g.dy + r)
        ..lineTo(g.dx - r * 0.3, g.dy + r * 0.3)
        ..lineTo(g.dx - r, g.dy)
        ..lineTo(g.dx - r * 0.3, g.dy - r * 0.3)
        ..close(),
      glint,
    );
  }

  @override
  bool shouldRepaint(covariant _ModeGlyphPainter old) =>
      old.vector != vector || old.color != color;
}
