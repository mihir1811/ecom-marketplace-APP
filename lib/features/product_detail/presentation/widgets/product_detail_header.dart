import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../buyer/application/wishlist_provider.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../chat/presentation/open_product_seller_chat.dart';
import '../../../product_share/presentation/widgets/product_share_sheet.dart';
import '../../domain/models/product_detail.dart';

/// Identity block: what the product is, how it is qualified, and its reference.
class ProductDetailHeader extends ConsumerStatefulWidget {
  const ProductDetailHeader({required this.detail, super.key});

  final ProductDetail detail;

  @override
  ConsumerState<ProductDetailHeader> createState() =>
      _ProductDetailHeaderState();
}

class _ProductDetailHeaderState extends ConsumerState<ProductDetailHeader> {
  bool _openingChat = false;

  Future<void> _openChat() async {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    try {
      await openProductSellerChat(
        context,
        ref,
        productId: widget.detail.id,
        apiProductType: widget.detail.apiProductType,
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final isJewelry = detail.jewelryDetail != null;
    final wishlisted = ref.watch(isInWishlistProvider(detail.id));
    final canChat = ref.watch(authProvider.select((s) => s.isSeller));

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: wishlisted ? Icons.favorite : Icons.favorite_border,
          tooltip: wishlisted ? 'Remove from wishlist' : 'Save to wishlist',
          tint: wishlisted
              ? AppColors.terracotta
              : AppColors.textPrimary(context),
          onTap: () {
            toggleWishlistItem(
              context,
              ref,
              detail.toWishlistItem(),
              addedMessage: 'Saved to wishlist',
              removedMessage: 'Removed from wishlist',
            );
          },
        ),
        if (canChat) ...[
          const SizedBox(width: AppSpacing.s8),
          _ActionIcon(
            icon: Icons.chat_bubble_outline,
            tooltip: context.tr(CatalogL10n.chatWithSeller),
            loading: _openingChat,
            onTap: _openChat,
          ),
        ],
        const SizedBox(width: AppSpacing.s8),
        _ActionIcon(
          icon: Icons.share_outlined,
          tooltip: context.tr(CatalogL10n.share),
          onTap: () => showProductShareSheet(
            context: context,
            ref: ref,
            productId: detail.id,
            productType: detail.apiProductType,
            productTitle: detail.title,
          ),
        ),
      ],
    );

    final meta = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail.badges.isNotEmpty)
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [for (final badge in detail.badges) _Badge(badge: badge)],
          ),
        if (detail.badges.isNotEmpty) const SizedBox(height: AppSpacing.s12),
        _Reference(
          label: _catalogText(context, detail.referenceLabel),
          value: detail.referenceValue,
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.title,
          style: AppTypography.headline.copyWith(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          detail.subtitle,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary(context),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        if (isJewelry)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: meta),
              const SizedBox(width: AppSpacing.s12),
              actions,
            ],
          )
        else ...[
          if (detail.badges.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final badge in detail.badges) _Badge(badge: badge),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          _Reference(
            label: _catalogText(context, detail.referenceLabel),
            value: detail.referenceValue,
          ),
        ],
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.tint,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? tint;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final iconColor = tint ?? AppColors.textPrimary(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: iconColor,
                  ),
                )
              : Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.badge});

  final ProductBadge badge;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (badge.tone) {
      ProductBadgeTone.accent => (
        AppColors.isDark(context) ? AppColors.slateBorder : AppColors.charcoal,
        AppColors.warmWhite,
      ),
      ProductBadgeTone.positive => (
        AppColors.success.withValues(alpha: 0.12),
        AppColors.success,
      ),
      ProductBadgeTone.caution => (
        AppColors.terracotta.withValues(alpha: 0.12),
        AppColors.terracotta,
      ),
      ProductBadgeTone.neutral => (
        AppColors.surface(context),
        AppColors.textSecondary(context),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.circular),
      ),
      child: Text(
        _catalogText(context, badge.label),
        style: AppTypography.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

String _catalogText(BuildContext context, String value) {
  if (value.endsWith(' certified')) {
    return context.tr(CatalogL10n.certified, {
      'authority': value.substring(0, value.length - 10),
    });
  }
  final key = catalogDisplayMessageKeys[value];
  return key == null ? value : context.tr(key);
}

class _Reference extends StatelessWidget {
  const _Reference({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${label.toUpperCase()}  ',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted(context),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: context.tr(CatalogL10n.copyValue, {'label': label}),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(AppSpacing.s8),
          constraints: const BoxConstraints(),
          iconSize: 14,
          color: AppColors.textMuted(context),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            final messenger = ScaffoldMessenger.maybeOf(context);
            messenger?.hideCurrentSnackBar();
            messenger?.showSnackBar(
              SnackBar(
                content: Text(
                  context.tr(CatalogL10n.valueCopied, {'label': label}),
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.copy_rounded),
        ),
      ],
    );
  }
}
