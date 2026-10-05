import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/luxe/luxe_shape_dial.dart';
import '../../../../core/widgets/luxe/luxe_shape_picker.dart';
import '../../application/diamond_search_provider.dart';
import 'diamond_svg_data.dart';

/// Photo for a shape name from the diamond shape catalogue, if any.
String? shapePhotoFor(String name) {
  for (final s in kAllShapes) {
    if (s['name'] == name) return s['image'];
  }
  return null;
}

/// Outline drawing used when a shape has no photo.
Widget shapeOutlineIcon(String name, Color color, double size) =>
    renderShapeSvg(name, size: size, color: color);

/// Diamond finder shape picker, built on the shared [LuxeShapeDialPicker].
class DiamondShapePicker extends ConsumerWidget {
  const DiamondShapePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(diamondSearchProvider.select((s) => s.shapes));
    return LuxeShapeDialPicker(
      shapes: [
        for (final s in kAllShapes)
          LuxeShapeOption(
            value: s['name']!,
            label: context.trCatalogValue(s['name']!),
            image: s['image'],
          ),
      ],
      selected: selected,
      onToggle: ref.read(diamondSearchProvider.notifier).toggleShape,
      iconBuilder: shapeOutlineIcon,
      selectLabel: (shape) =>
          context.tr(DiamondFlowL10n.selectShape, {'shape': shape}),
      selectedLabel: (shape) =>
          context.tr(DiamondFlowL10n.shapeSelected, {'shape': shape}),
      expandLabel: context.tr(DiamondFlowL10n.allShapes),
      collapseLabel: context.tr(DiamondFlowL10n.fewerShapes),
    );
  }
}
