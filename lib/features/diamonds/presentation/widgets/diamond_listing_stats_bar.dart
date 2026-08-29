import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../application/diamond_list_provider.dart';
import '../../domain/models/diamond_listing_summary_stats.dart';

/// Fixed listing header KPIs for authenticated individual (non-seller) buyers.
class DiamondListingStatsBar extends ConsumerWidget {
  const DiamondListingStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showForIndividual = ref.watch(
      authProvider.select((s) => s.isAuthenticated && !s.isSeller),
    );
    if (!showForIndividual) return const SizedBox.shrink();

    final diamonds = ref.watch(
      diamondListProvider.select((async) => async.valueOrNull?.diamonds),
    );
    if (diamonds == null || diamonds.isEmpty) return const SizedBox.shrink();

    final stats = DiamondListingSummaryStats.fromDiamonds(diamonds);
    final tiles = _tiles(context, stats);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        child: Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s8),
              _StatCard(tile: tiles[i]),
            ],
          ],
        ),
      ),
    );
  }

  static List<({String label, String value})> _tiles(
    BuildContext context,
    DiamondListingSummaryStats stats,
  ) {
    return [
      (label: context.tr(CatalogL10n.pcsShort), value: '${stats.pcs}'),
      (
        label: context.tr(CatalogL10n.totalCtShort),
        value: '${stats.totalCarat.toStringAsFixed(2)} ct',
      ),
      (
        label: context.tr(CatalogL10n.pricePerCtShort),
        value: AppCurrency.format(
          formatGroupedWhole(stats.pricePerCarat.roundToDouble()),
        ),
      ),
      (
        label: context.tr(CatalogL10n.total),
        value: AppCurrency.format(
          formatGroupedWhole(stats.totalPrice.roundToDouble()),
        ),
      ),
      (
        label: context.tr(CatalogL10n.averageTotal),
        value: AppCurrency.format(
          formatGroupedWhole(stats.avgTotal.roundToDouble()),
        ),
      ),
    ];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.tile});

  final ({String label, String value}) tile;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tile.label,
              softWrap: false,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              tile.value,
              softWrap: false,
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
