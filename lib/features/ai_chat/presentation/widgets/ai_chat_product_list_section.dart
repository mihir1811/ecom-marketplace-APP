import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../diamonds/presentation/widgets/diamond_list_card.dart';
import '../../../gemstones/presentation/widgets/gemstone_card.dart';
import '../../../jewelry/presentation/widgets/jewelry_product_card.dart';
import '../../application/ai_chat_listing_navigation.dart';
import '../../application/ai_chat_product_navigation.dart';
import '../../data/mappers/ai_chat_catalog_mapper.dart';
import '../../domain/models/ai_chat_product.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Renders Gem AI matches with the same list cards as catalog listing screens.
class AiChatProductListSection extends ConsumerWidget {
  const AiChatProductListSection({
    super.key,
    required this.products,
    this.productGroups = const [],
    this.totalFound,
    this.sourceQuery = '',
    this.onBeforeOpen,
  });

  final List<AiChatProduct> products;
  final List<AiChatProductGroup> productGroups;
  final int? totalFound;
  final String sourceQuery;
  final VoidCallback? onBeforeOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (products.isEmpty) return const SizedBox.shrink();

    final visible = products.take(12).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.s8,
            bottom: AppSpacing.s12,
          ),
          child: Row(
            children: [
              Text(
                context.tr(RemainingL10n.matches),
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                '${totalFound ?? products.length}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        for (final product in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: _AiChatCatalogListCard(
              product: product,
              onTap: () => AiChatProductNavigation.open(
                context,
                ref,
                product,
                beforeNavigate: onBeforeOpen,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.s4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => AiChatListingNavigation.seeMore(
              context,
              ref,
              userQuery: sourceQuery,
              products: products,
              productGroups: productGroups,
              beforeNavigate: onBeforeOpen,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary(context),
              side: BorderSide(color: AppColors.border(context)),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.r12),
              ),
            ),
            child: Text(
              context.tr(RemainingL10n.seeMoreListings),
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AiChatCatalogListCard extends StatelessWidget {
  const _AiChatCatalogListCard({required this.product, required this.onTap});

  final AiChatProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = AiChatCatalogMapper.normalizedType(product);

    if (type.contains('gem')) {
      return GemstoneCardList(
        key: ValueKey('ai-gem-${product.id}'),
        gemstone: AiChatCatalogMapper.toGemstone(product),
        onTap: onTap,
      );
    }

    if (type.contains('jewel')) {
      return JewelryProductListCard(
        key: ValueKey('ai-jewel-${product.id}'),
        item: AiChatCatalogMapper.toJewelry(product),
        onTap: onTap,
      );
    }

    return DiamondCardList(
      key: ValueKey('ai-diamond-${product.id}'),
      diamond: AiChatCatalogMapper.toDiamond(product),
      onTap: onTap,
    );
  }
}
