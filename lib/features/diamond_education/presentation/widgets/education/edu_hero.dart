import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../../../core/widgets/luxe/luxe_button.dart';
import '../sim_stone_view.dart';
import 'edu_blocks.dart';

/// Opening stage: a live traced diamond turning in the dark, the page
/// promise and the way into the simulator.
class EduHero extends StatelessWidget {
  const EduHero({required this.onOpenSimulator, super.key});

  final VoidCallback onOpenSimulator;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final stone = width >= 720 ? 260.0 : 200.0;
    return EduDarkScope(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(LuxeSpace.radius + 10),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.35),
              radius: 1.1,
              colors: [LuxeStage.glow, LuxeStage.obsidian],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LuxeSpace.gutter,
              12,
              LuxeSpace.gutter,
              32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    SimStoneView(
                      size: stone,
                      semanticLabel: context.tr(EducationL10n.simCardTitle),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(EducationL10n.eyebrow),
                      textAlign: TextAlign.center,
                      style: LuxeType.eyebrow(LuxeStage.gold),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      header: true,
                      child: Text(
                        context.tr(EducationL10n.title),
                        textAlign: TextAlign.center,
                        style: LuxeType.display(34, LuxeStage.ink),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(EducationL10n.body),
                      textAlign: TextAlign.center,
                      style: LuxeType.body(LuxeStage.inkMuted),
                    ),
                    const SizedBox(height: 22),
                    LuxeButton(
                      label: context.tr(EducationL10n.simCta),
                      icon: Icons.view_in_ar_outlined,
                      variant: LuxeButtonVariant.accent,
                      onPressed: onOpenSimulator,
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
