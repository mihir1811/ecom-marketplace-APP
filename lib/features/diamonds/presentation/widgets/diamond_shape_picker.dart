import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

/// Catalogue shapes with a diamond-simulator icon, copied from the
/// simulator-shapes API into `assets/shapes/simulator/`.
const Set<String> kSimulatorShapeIcons = {
  'Asscher',
  'Baguette',
  'Cushion',
  'Emerald',
  'Half Moon',
  'Lozenge',
  'Marquise',
  'Oval',
  'Pear',
  'Princess',
  'Radiant',
  'Rose Cut',
  'Round',
  'Tapered Baguette',
  'Trapezoid',
  'Trilliant',
};

/// Simulator outline for [name], falling back to [shapeOutlineIcon].
Widget shapeAssetIcon(String name, Color color, double size) {
  final box = size + 14;
  if (!kSimulatorShapeIcons.contains(name)) {
    return shapeOutlineIcon(name, color, box);
  }
  return SvgPicture.asset(
    'assets/shapes/simulator/${name.replaceAll(' ', '_')}.svg',
    width: box,
    height: box,
    theme: SvgTheme(currentColor: color),
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    placeholderBuilder: (_) => SizedBox.square(dimension: box),
    errorBuilder: (_, _, _) => shapeOutlineIcon(name, color, box),
  );
}

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
            hasOutline: kSimulatorShapeIcons.contains(s['name']),
          ),
      ],
      selected: selected,
      onToggle: ref.read(diamondSearchProvider.notifier).toggleShape,
      iconBuilder: shapeAssetIcon,
      expandLabel: context.tr(DiamondFlowL10n.allShapes),
      collapseLabel: context.tr(DiamondFlowL10n.fewerShapes),
    );
  }
}
