import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../../../core/widgets/luxe/luxe_button.dart';
import '../sim_stone_view.dart';
import 'edu_blocks.dart';

/// Opening stage: a live traced diamond turning in a soft dark studio
/// environment, the page promise and the way into the simulator.
class EduHero extends StatelessWidget {
  const EduHero({required this.onOpenSimulator, super.key});

  final VoidCallback onOpenSimulator;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final stone = width >= 720 ? 360.0 : 300.0;
    return EduDarkScope(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(LuxeSpace.radius + 10),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.28),
              radius: 1.08,
              colors: [
                Color(0xFF2D3444),
                Color(0xFF1E232E),
                Color(0xFF141820),
              ],
              stops: [0.0, 0.58, 1.0],
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
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  children: [
                    SimStoneView(
                      size: stone,
                      semanticLabel: context.tr(EducationL10n.simCardTitle),
                    ),
                    const SizedBox(height: 10),
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
