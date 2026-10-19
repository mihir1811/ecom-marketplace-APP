import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';
import '../../../diamond_education/presentation/widgets/education/edu_blocks.dart';
import '../../../diamond_education/presentation/widgets/sim_stone_view.dart';
import '../../application/jewelry_simulator_controller.dart';
import '../../domain/jewelry_design.dart';
import '../../domain/jewelry_metal.dart';
import '../../scene/jewelry_scene.dart';
import '../../scene/scene_factory.dart';
import '../jewelry_labels.dart';
import '../widgets/jewelry_viewport.dart';

/// Jewelry education: the four kinds of piece, metals and purity, how
/// stones are set, ring sizes, earring styles, chains and lengths,
/// bracelets and care, with the 3D simulator one tap away throughout.
class JewelryEducationScreen extends StatefulWidget {
  const JewelryEducationScreen({super.key});

  @override
  State<JewelryEducationScreen> createState() => _JewelryEducationScreenState();
}

class _JewelryEducationScreenState extends State<JewelryEducationScreen> {
  final _scroll = ScrollController();
  final _offset = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.offset);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _open([JewelryType? type]) {
    // From here the simulator starts with its own stone, not one handed
    // over earlier from the diamond simulator.
    ProviderScope.containerOf(
      context,
    ).read(jewelryStoneHandoffProvider.notifier).state = null;
    context.openRoute(
      type == null
          ? AppRouteNames.jewelrySimulator
          : AppRouteNames.jewelrySimulatorFor(type.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = width >= 720 ? 40.0 : LuxeSpace.gutter;

    Widget constrain(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: child,
      ),
    );

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: context.tr(JewelryEduL10n.navEducation),
        scrollOffset: _offset,
      ),
      body: ScrollRevealScope(
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Hero(onOpen: _open)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 48),
              sliver: SliverList.list(
                children: [
                  constrain(_Pieces(onOpen: _open)),
                  constrain(const _Metals()),
                  constrain(const _Settings()),
                  constrain(const _Bands()),
                  constrain(const _Earrings()),
                  constrain(const _Chains()),
                  constrain(const _Bracelets()),
                  constrain(_Physics(onOpen: _open)),
                  constrain(const _Care()),
                  constrain(
                    _FinalCta(
                      onOpen: _open,
                      onBrowse: () => context.openRoute(AppRouteNames.jewelry),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opening stage: a live ring on its cushion (tap it), the promise and
/// the way into the simulator.
class _Hero extends StatefulWidget {
  const _Hero({required this.onOpen});

  final ValueChanged<JewelryType?> onOpen;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  JScene? _scene;
  final _viewport = JewelryViewportController();

  @override
  void dispose() {
    _viewport.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Built after the page has slid in, so the transition stays smooth.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(
        () => _scene = JewelrySceneFactory.build(
          JewelryDesign.initial().copyWith(
            halo: HaloStyle.single,
            bandAccent: BandAccent.half,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final stage = width >= 720 ? 320.0 : 260.0;
    final scene = _scene;
    return EduDarkScope(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(LuxeSpace.radius + 10),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.55),
              radius: 1.1,
              colors: [
                SimStageTones.lit,
                SimStageTones.mid,
                LuxeStage.glow,
                LuxeStage.obsidian,
              ],
              stops: const [0, 0.22, 0.48, 1],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LuxeSpace.gutter,
              8,
              LuxeSpace.gutter,
              32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    SizedBox(
                      height: stage,
                      child: scene == null
                          ? const SizedBox.expand()
                          : JewelryViewport(
                              scene: scene,
                              controller: _viewport,
                              drag: false,
                              semanticLabel: context.typeName(JewelryType.ring),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(JewelryEduL10n.eyebrow),
                      textAlign: TextAlign.center,
                      style: LuxeType.eyebrow(LuxeStage.gold),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      header: true,
                      child: Text(
                        context.tr(JewelryEduL10n.title),
                        textAlign: TextAlign.center,
                        style: LuxeType.display(34, LuxeStage.ink),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(JewelryEduL10n.body),
                      textAlign: TextAlign.center,
                      style: LuxeType.body(LuxeStage.inkMuted),
                    ),
                    const SizedBox(height: 22),
                    LuxeButton(
                      label: context.tr(JewelryEduL10n.simCta),
                      icon: Icons.view_in_ar_outlined,
                      variant: LuxeButtonVariant.accent,
                      onPressed: () => widget.onOpen(null),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pieces extends StatelessWidget {
  const _Pieces({required this.onOpen});

  final ValueChanged<JewelryType?> onOpen;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final items = [
      (
        JewelryType.ring,
        Icons.radio_button_unchecked_rounded,
        JewelryEduL10n.ringBody,
      ),
      (
        JewelryType.earrings,
        Icons.water_drop_outlined,
        JewelryEduL10n.earringsBody,
      ),
      (
        JewelryType.necklace,
        Icons.diamond_outlined,
        JewelryEduL10n.necklaceBody,
      ),
      (
        JewelryType.bracelet,
        Icons.all_inclusive_rounded,
        JewelryEduL10n.braceletBody,
      ),
    ];
    return EduSection(
      children: [
        EduSectionHeader(
          eyebrow: context.tr(JewelryEduL10n.piecesEyebrow),
          title: context.tr(JewelryEduL10n.piecesTitle),
        ),
        const SizedBox(height: 20),
        for (final (type, icon, body) in items) ...[
          EduCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EduPoint(
                  icon: icon,
                  title: context.typeName(type),
                  body: context.tr(body),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => onOpen(type),
                    icon: Icon(
                      Icons.view_in_ar_outlined,
                      size: 18,
                      color: p.accent,
                    ),
                    label: Text(
                      context.tr(JewelryEduL10n.designIn3d),
                      style: LuxeType.label(p.accent, size: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _Metals extends StatelessWidget {
  const _Metals();

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final bodies = {
      JewelryMetal.yellowGold: JewelryEduL10n.yellowGoldBody,
      JewelryMetal.whiteGold: JewelryEduL10n.whiteGoldBody,
      JewelryMetal.roseGold: JewelryEduL10n.roseGoldBody,
      JewelryMetal.platinum: JewelryEduL10n.platinumBody,
      JewelryMetal.silver: JewelryEduL10n.silverBody,
    };
    const purity = [
      ('24K', 999),
      ('22K', 916),
      ('18K', 750),
      ('14K', 585),
      ('10K', 417),
      ('PT950', 950),
      ('925', 925),
    ];
    return EduSection(
      children: [
        EduSectionHeader(
          eyebrow: context.tr(JewelryEduL10n.metalsEyebrow),
          title: context.tr(JewelryEduL10n.metalsTitle),
          body: context.tr(JewelryEduL10n.metalsBody),
        ),
        const SizedBox(height: 20),
        EduCard(
          child: Column(
            children: [
              for (final e in bodies.entries) ...[
                EduPoint(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          MetalSwatch.of(e.key),
                          MetalSwatch.of(e.key).withValues(alpha: 0.6),
                        ],
                      ),
                      border: Border.all(color: p.hairline),
                    ),
                  ),
                  title: context.metalName(e.key),
                  body: context.tr(e.value),
                ),
                if (e.key != JewelryMetal.silver) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        EduSubhead(context.tr(JewelryEduL10n.purityTitle)),
        const SizedBox(height: 8),
        Text(
          context.tr(JewelryEduL10n.purityBody),
          style: LuxeType.body(p.inkMuted),
        ),
        const SizedBox(height: 14),
        EduCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            children: [
              for (final (label, parts) in purity)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Text(
                          label,
                          style: LuxeType.label(p.ink, size: 14),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: parts / 1000,
                            minHeight: 8,
                            backgroundColor: p.surfaceRaised,
                            valueColor: AlwaysStoppedAnimation(p.accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 54,
                        child: Text(
                          '${(parts / 10).toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: LuxeType.figure(p.inkMuted, size: 13),
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

class _Settings extends StatelessWidget {
  const _Settings();

  @override
  Widget build(BuildContext context) {
    final points = [
      (
        Icons.front_hand_outlined,
        JewelryEduL10n.prong6,
        JewelryEduL10n.prongBody,
      ),
      (Icons.circle_outlined, JewelryEduL10n.bezel, JewelryEduL10n.bezelBody),
      (Icons.flare_outlined, JewelryEduL10n.halo, JewelryEduL10n.haloBody),
      (
        Icons.more_horiz_rounded,
        JewelryEduL10n.threeStone,
        JewelryEduL10n.threeStoneBody,
      ),
      (Icons.grain_rounded, JewelryEduL10n.pave, JewelryEduL10n.paveBody),
      (
        Icons.architecture_rounded,
        JewelryEduL10n.cathedral,
        JewelryEduL10n.cathedralBody,
      ),
    ];
    return EduSection(
      children: [
        EduSectionHeader(
          eyebrow: context.tr(JewelryEduL10n.settingsEyebrow),
          title: context.tr(JewelryEduL10n.settingsTitle),
          body: context.tr(JewelryEduL10n.settingsBody),
        ),
        const SizedBox(height: 20),
        EduCard(
          child: Column(
            children: [
              for (var i = 0; i < points.length; i++) ...[
                EduPoint(
                  icon: points[i].$1,
                  title: context.tr(points[i].$2),
                  body: context.tr(points[i].$3),
                ),
                if (i < points.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Bands extends StatelessWidget {
  const _Bands();

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    const sizes = [4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0];
    return EduSection(
      children: [
        EduSubhead(context.tr(JewelryEduL10n.bandTitle)),
        const SizedBox(height: 8),
        Text(
          context.tr(JewelryEduL10n.bandBody),
          style: LuxeType.body(p.inkMuted),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr(JewelryEduL10n.sizeBody),
          style: LuxeType.body(p.inkMuted),
        ),
        const SizedBox(height: 14),
        EduCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr(JewelryEduL10n.sizeColumn).toUpperCase(),
                      style: LuxeType.eyebrow(p.inkFaint),
                    ),
                  ),
                  Text(
                    context.tr(JewelryEduL10n.diameterColumn).toUpperCase(),
                    style: LuxeType.eyebrow(p.inkFaint),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final s in sizes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.toStringAsFixed(0),
                          style: LuxeType.label(p.ink, size: 14),
                        ),
                      ),
                      Text(
                        '${RingSizes.diameterMm(s).toStringAsFixed(1)} mm',
                        style: LuxeType.figure(p.inkMuted, size: 13),
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

class _Earrings extends StatelessWidget {
  const _Earrings();

  @override
  Widget build(BuildContext context) => const _PointsSection(
    title: JewelryEduL10n.earTitle,
    points: [
      (
        Icons.fiber_manual_record_outlined,
        JewelryEduL10n.stud,
        JewelryEduL10n.studBody,
      ),
      (Icons.water_drop_outlined, JewelryEduL10n.drop, JewelryEduL10n.dropBody),
      (
        Icons.radio_button_unchecked_rounded,
        JewelryEduL10n.hoop,
        JewelryEduL10n.hoopBody,
      ),
    ],
  );
}

class _Chains extends StatelessWidget {
  const _Chains();

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return EduSection(
      children: [
        EduSubhead(context.tr(JewelryEduL10n.neckTitle)),
        const SizedBox(height: 8),
        Text(
          context.tr(JewelryEduL10n.neckBody),
          style: LuxeType.body(p.inkMuted),
        ),
        const SizedBox(height: 14),
        EduCard(
          child: Column(
            children: [
              for (final l in ChainLength.values) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        '${l.inches}"',
                        style: LuxeType.display(22, p.ink),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.lengthNote(l),
                            style: LuxeType.label(p.ink, size: 14),
                          ),
                          Text(
                            '${l.mm.round()} mm',
                            style: LuxeType.body(p.inkMuted, size: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (l != ChainLength.values.last) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Bracelets extends StatelessWidget {
  const _Bracelets();

  @override
  Widget build(BuildContext context) => const _PointsSection(
    title: JewelryEduL10n.braceletTitle,
    points: [
      (
        Icons.auto_awesome_outlined,
        JewelryEduL10n.tennis,
        JewelryEduL10n.tennisBody,
      ),
      (Icons.circle_outlined, JewelryEduL10n.bangle, JewelryEduL10n.bangleBody),
      (
        Icons.link_rounded,
        JewelryEduL10n.chainBracelet,
        JewelryEduL10n.chainBraceletBody,
      ),
    ],
    footer: JewelryEduL10n.braceletNote,
  );
}

class _Physics extends StatelessWidget {
  const _Physics({required this.onOpen});

  final ValueChanged<JewelryType?> onOpen;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return EduSection(
      children: [
        EduSubhead(context.tr(JewelryEduL10n.physicsTitle)),
        const SizedBox(height: 8),
        Text(
          context.tr(JewelryEduL10n.physicsBody),
          style: LuxeType.body(p.inkMuted),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: LuxeButton(
            label: context.tr(JewelryEduL10n.designIn3d),
            icon: Icons.touch_app_outlined,
            variant: LuxeButtonVariant.secondary,
            onPressed: () => onOpen(JewelryType.earrings),
          ),
        ),
      ],
    );
  }
}

class _Care extends StatelessWidget {
  const _Care();

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    const tips = [
      (Icons.wash_outlined, JewelryEduL10n.careClean),
      (Icons.inventory_2_outlined, JewelryEduL10n.careStore),
      (Icons.search_rounded, JewelryEduL10n.careProngs),
      (Icons.auto_fix_high_outlined, JewelryEduL10n.careRhodium),
    ];
    return EduSection(
      children: [
        EduSubhead(context.tr(JewelryEduL10n.careTitle)),
        const SizedBox(height: 14),
        EduCard(
          child: Column(
            children: [
              for (var i = 0; i < tips.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(tips[i].$1, size: 20, color: p.accent),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        context.tr(tips[i].$2),
                        style: LuxeType.body(p.inkMuted, size: 14),
                      ),
                    ),
                  ],
                ),
                if (i < tips.length - 1) const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A sub-heading and a card of points.
class _PointsSection extends StatelessWidget {
  const _PointsSection({
    required this.title,
    required this.points,
    this.footer,
  });

  final String title;
  final List<(IconData, String, String)> points;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return EduSection(
      children: [
        EduSubhead(context.tr(title)),
        const SizedBox(height: 14),
        EduCard(
          child: Column(
            children: [
              for (var i = 0; i < points.length; i++) ...[
                EduPoint(
                  icon: points[i].$1,
                  title: context.tr(points[i].$2),
                  body: context.tr(points[i].$3),
                ),
                if (i < points.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: 10),
          Text(
            context.tr(footer!),
            style: LuxeType.body(p.inkMuted, size: 13.5),
          ),
        ],
      ],
    );
  }
}

class _FinalCta extends StatelessWidget {
  const _FinalCta({required this.onOpen, required this.onBrowse});

  final ValueChanged<JewelryType?> onOpen;
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
                    context.tr(JewelryEduL10n.ctaTitle),
                    style: LuxeType.display(28, LuxeStage.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(JewelryEduL10n.ctaBody),
                    style: LuxeType.body(LuxeStage.inkMuted),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      LuxeButton(
                        label: context.tr(JewelryEduL10n.simCta),
                        icon: Icons.view_in_ar_outlined,
                        variant: LuxeButtonVariant.accent,
                        onPressed: () => onOpen(null),
                      ),
                      LuxeButton(
                        label: context.tr(JewelryEduL10n.browseJewelry),
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
