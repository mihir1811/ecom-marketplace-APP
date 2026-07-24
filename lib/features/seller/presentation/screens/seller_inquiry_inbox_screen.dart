import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/account_nav.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/seller_inquiry_mock_data.dart';
import '../../domain/models/seller_inquiry.dart';
import '../widgets/seller_layout.dart';

class SellerInquiryInboxScreen extends StatefulWidget {
  const SellerInquiryInboxScreen({super.key});

  @override
  State<SellerInquiryInboxScreen> createState() =>
      _SellerInquiryInboxScreenState();
}

class _SellerInquiryInboxScreenState extends State<SellerInquiryInboxScreen> {
  InquiryCategory _category = InquiryCategory.diamond;

  IconData _iconFor(InquiryCategory c) => switch (c) {
        InquiryCategory.diamond => Icons.diamond_outlined,
        InquiryCategory.gemstone => Icons.auto_awesome,
        InquiryCategory.bullion => Icons.monetization_on_outlined,
        InquiryCategory.watch => Icons.watch_outlined,
        InquiryCategory.jewelry => Icons.workspace_premium_outlined,
      };

  Color _accentFor(InquiryCategory c) => switch (c) {
        InquiryCategory.diamond => AppColors.info,
        InquiryCategory.gemstone => AppSwatches.inquiryGemstone,
        InquiryCategory.bullion => AppSwatches.inquiryBullion,
        InquiryCategory.watch => AppColors.textSecondaryLight,
        InquiryCategory.jewelry => AppSwatches.inquiryJewelry,
      };

  @override
  Widget build(BuildContext context) {
    final items = inquiriesForCategory(_category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => openSellerDrawer(context),
                icon: const Icon(Icons.menu),
              ),
              Text(
                'Inquiries',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.sandSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: AppColors.textMutedLight.withValues(alpha: 0.3),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warmWhite,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.warmBorder),
                            ),
                            child: Text(
                              'Seller · Inbox',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Inquiry inbox',
                          style: AppTypography.headline.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Incoming product inquiries from buyers across diamond, '
                          'gemstone, bullion, watches, and jewelry. Open a row to '
                          'see full specifications.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                          OutlinedButton(
                          onPressed: () => context.go(
                            inquiryNewPathFor(
                              GoRouterState.of(context).uri.path,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: AppColors.warmWhite,
                          ),
                          child: const Text('New inquiry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Browse by type',
                style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Switch category — each type loads its own list.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in InquiryCategory.values)
                    _CategoryChip(
                      label: c.label,
                      icon: _iconFor(c),
                      selected: _category == c,
                      accent: _accentFor(c),
                      onTap: () => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _accentFor(_category).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _iconFor(_category),
                        color: _accentFor(_category),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _category.listTitle,
                            style: AppTypography.label.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            items.isEmpty
                                ? 'Showing 0 of 0'
                                : 'Showing 1–${items.length} of ${items.length}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No ${_category.label.toLowerCase()} inquiries.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ),
                )
              else
                for (final inquiry in items) ...[
                  _InquiryCard(
                    inquiry: inquiry,
                    accent: _accentFor(inquiry.category),
                    icon: _iconFor(inquiry.category),
                    onView: () => context.go(
                      inquiryDetailPathFor(
                        GoRouterState.of(context).uri.path,
                        inquiry.category.name,
                        inquiry.id,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.1) : AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? accent : AppColors.warmBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? accent : AppColors.charcoal),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? accent : AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({
    required this.inquiry,
    required this.accent,
    required this.icon,
    required this.onView,
  });

  final SellerInquiry inquiry;
  final Color accent;
  final IconData icon;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '#${inquiry.id}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMutedLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                inquiry.createdAtLabel,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            inquiry.buyerName,
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            inquiry.summary,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onView,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              backgroundColor: AppColors.warmWhite,
            ),
            child: const Text('View details'),
          ),
        ],
      ),
    );
  }
}
