import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../application/diamond_simulator_controller.dart';
import '../widgets/sim_stone_view.dart';
import '../widgets/simulator/diamond_sim_viewport.dart';
import '../widgets/simulator/sim_cut_panels.dart';
import '../widgets/simulator/sim_grade_panels.dart';
import '../widgets/simulator/sim_shape_strip.dart';
import '../widgets/simulator/sim_viewport_overlay.dart';

enum _SimTab { cut, color, clarity, carat, fluorescence, proportions }

/// Full-screen 3D diamond simulator: a live stone in a dark studio above
/// controls for shape, the 4Cs, fluorescence and every proportion. Always
/// dark, whatever the app theme, so the stone's light reads truly.
class DiamondSimulatorScreen extends ConsumerStatefulWidget {
  const DiamondSimulatorScreen({super.key});

  @override
  ConsumerState<DiamondSimulatorScreen> createState() =>
      _DiamondSimulatorScreenState();
}

class _DiamondSimulatorScreenState
    extends ConsumerState<DiamondSimulatorScreen> {
  final _viewport = SimViewportController();
  _SimTab _tab = _SimTab.cut;

  @override
  void dispose() {
    _viewport.dispose();
    super.dispose();
  }

  String _tabLabel(_SimTab t) => context.tr(switch (t) {
    _SimTab.cut => EducationL10n.cut,
    _SimTab.color => EducationL10n.color,
    _SimTab.clarity => EducationL10n.clarity,
    _SimTab.carat => EducationL10n.carat,
    _SimTab.fluorescence => EducationL10n.fluorescence,
    _SimTab.proportions => EducationL10n.proportions,
  });

  Widget _panel(_SimTab t) => switch (t) {
    _SimTab.cut => SimCutPanel(viewport: _viewport),
    _SimTab.color => const SimColorPanel(),
    _SimTab.clarity => const SimClarityPanel(),
    _SimTab.carat => const SimCaratPanel(),
    _SimTab.fluorescence => const SimFluorescencePanel(),
    _SimTab.proportions => const SimProportionsPanel(),
  };

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.build(AppPalette.resolve(context).night),
      child: Builder(builder: _build),
    );
  }

  Widget _build(BuildContext context) {
    final p = LuxePalette.of(context);
    final stage = Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.1),
              radius: 1.05,
              colors: [
                SimStageTones.lit,
                SimStageTones.mid,
                LuxeStage.obsidian,
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
        ),
        DiamondSimViewport(controller: _viewport),
        SimViewportOverlay(controller: _viewport),
      ],
    );

    final tabs = _SimTabs(
      selected: _tab,
      labelOf: _tabLabel,
      onSelected: (t) => setState(() => _tab = t),
    );
    final panel = ColoredBox(
      color: p.surface,
      child: AnimatedSwitcher(
        duration: LuxeMotion.fast,
        child: SingleChildScrollView(
          key: ValueKey(_tab),
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: _panel(_tab),
        ),
      ),
    );

    return AppScaffold(
      enableAppDrawer: false,
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: context.tr(EducationL10n.simTitle),
        actions: [
          LuxeIconButton(
            icon: Icons.restart_alt_rounded,
            tooltip: context.tr(EducationL10n.reset),
            size: 40,
            onPressed: () {
              AppHaptics.light();
              ref.read(diamondSimulatorProvider.notifier).reset();
              _viewport
                ..autoRotate = true
                ..show(SimViewPreset.angled);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 860 ||
              (constraints.maxWidth > constraints.maxHeight &&
                  constraints.maxWidth >= 640);
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: ClipRect(child: stage)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.surface,
                    border: Border(left: BorderSide(color: p.hairline)),
                  ),
                  child: SizedBox(
                    width: constraints.maxWidth >= 1100 ? 440 : 380,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        const SimShapeStrip(),
                        const SizedBox(height: 8),
                        tabs,
                        Expanded(child: panel),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 11, child: ClipRect(child: stage)),
              ColoredBox(
                color: p.canvas,
                child: const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 6),
                  child: SimShapeStrip(),
                ),
              ),
              ColoredBox(color: p.canvas, child: tabs),
              Expanded(flex: 9, child: panel),
            ],
          );
        },
      ),
    );
  }
}

/// Scrollable row of panel tabs with a champagne underline.
class _SimTabs extends StatelessWidget {
  const _SimTabs({
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final _SimTab selected;
  final String Function(_SimTab) labelOf;
  final ValueChanged<_SimTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.hairline)),
      ),
      child: SizedBox(
        height: 46,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              for (final t in _SimTab.values)
                Semantics(
                  button: true,
                  selected: t == selected,
                  label: labelOf(t),
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (t == selected) return;
                      AppHaptics.selection();
                      onSelected(t);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          Text(
                            labelOf(t),
                            style: LuxeType.label(
                              t == selected ? p.ink : p.inkMuted,
                              size: 13.5,
                            ),
                          ),
                          const Spacer(),
                          AnimatedContainer(
                            duration: LuxeMotion.fast,
                            height: 2,
                            width: t == selected ? 28 : 0,
                            color: p.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
