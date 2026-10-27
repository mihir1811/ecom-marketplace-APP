import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';
import '../widgets/education/edu_four_cs.dart';
import '../widgets/education/edu_hero.dart';
import '../widgets/education/edu_reference_sections.dart';

/// Diamond education: the 4Cs, anatomy, proportions, shapes,
/// fluorescence, origin, certification and buying tips.
class DiamondEducationScreen extends StatefulWidget {
  const DiamondEducationScreen({super.key});

  @override
  State<DiamondEducationScreen> createState() => _DiamondEducationScreenState();
}

class _DiamondEducationScreenState extends State<DiamondEducationScreen> {
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
        title: context.tr(EducationL10n.navEducation),
        scrollOffset: _offset,
      ),
      body: ScrollRevealScope(
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: EduHero()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 48),
              sliver: SliverList.list(
                children: [
                  constrain(const EduFourCsOverview()),
                  constrain(const EduAnatomySection()),
                  constrain(const EduProportionsSection()),
                  constrain(const EduFluorescenceSection()),
                  constrain(const EduOriginSection()),
                  constrain(const EduCertificationSection()),
                  constrain(const EduTipsSection()),
                  constrain(
                    EduFinalCta(
                      onBrowse: () => context.openRoute(AppRouteNames.diamonds),
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
