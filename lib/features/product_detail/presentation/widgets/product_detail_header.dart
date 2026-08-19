import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/product_detail.dart';

/// Identity block: what the product is, how it is qualified, and its reference.
class ProductDetailHeader extends StatelessWidget {
  const ProductDetailHeader({required this.detail, super.key});

  final ProductDetail detail;

  @override
  Widget build(BuildContext context) {
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
        if (detail.badges.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final badge in detail.badges) _Badge(badge: badge),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
        _Reference(
          label: detail.referenceLabel,
          value: detail.referenceValue,
        ),
      ],
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
        badge.label,
        style: AppTypography.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
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
          tooltip: 'Copy $label',
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
                content: Text('$label copied'),
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
