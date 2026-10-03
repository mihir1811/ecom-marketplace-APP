import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_metal_swatch.dart';
import '../../application/jewellery_categories_provider.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../domain/models/jewellery_category_admin.dart';

/// Metal tones offered as one-tap quick filters on results and the house
/// landing (the full list lives in the filter screen).
const jewelryQuickMetals = ['Yellow Gold', 'White Gold', 'Rose Gold', 'Two-Tone'];

/// Active style names (sub-categories) for [category], straight from the
/// live category API. "All jewelry" and the accessories landing list every
/// style once; an unknown category lists none.
List<String> jewelryStylesFor(
  List<JewelleryCategoryAdmin> live,
  String? category,
) {
  final matched = JewelleryCategoryMatch.find(live, category);
  if (matched != null) {
    return [
      for (final sub in matched.subcategories)
        if (sub.isActive && sub.name.trim().isNotEmpty) sub.name.trim(),
    ];
  }
  final browsingAll =
      category == null || category.isEmpty || category == 'All Accessories';
  if (!browsingAll) return const [];
  final seen = <String>{};
  return [
    for (final cat in live)
      for (final sub in cat.subcategories)
        if (sub.isActive && sub.name.trim().isNotEmpty && seen.add(sub.name))
          sub.name.trim(),
  ];
}

/// Style chips for the current collection: "All styles" plus every live
/// sub-category. Multi-select; "All styles" clears the selection.
class JewelryStyleChips extends ConsumerWidget {
  const JewelryStyleChips({super.key});

  static const _all = '\u0000all';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(jewelryFilterProvider.select((s) => s.category));
    final selected = ref.watch(
      jewelryFilterProvider.select((s) => s.subCategories),
    );
    final live = ref.watch(jewelleryCategoriesProvider);
    return AnimatedSize(
      duration: LuxeMotion.medium,
      curve: LuxeMotion.settle,
      child: live.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              LuxeSkeleton(width: 86, height: 40, radius: 20),
              SizedBox(width: 8),
              LuxeSkeleton(width: 110, height: 40, radius: 20),
              SizedBox(width: 8),
              LuxeSkeleton(width: 74, height: 40, radius: 20),
            ],
          ),
        ),
        // Styles are an extra; the rest of the page still works without.
        error: (_, _) => const SizedBox(width: double.infinity),
        data: (categories) {
          final styles = jewelryStylesFor(categories, category);
          if (styles.isEmpty) return const SizedBox(width: double.infinity);
          final n = ref.read(jewelryFilterProvider.notifier);
          return LuxeQuickChips<String>(
            chips: [
              LuxeQuickChip(
                value: _all,
                label: context.tr(JewelryFlowL10n.allStyles),
              ),
              for (final s in styles) LuxeQuickChip(value: s, label: s),
            ],
            isSelected: (v) => v == _all ? selected.isEmpty : selected.contains(v),
            onTap: (v) =>
                v == _all ? n.clearSubCategories() : n.toggleSubCategory(v),
          );
        },
      ),
    );
  }
}

/// One-tap metal tone filters with polished swatches.
class JewelryMetalChips extends ConsumerWidget {
  const JewelryMetalChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      jewelryFilterProvider.select((s) => s.metalColors),
    );
    return LuxeQuickChips<String>(
      dense: true,
      chips: [
        for (final m in jewelryQuickMetals)
          LuxeQuickChip(
            value: m,
            label: context.trCatalogValue(m),
            leading: LuxeMetalSwatch(label: m, size: 14),
          ),
      ],
      isSelected: selected.contains,
      onTap: ref.read(jewelryFilterProvider.notifier).toggleMetalColor,
    );
  }
}
