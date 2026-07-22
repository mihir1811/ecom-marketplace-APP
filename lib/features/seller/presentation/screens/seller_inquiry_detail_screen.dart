import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/seller_inquiry_mock_data.dart';
import '../../domain/models/seller_inquiry.dart';
import '../widgets/seller_layout.dart';

class SellerInquiryDetailScreen extends StatelessWidget {
  const SellerInquiryDetailScreen({
    required this.categoryName,
    required this.inquiryId,
    super.key,
  });

  final String categoryName;
  final String inquiryId;

  @override
  Widget build(BuildContext context) {
    final inquiry = findSellerInquiry(inquiryId);
    if (inquiry == null) {
      return Center(
        child: TextButton(
          onPressed: () => context.go(AppRouteNames.sellerInquiries),
          child: const Text('Back to inquiries'),
        ),
      );
    }

    final accent = switch (inquiry.category) {
      InquiryCategory.diamond => AppColors.info,
      InquiryCategory.gemstone => AppSwatches.inquiryGemstone,
      InquiryCategory.bullion => AppSwatches.inquiryBullion,
      InquiryCategory.watch => AppColors.textSecondaryLight,
      InquiryCategory.jewelry => AppSwatches.inquiryJewelry,
    };
    final icon = switch (inquiry.category) {
      InquiryCategory.diamond => Icons.diamond_outlined,
      InquiryCategory.gemstone => Icons.auto_awesome,
      InquiryCategory.bullion => Icons.monetization_on_outlined,
      InquiryCategory.watch => Icons.watch_outlined,
      InquiryCategory.jewelry => Icons.workspace_premium_outlined,
    };

    final sections = _groupFields(inquiry.fields);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => openSellerDrawer(context),
                icon: const Icon(Icons.menu),
              ),
              TextButton.icon(
                onPressed: () => context.go(AppRouteNames.sellerInquiries),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('All inquiries'),
              ),
            ],
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${inquiry.category.label.toUpperCase()} INQUIRY',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: AppColors.textMutedLight,
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
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: AppColors.textMutedLight,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  inquiry.createdAtLong,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondaryLight,
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
              const SizedBox(height: 12),
              _Card(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.sandSurface,
                      child: Icon(Icons.person_outline),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CUSTOMER',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: AppColors.textMutedLight,
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
                              const Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: AppColors.textMutedLight,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  inquiry.buyerEmail,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondaryLight,
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
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Inquiry details',
                          style: AppTypography.title.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Specifications from your submission',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final section in sections) ...[
                      const SizedBox(height: 8),
                      Text(
                        section.title,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _TwoColGrid(entries: section.entries),
                    ],
                  ],
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

List<_FieldSection> _groupFields(Map<String, String> fields) {
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
        (k) => lower.contains(k.toLowerCase()) || k.toLowerCase().contains(lower),
      );
      if (hit) {
        matched.add(e);
        used.add(e.key);
      }
    }
    if (matched.isNotEmpty) {
      result.add(_FieldSection(group.key, matched));
    }
  }

  final remaining = fields.entries
      .where((e) => !used.contains(e.key))
      .toList();
  if (remaining.isNotEmpty) {
    result.add(_FieldSection('Other', remaining));
  }
  return result;
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
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final e in entries)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.warmBorder),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMutedLight,
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
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: child,
    );
  }
}
