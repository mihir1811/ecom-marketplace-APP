import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../application/inquiry_provider.dart';
import '../../domain/models/seller_inquiry.dart';
import '../widgets/inquiry_form_fields.dart';
import '../widgets/inquiry_seller_reply.dart';

import '../../../../core/l10n/app_localizations.dart';

class SellerInquiryDetailScreen extends ConsumerWidget {
  const SellerInquiryDetailScreen({
    required this.categoryName,
    required this.inquiryId,
    super.key,
  });

  final String categoryName;
  final String inquiryId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    InquiryCategory category,
  ) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr(RemainingL10n.deleteInquiry)),
        content: Text(
          context.tr(RemainingL10n.thisWillPermanentlyRemoveYourInquiryThis),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr(RemainingL10n.cancel)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              context.tr(RemainingL10n.delete),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(inquiryMutationProvider.notifier)
        .delete(category: category, id: inquiryId);

    if (!context.mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(RemainingL10n.inquiryDeleted))),
        );
        context.goBack();
      case ResultFailure(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = InquiryCategory.fromRouteName(categoryName);
    if (category == null) {
      return Center(
        child: TextButton(
          onPressed: () => context.goBack(),
          child: Text(context.tr(RemainingL10n.backToInquiries)),
        ),
      );
    }

    final inquiryAsync = ref.watch(
      inquiryDetailProvider((category: category, id: inquiryId)),
    );

    return inquiryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        final message = error is Failure
            ? error.message
            : context.tr(RemainingL10n.couldNotLoadInquiry);
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: AppTypography.body),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.goBack(),
                child: Text(context.tr(RemainingL10n.backToInquiries)),
              ),
            ],
          ),
        );
      },
      data: (inquiry) => _InquiryDetailBody(
        inquiry: inquiry,
        category: category,
        onDelete: () => _confirmDelete(context, ref, category),
      ),
    );
  }
}

class _InquiryDetailBody extends StatelessWidget {
  const _InquiryDetailBody({
    required this.inquiry,
    required this.category,
    required this.onDelete,
  });

  final SellerInquiry inquiry;
  final InquiryCategory category;
  final VoidCallback onDelete;

  bool _isImageFieldKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('imageurl') ||
        lower.contains('image url') ||
        lower.contains('reference image') ||
        lower == 'referenceimage' ||
        lower == 'imageurl' ||
        lower == 'image_url';
  }

  @override
  Widget build(BuildContext context) {
    final accent = switch (inquiry.category) {
      InquiryCategory.diamond => AppColors.info,
      InquiryCategory.gemstone => AppSwatches.inquiryGemstone,
      InquiryCategory.bullion => AppSwatches.inquiryBullion,
      InquiryCategory.watch => AppColors.textSecondary(context),
      InquiryCategory.jewelry => AppSwatches.inquiryJewelry,
    };
    final icon = switch (inquiry.category) {
      InquiryCategory.diamond => Icons.diamond_outlined,
      InquiryCategory.gemstone => Icons.auto_awesome,
      InquiryCategory.bullion => Icons.monetization_on_outlined,
      InquiryCategory.watch => Icons.watch_outlined,
      InquiryCategory.jewelry => Icons.workspace_premium_outlined,
    };

    final textFields = Map<String, String>.fromEntries(
      inquiry.fields.entries.where((e) => !_isImageFieldKey(e.key)),
    );
    final sections = _groupFields(context, textFields);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.goBack(),
            child: Text(context.tr(RemainingL10n.allInquiries)),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              _Card(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: accent),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${inquiry.category.label.toUpperCase()} INQUIRY',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                          Text(
                            '#${inquiry.id}',
                            style: AppTypography.headline.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: AppColors.textMuted(context),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  inquiry.createdAtLong,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _Card(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.surface(context),
                      child: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inquiry.sentBy == InquirySenderRole.seller
                                ? context.tr(RemainingL10n.submittedBy)
                                : context.tr(RemainingL10n.submittedBy),
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                          Text(
                            inquiry.buyerName,
                            style: AppTypography.title.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: AppColors.textMuted(context),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  inquiry.buyerEmail,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            inquiry.sentBy == InquirySenderRole.seller
                                ? context.tr(RemainingL10n.sellerToAdmin)
                                : context.tr(RemainingL10n.buyerToAdmin),
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.bronze,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          context.tr(RemainingL10n.inquiryDetails),
                          style: AppTypography.title.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(
                        RemainingL10n.specificationsFromYourSubmissionToAdmin,
                      ),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final section in sections) ...[
                      const SizedBox(height: 6),
                      Text(
                        section.title,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _TwoColGrid(entries: section.entries),
                    ],
                    if (inquiry.referenceImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InquiryImageGallery(
                        title: context.tr(RemainingL10n.yourReferenceImages),
                        images: inquiry.referenceImages,
                      ),
                    ],
                    if (inquiry.imageUrl != null &&
                        inquiry.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        context.tr(RemainingL10n.referenceImage2),
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          inquiry.imageUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            color: AppColors.surface(context),
                            alignment: Alignment.center,
                            child: Text(
                              context.tr(RemainingL10n.couldNotLoadImage),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.support_agent_outlined, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          context.tr(RemainingL10n.adminResponse),
                          style: AppTypography.title.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(RemainingL10n.onlyAdminRepliesAppearHereYou),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (inquiry.hasAdminReply) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(RemainingL10n.adminReply) +
                                  (inquiry.adminReplyAt != null
                                      ? ' · ${inquiry.adminReplyAt}'
                                      : ''),
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (inquiry.adminReply != null &&
                                inquiry.adminReply!.trim().isNotEmpty &&
                                inquiry.adminReply != '(Image attached)') ...[
                              const SizedBox(height: 6),
                              InquiryReplyText(inquiry.adminReply!),
                            ],
                            if (inquiry.adminReplyImages.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              InquiryImageGallery(
                                title: context.tr(
                                  RemainingL10n.adminReferenceImages,
                                ),
                                images: inquiry.adminReplyImages,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        context.tr(RemainingL10n.noAdminResponseYetYourInquiry),
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _Card(
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(context.tr(RemainingL10n.deleteInquiryAction)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldSection {
  const _FieldSection(this.title, this.entries);
  final String title;
  final List<MapEntry<String, String>> entries;
}

List<_FieldSection> _groupFields(
  BuildContext context,
  Map<String, String> fields,
) {
  const groups = <String, List<String>>{
    'General': [
      'Sub-category (PARCEL / SINGLE)',
      'Diamond type (LAB / NATURAL)',
      'Growth process (LAB only)',
      'Shape',
      'Brand',
      'Model',
      'Reference number',
      'Gemstone type',
      'metalType',
      'subCategory',
    ],
    'Certification': [
      'Certified',
      'Certificate company',
      'Is Certified',
      'isCertified',
      'certificateName',
    ],
    'Stone details': [
      'hasStone',
      'stoneType',
      'stoneShape',
      'stoneCut',
      'stoneQuantity',
      'stoneCaratMin',
      'stoneCaratMax',
      'stoneColorMin',
      'stoneColorMax',
      'stoneClarityMin',
      'stoneClarityMax',
    ],
    'Parcel sizing': [
      'Minimum sieve size (PARCEL)',
      'Maximum sieve size (PARCEL)',
    ],
    'Quality & specs': [
      'Minimum carat weight',
      'Maximum carat weight',
      'Minimum color grade',
      'Maximum color grade',
      'Minimum clarity grade',
      'Maximum clarity grade',
      'Cut quality',
      'BGM (brown/green/milky)',
      'Inclusion type',
      'Minimum fluorescence intensity',
      'Maximum fluorescence intensity',
      'Carat weight min',
      'Carat weight max',
      'Primary color min',
      'Primary color max',
      'Clarity',
      'Origin',
      'Treatments',
      'clarity',
      'origin',
      'treatments',
      'Condition',
      'Movement',
      'Case Material',
      'Dial Color',
      'Strap Material',
      'metalFineness',
      'shapeFormat',
      'metalPurity',
      'metalColor',
      'finish',
      'settingType',
      'ringSize',
    ],
    'Commercial': [
      'Quantity',
      'quantity',
      'Minimum total price',
      'Maximum total price',
      'Minimum price per carat',
      'Maximum price per carat',
      'Payment terms',
      'Total budget min',
      'Total budget max',
      'pricePerCaratMin',
      'pricePerCaratMax',
      'totalPriceMin',
      'totalPriceMax',
      'paymentTerms',
      'paymentCurrency',
      'Year min',
      'Year max',
      'Total price min',
      'Total price max',
      'weightMin',
      'weightMax',
      'preferredMint',
      'pricePerGramMin',
      'pricePerGramMax',
    ],
    'Dimensions': [
      'Minimum length (SINGLE)',
      'Maximum length',
      'Minimum width',
      'Maximum width',
      'Minimum height',
      'Maximum height',
      'lengthMin',
      'lengthMax',
      'widthMin',
      'widthMax',
      'heightMin',
      'heightMax',
      'Case Size Min',
      'Case Size Max',
      'shankWidthMin',
      'shankWidthMax',
      'thicknessMin',
      'thicknessMax',
      'approxWeightMin',
      'approxWeightMax',
    ],
    'Logistics & notes': [
      'Remarks',
      'remarks',
      'description',
      'designDescription',
      'Expiry date',
      'urgency',
      'expiry',
      'Reference image URL',
      'Reference Image URL',
      'imageUrl',
      'imageURL',
      'referenceImage',
      'referenceVideo',
      'Delivery location',
      'deliveryLocation',
    ],
  };

  final used = <String>{};
  final result = <_FieldSection>[];

  for (final group in groups.entries) {
    final matched = <MapEntry<String, String>>[];
    for (final key in group.value) {
      if (fields.containsKey(key) && !used.contains(key)) {
        matched.add(MapEntry(key, fields[key]!));
        used.add(key);
      }
    }
    // Also match by lowercase / contains for flexible keys
    for (final e in fields.entries) {
      if (used.contains(e.key)) continue;
      final lower = e.key.toLowerCase();
      final hit = group.value.any(
        (k) =>
            lower.contains(k.toLowerCase()) || k.toLowerCase().contains(lower),
      );
      if (hit) {
        matched.add(e);
        used.add(e.key);
      }
    }
    if (matched.isNotEmpty) {
      result.add(_FieldSection(_sectionTitleFor(context, group.key), matched));
    }
  }

  final remaining = fields.entries.where((e) => !used.contains(e.key)).toList();
  if (remaining.isNotEmpty) {
    result.add(_FieldSection(context.tr(RemainingL10n.other), remaining));
  }
  return result;
}

String _sectionTitleFor(BuildContext context, String groupKey) {
  const titles = <String, String>{
    'General': RemainingL10n.general,
    'Certification': RemainingL10n.certification,
    'Stone details': RemainingL10n.stoneDetails,
    'Parcel sizing': RemainingL10n.parcelSizing,
    'Quality & specs': RemainingL10n.qualitySpecs,
    'Quality / specifications': RemainingL10n.qualitySpecs,
    'Commercial': RemainingL10n.commercial,
    'Dimensions': RemainingL10n.dimensions,
    'Logistics & notes': RemainingL10n.logisticsAndNotes,
  };
  final key = titles[groupKey];
  return key == null ? groupKey : context.tr(key);
}

class _TwoColGrid extends StatelessWidget {
  const _TwoColGrid({required this.entries});

  final List<MapEntry<String, String>> entries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final e in entries)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.value.isEmpty ? '—' : e.value,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: child,
    );
  }
}
