import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../application/diamond_simulator_controller.dart';
import 'diamond_sim_viewport.dart';

/// Pieces laid over the full-screen stone. Only buttons take touches;
/// everything else lets gestures through to the stone.

/// In the hand view, the way back to 3D and the hand's scale.
class SimViewControls extends ConsumerWidget {
  const SimViewControls({required this.controller, super.key});

  final SimViewportController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final hand = ref.read(simHandProvider.notifier);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SimGlassPill(
            label: context.tr(EducationL10n.goBack),
            selected: false,
            palette: p,
            onTap: () => hand.show(false),
          ),
          const SizedBox(width: 6),
          ValueListenableBuilder<bool>(
            valueListenable: controller.lifeSize,
            builder: (context, life, _) => SimGlassPill(
              label: context.tr(
                life ? EducationL10n.fitHand : EducationL10n.lifeSize,
              ),
              selected: life,
              palette: p,
              onTap: () => controller.lifeSize.value = !life,
            ),
          ),
        ],
      ),
    );
  }
}

/// A frosted pill of text over the stage.
class SimGlassPill extends StatelessWidget {
  const SimGlassPill({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
    this.height = 36,
    super.key,
  });

  final String label;
  final bool selected;
  final LuxePalette palette;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final fg = selected ? p.accent : p.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: LuxeMotion.fast,
          height: height,
          constraints: const BoxConstraints(minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: const Color(0x8C101010),
            shape: StadiumBorder(
              side: BorderSide(
                color: selected
                    ? p.accent.withValues(alpha: 0.8)
                    : LuxeStage.glassBorder,
              ),
            ),
          ),
          child: Text(label, style: LuxeType.label(fg, size: 12.5)),
        ),
      ),
    );
  }
}
