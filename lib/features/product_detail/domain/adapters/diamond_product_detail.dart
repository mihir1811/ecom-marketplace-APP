import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../models/product_detail.dart';

/// Maps a natural or lab grown diamond onto the universal detail shape.
ProductDetail diamondProductDetail(Diamond d) {
  final segment = d.isLabGrown
      ? ProductSegment.labGrownDiamond
      : ProductSegment.naturalDiamond;
  final authority = d.lab ?? d.certificate;
  final perCarat =
      d.pricePerCarat ?? (d.carat > 0 ? d.price / d.carat : null);
  final carat = d.carat.toStringAsFixed(2);

  return ProductDetail(
    id: d.id,
    segment: segment,
    title: '$carat ct ${d.shape}',
    subtitle: '${d.color} · ${d.clarity} · ${d.cut} cut',
    referenceLabel: 'Stock ID',
    referenceValue: d.id,
    shapeKey: d.shape,
    badges: [
      ProductBadge(segment.label, tone: ProductBadgeTone.accent),
      ProductBadge('$authority certified', tone: ProductBadgeTone.positive),
      if (d.discount != null && d.discount! > 0)
        ProductBadge(
          '${d.discount!.round()}% below list',
          tone: ProductBadgeTone.caution,
        ),
    ],
    media: ProductMedia(
      images: [
        if (d.imageUrl != null) ProductImage.network(d.imageUrl!),
      ],
      imageSlots: 4,
      certificateLabel: '$authority certificate',
      fallbackIcon: Icons.diamond_outlined,
      fallbackTint: AppColors.bronze,
      hasVideo: true,
      videoLabel: d.hasVideo ? '360° video' : 'Video walkthrough',
    ),
    price: ProductPrice(
      currencySymbol: r'$',
      amountLabel: formatGroupedWhole(d.price),
      priceUsd: d.price,
      priceInr: usdToInr(d.price),
      unitLabel: 'per carat',
      unitAmountLabel:
          perCarat == null ? null : formatGroupedWhole(perCarat),
      discountPercent: d.discount,
    ),
    highlights: [
      ProductHighlight('Carat', carat),
      ProductHighlight('Color', d.color),
      ProductHighlight('Clarity', d.clarity),
      ProductHighlight('Cut', d.cut),
    ],
    certification: ProductCertification(
      authority: authority,
      referenceLabel: 'Report',
      referenceValue: d.id,
    ),
    specSections: [
      specSection(ProductSpecGroup.essentials, {
        'Shape': d.shape,
        'Carat weight': '$carat ct',
        'Origin type': d.isLabGrown ? 'Lab grown' : 'Natural',
        'Price per carat':
            perCarat == null ? null : '\$${formatGroupedWhole(perCarat)}',
      }),
      specSection(ProductSpecGroup.quality, {
        'Cut grade': d.cut,
        'Color grade': d.color,
        'Clarity grade': d.clarity,
        'Polish': d.polish,
        'Symmetry': d.symmetry,
        'Fluorescence': d.fluorescence,
      }),
      specSection(ProductSpecGroup.provenance, {
        'Grading lab': authority,
        'Certificate': d.certificate,
        'Report number': d.id,
      }),
      specSection(ProductSpecGroup.inclusions, {
        'Media': [
          if (d.hasImage) 'Photography',
          if (d.hasVideo) '360° video',
        ].join(' · '),
      }),
    ],
    note: d.isLabGrown
        ? 'Lab grown diamonds are chemically and optically identical to mined '
            'diamonds and carry the same grading scales.'
        : 'Grades follow the issuing laboratory report. Verify the report '
            'number before payment.',
  );
}
