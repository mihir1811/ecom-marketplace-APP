import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../domain/diamond_shape.dart';
import '../../sim_labels.dart';

/// Swipeable row of the ten classic shapes; tapping one recuts the stone.
class SimShapeStrip extends ConsumerWidget {
  const SimShapeStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      diamondSimulatorProvider.select((s) => s.spec.shape),
    );
    final p = LuxePalette.of(context);
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: SimShape.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final shape = SimShape.values[i];
          final on = shape == selected;
          final color = on ? p.accent : p.inkMuted;
          return Semantics(
            button: true,
            selected: on,
            label: context.shapeName(shape),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (on) return;
                AppHaptics.selection();
                ref.read(diamondSimulatorProvider.notifier).setShape(shape);
              },
              child: AnimatedContainer(
                duration: LuxeMotion.fast,
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: on ? p.accentSoft : p.surface,
                  borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
                  border: Border.all(color: on ? p.accent : p.hairline),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      shape.svgAsset,
                      width: 28,
                      height: 28,
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      placeholderBuilder: (_) =>
                          const SizedBox.square(dimension: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.shapeName(shape),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.label(color, size: 11),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
