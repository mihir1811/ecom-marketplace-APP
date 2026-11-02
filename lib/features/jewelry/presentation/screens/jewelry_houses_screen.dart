import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../application/jewelry_catalogue_providers.dart';
import '../../domain/models/marketplace_listing.dart';
import '../widgets/jewelry_house_parts.dart';

enum _HouseSort { featured, newest, pieces, name }

/// Every jewelry house on an always-dark page, with sort (featured, newest,
/// most pieces, name) and the filters the live shops actually support
/// (city, price breakup). A house opens its own house page.
class JewelryHousesScreen extends ConsumerStatefulWidget {
  const JewelryHousesScreen({super.key});

  @override
  ConsumerState<JewelryHousesScreen> createState() =>
      _JewelryHousesScreenState();
}

class _JewelryHousesScreenState extends ConsumerState<JewelryHousesScreen> {
  _HouseSort _sort = _HouseSort.featured;
  String? _city;
  bool _priceBreakup = false;

  List<MarketplaceShop> _visible(List<MarketplaceShop> shops) {
    final filtered = [
      for (final s in shops)
        if ((_city == null || JewelryHouses.cityOf(s) == _city) &&
            (!_priceBreakup || s.showPriceBreakdown))
          s,
    ];
    return switch (_sort) {
      _HouseSort.featured => JewelryHouses.ranked(filtered),
      _HouseSort.newest => filtered,
      _HouseSort.pieces => [
        ...filtered,
      ]..sort((a, b) => (b.listingCount ?? 0) - (a.listingCount ?? 0)),
      _HouseSort.name => [
        ...filtered,
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    };
  }

  void _clearFilters() => setState(() {
    _city = null;
    _priceBreakup = false;
  });

  void _openHouse(MarketplaceShop house) =>
      context.push(AppRouteNames.jewelryHousePath(house.slug), extra: house);

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final shops = ref.watch(jewelryShopsProvider);
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AppScaffold(
        backgroundColor: LuxeStage.obsidian,
        safeTop: false,
        body: Stack(
          children: [
            const Positioned.fill(child: JewelryStageBackdrop()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Smoked glass back button on the dark page.
                Theme(
                  data: theme.copyWith(
                    colorScheme: theme.colorScheme.copyWith(
                      brightness: Brightness.dark,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      8,
                      MediaQuery.paddingOf(context).top + 8,
                      8,
                      6,
                    ),
                    child: Row(
                      children: [
                        LuxeIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          glass: true,
                          size: 42,
                          onPressed: () => context.goBack(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr(JewelryFlowL10n.allHouses),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuxeType.display(24, LuxeStage.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: LuxeStage.obsidian,
                    backgroundColor: LuxeStage.ink,
                    onRefresh: () async {
                      ref.invalidate(jewelryShopsProvider);
                      await ref
                          .read(jewelryShopsProvider.future)
                          .catchError((_) => const <MarketplaceShop>[]);
                    },
                    child: shops.when(
                      skipLoadingOnRefresh: false,
                      loading: () => const _ListSkeleton(),
                      error: (error, _) => _scrollable(
                        JewelryStageMessage(
                          icon: Icons.cloud_off_rounded,
                          title: context.tr(CatalogFlowL10n.errorTitle),
                          message: error is Failure
                              ? error.message
                              : context.tr(JewelryFlowL10n.housesError),
                          actionLabel: context.tr(CatalogL10n.retry),
                          onAction: () => ref.invalidate(jewelryShopsProvider),
                        ),
                      ),
                      data: (all) => all.isEmpty
                          ? _scrollable(
                              JewelryStageMessage(
                                icon: Icons.storefront_outlined,
                                title: context.tr(JewelryFlowL10n.housesEmpty),
                                message: context.tr(
                                  JewelryFlowL10n.housesEmptyBody,
                                ),
                              ),
                            )
                          : _houses(context, all),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scrollable(Widget child) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [child],
  );

  Widget _houses(BuildContext context, List<MarketplaceShop> all) {
    final cities = {for (final s in all) ?JewelryHouses.cityOf(s)}.toList()
      ..sort();
    final breakupApplies =
        all.any((s) => s.showPriceBreakdown) &&
        all.any((s) => !s.showPriceBreakdown);
    final visible = _visible(all);
    final filtering = _city != null || _priceBreakup;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr(JewelryFlowL10n.sortBy).toUpperCase(),
                      style: LuxeType.eyebrow(LuxeStage.gold),
                    ),
                    Text(
                      context.tr(JewelryFlowL10n.housesCount, {
                        'count': visible.length,
                      }),
                      style: LuxeType.label(LuxeStage.inkMuted, size: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              JewelryStageChipRow(
                children: [
                  for (final sort in _HouseSort.values)
                    JewelryStageChip(
                      label: context.tr(switch (sort) {
                        _HouseSort.featured => JewelryFlowL10n.sortFeatured,
                        _HouseSort.newest => JewelryFlowL10n.sortNewest,
                        _HouseSort.pieces => JewelryFlowL10n.sortMostPieces,
                        _HouseSort.name => JewelryFlowL10n.sortName,
                      }),
                      selected: _sort == sort,
                      onTap: () => setState(() => _sort = sort),
                    ),
                ],
              ),
              if (cities.length > 1 || breakupApplies) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    context.tr(JewelryFlowL10n.filterBy).toUpperCase(),
                    style: LuxeType.eyebrow(LuxeStage.gold),
                  ),
                ),
                const SizedBox(height: 8),
                JewelryStageChipRow(
                  children: [
                    if (filtering)
                      JewelryStageChip(
                        label: context.tr(CatalogL10n.clearAll),
                        icon: Icons.close_rounded,
                        selected: false,
                        onTap: _clearFilters,
                      ),
                    if (breakupApplies)
                      JewelryStageChip(
                        label: context.tr(JewelryFlowL10n.priceBreakup),
                        selected: _priceBreakup,
                        onTap: () =>
                            setState(() => _priceBreakup = !_priceBreakup),
                      ),
                    if (cities.length > 1)
                      for (final city in cities)
                        JewelryStageChip(
                          label: city,
                          icon: Icons.place_outlined,
                          selected: _city == city,
                          onTap: () => setState(
                            () => _city = _city == city ? null : city,
                          ),
                        ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (visible.isEmpty)
          SliverToBoxAdapter(
            child: JewelryStageMessage(
              icon: Icons.filter_alt_off_outlined,
              title: context.tr(JewelryFlowL10n.housesNoMatch),
              actionLabel: context.tr(CatalogL10n.clearAll),
              onAction: _clearFilters,
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              12,
              0,
              12,
              MediaQuery.paddingOf(context).bottom + 32,
            ),
            sliver: SliverList.separated(
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => JewelryHouseRow(
                key: ValueKey(visible[i].id),
                house: visible[i],
                onTap: () => _openHouse(visible[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double? w, double h, double r) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: LuxeStage.glass,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    final skeleton = ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              block(92, 36, 18),
            ],
          ],
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < 6; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          block(double.infinity, 76, LuxeSpace.radiusSmall + 4),
        ],
      ],
    );

    if (MediaQuery.disableAnimationsOf(context)) return skeleton;
    return skeleton
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.55, end: 1, duration: 900.ms);
  }
}
