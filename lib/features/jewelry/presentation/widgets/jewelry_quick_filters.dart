import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_metal_swatch.dart';
import '../../application/jewellery_categories_provider.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../application/jewelry_house_providers.dart';
import '../../domain/models/marketplace_enums.dart';
import '../../domain/models/marketplace_listing.dart';

/// Collection chips when every category is shown; style (sub-category)
/// chips once a collection is open. Single-select, like the API's
/// `category` param. Inside one house, only the collections and styles it
/// has pieces in are offered; styles are user-made, so always read live.
class JewelryStyleChips extends ConsumerWidget {
  const JewelryStyleChips({super.key});

  static const _all = '\u0000all';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(jewelryFilterProvider.select((s) => s.category));
    final selected = ref.watch(
      jewelryFilterProvider.select((s) => s.subCategory),
    );
    final shop = ref.watch(jewelryFilterProvider.select((s) => s.shop));
    final live = _forShop(ref, shop, category);
    return AnimatedSize(
      duration: LuxeMotion.medium,
      curve: LuxeMotion.settle,
      child: live.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              LuxeSkeleton(width: 86, height: 40, radius: 20),
              SizedBox(width: 6),
              LuxeSkeleton(width: 110, height: 40, radius: 20),
              SizedBox(width: 6),
              LuxeSkeleton(width: 74, height: 40, radius: 20),
            ],
          ),
        ),
        // Styles are an extra; the rest of the page still works without.
        error: (_, _) => const SizedBox(width: double.infinity),
        data: (scoped) {
          final (categories, styles) = scoped;
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
          final children = [
            for (final s in parent.children)
              if (styles == null || styles.contains(s.slug)) s,
          ];
          if (children.isEmpty) {
            return const SizedBox(width: double.infinity);
          }
          return LuxeQuickChips<String>(
            chips: [
              LuxeQuickChip(
                value: _all,
                label: context.tr(JewelryFlowL10n.allStyles),
              ),
              for (final s in children)
                LuxeQuickChip(value: s.slug, label: s.name),
            ],
            isSelected: (v) => v == _all ? selected == null : selected == v,
            onTap: (v) => n.selectSubCategory(v == _all ? null : v),
          );
        },
      ),
    );
  }

  /// Categories (only the house's own while [shop] is set) and the styles
  /// of [category] the house has, or null for every style. House lookups
  /// that fail fall back to everything.
  static AsyncValue<(List<MarketplaceCategory>, Set<String>?)> _forShop(
    WidgetRef ref,
    String? shop,
    String? category,
  ) {
    final live = ref.watch(jewelleryCategoriesProvider);
    if (shop == null || shop.isEmpty) {
      return live.whenData((c) => (c, null));
    }
    final all = live.valueOrNull;
    if (all == null) return live.whenData((c) => (c, null));
    final parent = MarketplaceCategory.find(all, category);
    if (parent == null) {
      final house = ref.watch(jewelryHouseCollectionsProvider(shop));
      if (house.isLoading) return const AsyncLoading();
      final own = house.valueOrNull;
      return AsyncData((
        own == null ? all : [for (final c in own) c.category],
        null,
      ));
    }
    final styles = ref.watch(
      jewelryHouseStylesProvider((shop: shop, category: parent.slug)),
    );
    if (styles.isLoading) return const AsyncLoading();
    return AsyncData((all, styles.valueOrNull));
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
