import 'package:flutter/material.dart';

import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../gemstones/domain/gemstone_assets.dart';
import '../../../gemstones/domain/models/gemstone.dart';
import '../models/product_detail.dart';

/// Maps a gemstone listing onto the universal detail shape.
ProductDetail gemstoneProductDetail(Gemstone g) {
  final perCarat = g.pricePerCarat ?? (g.carat > 0 ? g.price / g.carat : null);
  final carat = g.carat.toStringAsFixed(2);
  final assetPath = gemstoneImagePath(g.type);
  final authority = _optional(g.lab, uppercase: true);
  final certificateUrl = _optional(g.certificateUrl);
  final certificateLabel = certificateUrl == null
      ? null
      : (authority == null ? 'Certificate' : '$authority certificate');

  return ProductDetail(
    id: g.id,
    segment: ProductSegment.gemstone,
    title: '$carat ct ${g.type}',
    subtitle: [
      if (g.origin.isNotEmpty) '${g.origin} origin',
      if (g.color.isNotEmpty) g.color,
    ].join(' · '),
    referenceLabel: 'Stock ID',
    referenceValue: g.stockNumber ?? g.id,
    shapeKey: g.shape,
    badges: [
      const ProductBadge('Gemstone', tone: ProductBadgeTone.accent),
      if (authority != null)
        ProductBadge('$authority certified', tone: ProductBadgeTone.positive),
      if (g.qualityGrade != null) ProductBadge(g.qualityGrade!),
      if (g.treatment.isNotEmpty) ProductBadge(g.treatment),
      if (g.discount != null && g.discount! > 0)
        ProductBadge(
          '${g.discount!.round()}% below list',
          tone: ProductBadgeTone.caution,
        ),
    ],
    media: ProductMedia(
      images: [
        if (g.hasNetworkImage)
          for (final url
              in (g.imageUrls.isNotEmpty ? g.imageUrls : [g.imageUrl!]))
            ProductImage.network(url)
        else if (assetPath != null)
          ProductImage.asset(assetPath),
      ],
      imageSlots: g.hasNetworkImage
          ? (g.imageUrls.isNotEmpty ? g.imageUrls.length : 1)
          : (assetPath != null ? 1 : 0),
      certificateLabel: certificateLabel,
      certificateUrl: certificateUrl,
      shapeKey: g.shape,
      fallbackIcon: Icons.auto_awesome,
      fallbackTint: gemstoneHue(g.type),
      hasVideo: g.videoUrl != null,
      videoLabel: g.videoUrl != null ? 'Video' : null,
      videoUrl: g.videoUrl,
    ),
    price: ProductPrice(
      currencySymbol: AppCurrency.symbol,
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
      ProductHighlight('Origin', g.origin.isEmpty ? 'N/A' : g.origin),
      ProductHighlight('Color', g.color.isEmpty ? 'N/A' : g.color),
      ProductHighlight(
        'Treatment',
        g.treatment.isEmpty ? 'N/A' : g.treatment,
      ),
    ],
    certification: ProductCertification(
      authority: authority ?? 'Not certified',
      referenceLabel: 'Certificate',
      referenceValue: _optional(g.certificate) ?? g.stockNumber ?? g.id,
      certificateUrl: certificateUrl,
      certificateLabel: certificateLabel,
    ),
    availability: _availability(g),
    specSections: [
      specSection(ProductSpecGroup.essentials, {
        'Gemstone type': g.type,
        'Carat weight': '$carat ct',
        'Shape': _optional(g.shape),
        'Cut': _optional(g.cut),
        'Price per carat': perCarat == null
            ? null
            : AppCurrency.format(formatGroupedWhole(perCarat)),
      }),
      specSection(ProductSpecGroup.quality, {
        'Color': _optional(g.color),
        'Clarity': _optional(g.clarity),
        'Quality grade': _optional(g.qualityGrade),
        'Treatment': _optional(g.treatment),
        'Hardness': g.hardness > 0
            ? '${formatDecimal(g.hardness)} Mohs'
            : null,
      }),
      specSection(ProductSpecGroup.measurements, {
        'Dimensions': _optional(g.dimensions),
      }),
      specSection(ProductSpecGroup.provenance, {
        'Origin': _optional(g.origin),
        'Grading lab': authority,
        'Certificate no.': _optional(g.certificate),
        'Stock number': _optional(g.stockNumber),
      }),
    ],
    note: 'Treatment disclosure follows the laboratory report. Untreated '
        'stones of the same grade carry a premium.',
  );
}

ProductAvailability _availability(Gemstone g) {
  if (g.isSold) {
    return const ProductAvailability(
      label: 'Sold',
      tone: ProductStockTone.unavailable,
    );
  }
  return switch ((g.availability ?? '').toLowerCase()) {
    'hold' => const ProductAvailability(
        label: 'On hold',
        tone: ProductStockTone.limited,
      ),
    'memo' => const ProductAvailability(
        label: 'On memo',
        tone: ProductStockTone.limited,
      ),
    'yes' => const ProductAvailability(
        label: 'Available',
        tone: ProductStockTone.available,
      ),
    _ => const ProductAvailability(
        label: 'Availability not listed',
        tone: ProductStockTone.limited,
      ),
  };
}

String? _optional(String? value, {bool uppercase = false}) {
  if (value == null) return null;
  final t = value.trim();
  if (t.isEmpty || t == '-' || t == '—' || t == '–' || t.toLowerCase() == 'n/a') {
    return null;
  }
  return uppercase ? t.toUpperCase() : t;
}
