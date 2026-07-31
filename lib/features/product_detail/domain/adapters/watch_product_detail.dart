import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../watches/domain/models/watch.dart';
import '../models/product_detail.dart';

/// Maps a luxury watch onto the universal detail shape.
ProductDetail watchProductDetail(Watch w) {
  final imageUrl = w.renderableImageUrl;
  final inclusions = [
    if (w.boxIncluded) 'Original box',
    if (w.papersIncluded) 'Papers',
    if (w.warrantyCardIncluded) 'Warranty card',
  ];

  return ProductDetail(
    id: w.id,
    segment: ProductSegment.watch,
    title: '${w.brand} ${w.model}',
    subtitle: '${w.collection} · ${w.year}',
    referenceLabel: 'Stock ID',
    referenceValue: w.id,
    badges: [
      const ProductBadge('Watch', tone: ProductBadgeTone.accent),
      ProductBadge(w.condition, tone: ProductBadgeTone.positive),
      if (w.fullSetIncluded) const ProductBadge('Full set'),
      if (w.discount != null && w.discount! > 0)
        ProductBadge(
          '${w.discount!.round()}% below list',
          tone: ProductBadgeTone.caution,
        ),
    ],
    media: ProductMedia(
      images: [
        if (imageUrl != null) ProductImage.network(imageUrl),
      ],
      imageSlots: imageUrl != null ? 1 : 0,
      certificateLabel: null,
      fallbackIcon: Icons.watch_outlined,
      fallbackTint: AppColors.bronze,
      fit: BoxFit.cover,
      hasVideo: false,
    ),
    price: ProductPrice(
      currencySymbol: AppCurrency.symbol,
      amountLabel: formatGroupedWhole(w.price),
      priceUsd: w.price,
      priceInr: usdToInr(w.price),
      discountPercent: w.discount,
    ),
    highlights: [
      ProductHighlight('Case size', '${w.caseSizeMm} mm'),
      ProductHighlight('Movement', w.movement),
      ProductHighlight('Year', '${w.year}'),
      ProductHighlight('Condition', w.condition),
    ],
    specSections: [
      specSection(ProductSpecGroup.essentials, {
        'Brand': w.brand,
        'Model': w.model,
        'Collection': w.collection,
        'Year': '${w.year}',
        'Category': w.category,
        'Worn by': w.gender,
        'Condition': w.condition,
      }),
      specSection(ProductSpecGroup.quality, {
        'Movement': w.movement,
        'Power reserve': w.powerReserveRange,
        'Water resistance': '${w.waterResistanceM} m',
        'Indexes': w.indexes,
      }),
      specSection(ProductSpecGroup.material, {
        'Case material': w.caseMaterial,
        'Case back': w.caseBack,
        'Bezel': '${w.bezelType} · ${w.bezelMaterial}',
        'Dial color': w.dialColor,
        'Crystal': w.glassMaterial,
        'Crown': w.crownType,
        'Strap': '${w.strapMaterial} · ${w.strapColor}',
        'Clasp': '${w.claspType} · ${w.claspMaterial}',
        'Materials': w.materials.join(' · '),
        'Precious stones': w.preciousStoneTypes.join(' · '),
      }),
      specSection(ProductSpecGroup.measurements, {
        'Case size': '${w.caseSizeMm} mm',
        'Case size band': w.caseSizeRange,
        'Case shape': w.caseShape,
        'Lug width': w.lugWidth,
      }),
      specSection(ProductSpecGroup.provenance, {
        'Certification': w.certification,
        'Production year': '${w.year}',
      }),
      specSection(ProductSpecGroup.inclusions, {
        'In the delivery': inclusions.join(' · '),
        'Configuration': w.configurations.join(' · '),
        'Media': w.hasVideo ? 'Video walkthrough' : null,
      }),
    ],
    note: 'Condition grade and completeness of the set are the two largest '
        'drivers of resale value on pre-owned references.',
  );
}
