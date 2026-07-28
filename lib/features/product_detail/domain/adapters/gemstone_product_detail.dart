import 'package:flutter/material.dart';

import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../gemstones/domain/gemstone_assets.dart';
import '../../../gemstones/domain/models/gemstone.dart';
import '../models/product_detail.dart';

/// Maps a gemstone listing onto the universal detail shape.
ProductDetail gemstoneProductDetail(Gemstone g) {
  final perCarat = g.carat > 0 ? g.price / g.carat : null;
  final carat = g.carat.toStringAsFixed(2);
  final assetPath = gemstoneImagePath(g.type);

  return ProductDetail(
    id: g.id,
    segment: ProductSegment.gemstone,
    title: '$carat ct ${g.type}',
    subtitle: '${g.origin} origin · ${g.color}',
    referenceLabel: 'Stock ID',
    referenceValue: g.id,
    shapeKey: g.shape,
    badges: [
      const ProductBadge('Gemstone', tone: ProductBadgeTone.accent),
      ProductBadge('${g.lab} certified', tone: ProductBadgeTone.positive),
      ProductBadge(g.treatment),
      if (g.discount != null && g.discount! > 0)
        ProductBadge(
          '${g.discount!.round()}% below list',
          tone: ProductBadgeTone.caution,
        ),
    ],
    media: ProductMedia(
      images: [
        if (g.imageUrl != null)
          ProductImage.network(g.imageUrl!)
        else if (assetPath != null)
          ProductImage.asset(assetPath),
      ],
      imageSlots: 4,
      certificateLabel: '${g.lab} certificate',
      fallbackIcon: Icons.auto_awesome,
      fallbackTint: gemstoneHue(g.type),
      hasVideo: true,
      videoLabel: 'Gem video',
    ),
    price: ProductPrice(
      currencySymbol: r'$',
      amountLabel: formatGroupedWhole(g.price),
      priceUsd: g.price,
      priceInr: usdToInr(g.price),
      unitLabel: 'per carat',
      unitAmountLabel:
          perCarat == null ? null : formatGroupedWhole(perCarat),
      discountPercent: g.discount,
    ),
    highlights: [
      ProductHighlight('Carat', carat),
      ProductHighlight('Origin', g.origin),
      ProductHighlight('Color', g.color),
      ProductHighlight('Treatment', g.treatment),
    ],
    certification: ProductCertification(
      authority: g.lab,
      referenceLabel: 'Certificate',
      referenceValue: g.certificate ?? g.id,
    ),
    specSections: [
      specSection(ProductSpecGroup.essentials, {
        'Gemstone type': g.type,
        'Carat weight': '$carat ct',
        'Shape': g.shape,
        'Cut': g.cut,
        'Price per carat':
            perCarat == null ? null : '\$${formatGroupedWhole(perCarat)}',
      }),
      specSection(ProductSpecGroup.quality, {
        'Color': g.color,
        'Clarity': g.clarity,
        'Treatment': g.treatment,
        'Hardness': '${g.hardness} Mohs',
      }),
      specSection(ProductSpecGroup.measurements, {
        'Dimensions': g.dimensions,
      }),
      specSection(ProductSpecGroup.provenance, {
        'Origin': g.origin,
        'Grading lab': g.lab,
        'Certificate': g.certificate,
      }),
    ],
    note: 'Treatment disclosure follows the laboratory report. Untreated '
        'stones of the same grade carry a premium.',
  );
}
