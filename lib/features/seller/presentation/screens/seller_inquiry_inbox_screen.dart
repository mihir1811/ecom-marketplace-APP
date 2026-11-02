import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/account_nav.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/inquiry_provider.dart';
import '../../domain/models/seller_inquiry.dart';
import '../widgets/seller_layout.dart';

import '../../../../core/l10n/app_localizations.dart';

class SellerInquiryInboxScreen extends ConsumerStatefulWidget {
  const SellerInquiryInboxScreen({super.key, this.showHeader = true});

  /// When false, the parent shell already provides the title/menu app bar.
  final bool showHeader;

  @override
  ConsumerState<SellerInquiryInboxScreen> createState() =>
      _SellerInquiryInboxScreenState();
}

class _SellerInquiryInboxScreenState
    extends ConsumerState<SellerInquiryInboxScreen> {
  InquiryCategory _category = InquiryCategory.diamond;

  IconData _iconFor(InquiryCategory c) => switch (c) {
    InquiryCategory.diamond => Icons.diamond_outlined,
    InquiryCategory.gemstone => Icons.auto_awesome,
    InquiryCategory.bullion => Icons.monetization_on_outlined,
    InquiryCategory.watch => Icons.watch_outlined,
    InquiryCategory.jewelry => Icons.workspace_premium_outlined,
  };

  Color _accentFor(BuildContext context, InquiryCategory c) => switch (c) {
    InquiryCategory.diamond => AppColors.info,
    InquiryCategory.gemstone => AppSwatches.inquiryGemstone,
    InquiryCategory.bullion => AppSwatches.inquiryBullion,
    InquiryCategory.watch => AppColors.textSecondary(context),
    InquiryCategory.jewelry => AppSwatches.inquiryJewelry,
  };

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final sentBy = isBuyerPath(path)
        ? InquirySenderRole.buyer
        : InquirySenderRole.seller;
    final listState = ref.watch(inquiryListProvider(_category));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => openSellerDrawer(context),
                  icon: const Icon(Icons.menu),
                ),
                Text(
                  context.tr(RemainingL10n.inquiries),
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(inquiryListProvider(_category).notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
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
                          color: AppColors.textMuted(
                            context,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.card(context),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.border(context),
                                ),
                              ),
                              child: Text(
                                sentBy == InquirySenderRole.buyer
                                    ? 'Buyer · Sent to admin'
                                    : 'Seller · Sent to admin',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr(RemainingL10n.myInquiries),
                            style: AppTypography.headline.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            context.tr(
                              RemainingL10n.inquiriesYouSubmitGoDirectlyTo,
                            ),
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary(context),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => context.openRoute(
                              inquiryNewPathFor(
                                GoRouterState.of(context).uri.path,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              backgroundColor: AppColors.card(context),
                            ),
                            child: Text(context.tr(RemainingL10n.newInquiry)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr(RemainingL10n.browseByType),
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(RemainingL10n.switchCategoryEachTypeLoadsItsOwn),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in InquiryCategory.values)
                      _CategoryChip(
                        label: c.label,
                        icon: _iconFor(c),
                        selected: _category == c,
                        accent: _accentFor(context, c),
                        onTap: () => setState(() => _category = c),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _accentFor(
                            context,
                            _category,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _iconFor(_category),
                          color: _accentFor(context, _category),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                              listState.isLoading
                                  ? context.tr(RemainingL10n.loadingEllipsis)
                                  : listState.items.isEmpty
                                  ? context.tr(RemainingL10n.showingZeroOfZero)
                                  : context
                                        .tr(RemainingL10n.showingRangeOfTotal, {
                                          'from': '1',
                                          'to': '${listState.items.length}',
                                          'total': '${listState.total}',
                                        }),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (listState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      listState.errorMessage!,
                      style: AppTypography.body.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (listState.isLoading && listState.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (listState.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        context.tr(RemainingL10n.noCategoryInquiries, {
                          'category': _category.label.toLowerCase(),
                        }),
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ),
                  )
                else
                  for (final inquiry in listState.items) ...[
                    _InquiryCard(
                      inquiry: inquiry,
                      accent: _accentFor(context, inquiry.category),
                      icon: _iconFor(inquiry.category),
                      onView: () => context.openRoute(
                        inquiryDetailPathFor(
                          GoRouterState.of(context).uri.path,
                          inquiry.category.name,
                          inquiry.id,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                if (listState.hasMore) ...[
                  const SizedBox(height: 4),
                  OutlinedButton(
                    onPressed: listState.isLoadingMore
                        ? null
                        : () => ref
                              .read(inquiryListProvider(_category).notifier)
                              .loadMore(),
                    child: listState.isLoadingMore
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr(RemainingL10n.loadMore)),
                  ),
                ],
              ],
            ),
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
      color: selected ? accent.withValues(alpha: 0.1) : AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? accent : AppColors.border(context),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? accent : AppColors.textPrimary(context),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? accent : AppColors.textPrimary(context),
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
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '#${inquiry.id.length > 8 ? inquiry.id.substring(0, 8) : inquiry.id}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                inquiry.createdAtLabel,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            inquiry.buyerName,
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            inquiry.summary,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: inquiry.hasAdminReply
                    ? AppColors.info.withValues(alpha: 0.12)
                    : AppColors.surface(context),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                inquiry.hasAdminReply
                    ? context.tr(RemainingL10n.adminReplied)
                    : context.tr(RemainingL10n.awaitingAdmin),
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: inquiry.hasAdminReply
                      ? AppColors.info
                      : AppColors.textMuted(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onView,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              backgroundColor: AppColors.card(context),
            ),
            child: Text(context.tr(RemainingL10n.viewDetails)),
          ),
        ],
      ),
    );
  }
}
