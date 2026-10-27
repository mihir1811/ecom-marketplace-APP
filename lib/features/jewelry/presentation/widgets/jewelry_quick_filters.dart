import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_metal_swatch.dart';
import '../../application/jewellery_categories_provider.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../domain/models/marketplace_enums.dart';
import '../../domain/models/marketplace_listing.dart';

/// Collection chips when every category is shown; style (sub-category)
/// chips once a collection is open. Single-select, like the API's
/// `category` param.
class JewelryStyleChips extends ConsumerWidget {
  const JewelryStyleChips({super.key});

  static const _all = '\u0000all';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(jewelryFilterProvider.select((s) => s.category));
    final selected = ref.watch(
      jewelryFilterProvider.select((s) => s.subCategory),
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
          final n = ref.read(jewelryFilterProvider.notifier);
          final parent = MarketplaceCategory.find(categories, category);
          if (parent == null) {
            // Every category: chips open a collection.
            if (categories.isEmpty) {
              return const SizedBox(width: double.infinity);
            }
            return LuxeQuickChips<String>(
              chips: [
                LuxeQuickChip(
                  value: _all,
                  label: context.tr(JewelryFlowL10n.allStyles),
                ),
                for (final c in categories)
                  LuxeQuickChip(value: c.slug, label: c.name),
              ],
              isSelected: (v) => v == _all,
              onTap: (v) {
                if (v != _all) n.selectCategory(v);
              },
            );
          }
          if (parent.children.isEmpty) {
            return const SizedBox(width: double.infinity);
          }
          return LuxeQuickChips<String>(
            chips: [
              LuxeQuickChip(
                value: _all,
                label: context.tr(JewelryFlowL10n.allStyles),
              ),
              for (final s in parent.children)
                LuxeQuickChip(value: s.slug, label: s.name),
            ],
            isSelected: (v) => v == _all ? selected == null : selected == v,
            onTap: (v) => n.selectSubCategory(v == _all ? null : v),
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
    final selected = ref.watch(jewelryFilterProvider.select((s) => s.metals));
    return LuxeQuickChips<String>(
      dense: true,
      chips: [
        for (final m in MarketplaceEnums.quickMetals)
          LuxeQuickChip(
            value: m,
            label: context.trCatalogValue(MarketplaceEnums.label(m)),
            leading: LuxeMetalSwatch(
              label: MarketplaceEnums.swatchLabel(m),
              size: 14,
            ),
          ),
      ],
      isSelected: selected.contains,
      onTap: ref.read(jewelryFilterProvider.notifier).toggleMetal,
    );
  }
}
