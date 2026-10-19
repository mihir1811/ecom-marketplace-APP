import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../diamond_education/presentation/sim_labels.dart';
import '../../../diamond_education/presentation/widgets/sim_stone_view.dart';
import '../../../diamond_education/presentation/widgets/simulator/sim_viewport_overlay.dart';
import '../../application/jewelry_simulator_controller.dart';
import '../../domain/jewelry_design.dart';
import '../jewelry_labels.dart';
import '../widgets/jewelry_panels.dart';
import '../widgets/jewelry_viewport.dart';

/// Full-screen 3D jewelry simulator. The piece fills the screen on its
/// display; the four kinds of piece sit in a row at the top, a slim rail
/// of tools at the side, and choosing a tool opens only its controls in
/// a compact sheet. Always dark, whatever the app theme, so metal and
/// stones read truly.
class JewelrySimulatorScreen extends ConsumerStatefulWidget {
  const JewelrySimulatorScreen({super.key});

  @override
  ConsumerState<JewelrySimulatorScreen> createState() =>
      _JewelrySimulatorScreenState();
}

class _JewelrySimulatorScreenState
    extends ConsumerState<JewelrySimulatorScreen> {
  final _viewport = JewelryViewportController();
  JewelryTool? _open;
  double _panelHeight = 0;
  ThemeData? _theme;
  Object? _themeFor;

  @override
  void dispose() {
    _viewport.dispose();
    super.dispose();
  }

  String _toolLabel(JewelryTool t) => context.tr(switch (t) {
    JewelryTool.metal => JewelryEduL10n.toolMetal,
    JewelryTool.stone => JewelryEduL10n.toolStone,
    JewelryTool.setting => JewelryEduL10n.toolSetting,
    JewelryTool.accents => JewelryEduL10n.toolAccents,
    JewelryTool.band => JewelryEduL10n.toolBand,
    JewelryTool.style => JewelryEduL10n.toolStyle,
    JewelryTool.chain => JewelryEduL10n.toolChain,
  });

  Widget _panel(JewelryTool t) => switch (t) {
    JewelryTool.metal => const JewelryMetalPanel(),
    JewelryTool.stone => const JewelryStonePanel(),
    JewelryTool.setting => const JewelrySettingPanel(),
    JewelryTool.accents => const JewelryAccentsPanel(),
    JewelryTool.band => const JewelryBandPanel(),
    JewelryTool.style => const JewelryStylePanel(),
    JewelryTool.chain => const JewelryChainPanel(),
  };

  void _openTool(JewelryTool t) {
    AppHaptics.selection();
    setState(() => _open = t);
  }

  void _close() {
    ref.read(jewelrySimulatorProvider.notifier).flush();
    setState(() {
      _open = null;
      _panelHeight = 0;
    });
  }

  void _reset() {
    AppHaptics.light();
    ref.read(jewelrySimulatorProvider.notifier).reset();
    _viewport
      ..autoRotate = true
      ..show(JewelryViewPreset.angled);
  }

  void _setType(JewelryType t) {
    final c = ref.read(jewelrySimulatorProvider.notifier);
    c.setType(t);
    c.flush();
    // A tool the new piece lacks closes.
    final tools = ref.read(jewelrySimulatorProvider).design.tools;
    if (_open != null && !tools.contains(_open)) _close();
  }

  @override
  Widget build(BuildContext context) {
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
    final scene = ref.watch(jewelrySimulatorProvider.select((s) => s.scene));
    final design = ref.watch(jewelrySimulatorProvider.select((s) => s.design));
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
          final maxPanel = math.min(size.height * 0.46, 420.0);
          final barTop = pad.top + 6;
          final typesTop = barTop + 48;
          final summaryTop = typesTop + 46;
          final stageBottom = open != null && !wide
              ? math.max(0.0, _panelHeight - 16)
              : 0.0;
          final stageRight = open != null && wide ? panelWidth + 16 : 0.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
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
              ),
              AnimatedPositioned(
                duration: LuxeMotion.medium,
                curve: LuxeMotion.settle,
                left: 0,
                top: 0,
                right: stageRight,
                bottom: stageBottom,
                child: JewelryViewport(
                  scene: scene,
                  controller: _viewport,
                  semanticLabel: context.typeName(design.type),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: summaryTop + 90,
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
                child: _TopBar(onReset: _reset),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: typesTop,
                child: _TypeRow(selected: design.type, onSelected: _setType),
              ),
              Positioned(
                left: 16,
                right: wide ? 16 : 120,
                top: summaryTop,
                child: const IgnorePointer(child: _Summary()),
              ),
              if (open == null) ...[
                Positioned(
                  right: 10,
                  top: summaryTop,
                  bottom: pad.bottom + 96,
                  child: _ToolRail(
                    tools: design.tools,
                    labelOf: _toolLabel,
                    onOpen: _openTool,
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: pad.bottom + 58,
                  child: IgnorePointer(
                    child: Text(
                      context.tr(JewelryEduL10n.hint),
                      textAlign: TextAlign.center,
                      style: LuxeType.label(
                        LuxePalette.of(context).inkMuted,
                        size: 11.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: pad.bottom + 12,
                  child: _ViewControls(controller: _viewport),
                ),
              ],
              if (open != null)
                wide
                    ? Positioned(
                        right: 16,
                        top: summaryTop,
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
                          child: _MeasureSize(
                            onSize: (s) {
                              if (!mounted) return;
                              if ((s.height - _panelHeight).abs() > 1) {
                                setState(() => _panelHeight = s.height);
                              }
                            },
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
                      ),
            ],
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onReset});

  final VoidCallback onReset;

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
            context.tr(JewelryEduL10n.simTitle),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LuxeType.display(19, p.ink),
          ),
        ),
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

/// Ring, earrings, necklace, bracelet.
class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.selected, required this.onSelected});

  final JewelryType selected;
  final ValueChanged<JewelryType> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final t in JewelryType.values) ...[
            SimGlassPill(
              label: context.typeName(t),
              selected: t == selected,
              palette: p,
              height: 36,
              onTap: () {
                if (t != selected) onSelected(t);
              },
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

/// What the piece is and what it weighs.
class _Summary extends ConsumerWidget {
  const _Summary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(jewelrySimulatorProvider.select((s) => s.design));
    final facts = ref.watch(
      jewelrySimulatorProvider.select((s) => s.scene.facts),
    );
    final p = LuxePalette.of(context);
    final lines = <String>[
      context.tr(JewelryEduL10n.metalWeight, {
        'grams': facts.metalGrams.toStringAsFixed(1),
      }),
      if (d.hasCentreStone)
        '${context.shapeName(d.stone.shape)} · ${context.tr(JewelryEduL10n.centreCarat, {'ct': facts.centreCarats.toStringAsFixed(2)})}',
      if (facts.accentCount > 0)
        context.tr(JewelryEduL10n.accentCarat, {
          'count': facts.accentCount,
          'ct': facts.accentCarats.toStringAsFixed(2),
        }),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${context.metalLine(d.metal, d.purity)} · ${context.typeName(d.type)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: LuxeType.label(p.ink, size: 14),
        ),
        const SizedBox(height: 4),
        for (final l in lines)
          Text(
            l,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LuxeType.label(p.inkMuted, size: 12),
          ),
      ],
    );
  }
}

class _ToolRail extends ConsumerWidget {
  const _ToolRail({
    required this.tools,
    required this.labelOf,
    required this.onOpen,
  });

  final List<JewelryTool> tools;
  final String Function(JewelryTool) labelOf;
  final ValueChanged<JewelryTool> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(jewelrySimulatorProvider.select((s) => s.design));
    String valueOf(JewelryTool t) => switch (t) {
      JewelryTool.metal => context.metalLine(d.metal, d.purity),
      JewelryTool.stone =>
        d.hasCentreStone
            ? '${d.stone.carat.toStringAsFixed(2)} ct ${d.stone.isFancy ? '' : d.stone.colorGrade.label} ${d.stone.clarity.label}'
            : '${d.stone.colorGrade.label} ${d.stone.clarity.label}',
      JewelryTool.setting =>
        d.headSpec.isBezel
            ? context.headName(d.head)
            : '${context.headName(d.head)} · ${context.tipName(d.prongTip)}',
      JewelryTool.accents => [
        if (d.takesHalo && d.halo != HaloStyle.none)
          context.tr(JewelryEduL10n.halo),
        if (d.takesHalo && d.hiddenHalo) context.tr(JewelryEduL10n.hiddenHalo),
        if (d.takesBandStones && d.bandAccent != BandAccent.plain)
          context.accentName(d.bandAccent),
        if (d.milgrain) context.tr(JewelryEduL10n.milgrain),
      ].join(' · ').ifEmpty(context.tr(JewelryEduL10n.plain)),
      JewelryTool.band =>
        '${context.shankName(d.shank)} · ${d.bandWidthMm.toStringAsFixed(1)} mm',
      JewelryTool.style =>
        d.type == JewelryType.earrings
            ? context.earringName(d.earringStyle)
            : switch (d.braceletStyle) {
                BraceletStyle.tennis =>
                  '${context.braceletName(d.braceletStyle)} · ${context.tennisSettingName(d.tennisSetting)}',
                BraceletStyle.bangle =>
                  '${context.braceletName(d.braceletStyle)} · ${context.bangleName(d.bangleStyle)}',
                BraceletStyle.chain =>
                  '${context.chainName(d.chainStyle)} · ${context.claspName(d.clasp)}',
              },
      JewelryTool.chain =>
        '${context.chainName(d.chainStyle)} · ${d.chainLength.inches}"',
    };
    final p = LuxePalette.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in tools)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Semantics(
                  button: true,
                  label: '${labelOf(t)}, ${valueOf(t)}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onOpen(t),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        maxWidth: 112,
                      ),
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                      decoration: BoxDecoration(
                        color: const Color(0x8C101010),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: LuxeStage.glassBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            labelOf(t),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuxeType.label(p.ink, size: 12),
                          ),
                          Text(
                            valueOf(t),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuxeType.label(p.accent, size: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViewControls extends StatelessWidget {
  const _ViewControls({required this.controller});

  final JewelryViewportController controller;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    String label(JewelryViewPreset v) => context.tr(switch (v) {
      JewelryViewPreset.front => JewelryEduL10n.viewFront,
      JewelryViewPreset.angled => EducationL10n.viewAngled,
      JewelryViewPreset.side => JewelryEduL10n.viewSide,
      JewelryViewPreset.top => JewelryEduL10n.viewTop,
    });
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (final v in JewelryViewPreset.values) ...[
              SimGlassPill(
                label: label(v),
                selected: controller.preset == v,
                palette: p,
                onTap: () => controller.show(v),
              ),
              const SizedBox(width: 6),
            ],
            SimGlassPill(
              label: context.tr(EducationL10n.autoSpin),
              selected: controller.autoRotate,
              palette: p,
              onTap: () => controller.autoRotate = !controller.autoRotate,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
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

/// Reports its child's laid out size after each layout.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureSize(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMeasureSize renderObject,
  ) => renderObject.onSize = onSize;
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onSize);

  ValueChanged<Size> onSize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _last) return;
    _last = size;
    final s = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(s));
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
