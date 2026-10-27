import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import 'edu_blocks.dart';

/// Opening stage: the page promise on a dark stage.
class EduHero extends StatelessWidget {
  const EduHero({super.key});

  @override
  Widget build(BuildContext context) {
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
                EduStageTones.lit,
                EduStageTones.mid,
                LuxeStage.glow,
                LuxeStage.obsidian,
              ],
              stops: const [0, 0.22, 0.48, 1],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LuxeSpace.gutter,
              40,
              LuxeSpace.gutter,
              36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
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
