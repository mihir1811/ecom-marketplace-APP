import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../../../gemstones/domain/models/gemstone.dart';
import '../models/product_detail.dart';

/// Maps a gemstone listing onto the universal detail shape.
ProductDetail gemstoneProductDetail(Gemstone g) {
  final perCarat = g.pricePerCarat ?? (g.carat > 0 ? g.price / g.carat : null);
  final carat = g.carat.toStringAsFixed(2);
  final authority = _optional(g.lab, uppercase: true);
  final certificateUrl = _optional(g.certificateUrl);
  final certificateLabel = certificateUrl == null
      ? null
      : (authority == null ? 'Certificate' : '$authority certificate');

  return ProductDetail(
    id: g.id,
    segment: ProductSegment.gemstone,
    apiProductType: CartProductType.gemstone,
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
          '${formatDiscountPercent(g.discount!)}% below list',
          tone: ProductBadgeTone.caution,
        ),
    ],
    media: ProductMedia(
      images: [
        if (g.hasNetworkImage)
          for (final url
              in (g.imageUrls.isNotEmpty ? g.imageUrls : [g.imageUrl!]))
            ProductImage.network(url),
      ],
      imageSlots: g.hasNetworkImage
          ? (g.imageUrls.isNotEmpty ? g.imageUrls.length : 1)
          : 0,
      certificateLabel: certificateLabel,
      certificateUrl: certificateUrl,
      shapeKey: null,
      fallbackIcon: Icons.auto_awesome,
      fallbackTint: AppColors.bronzeLight,
      hasVideo: g.videoUrl != null,
      videoLabel: g.videoUrl != null ? 'Video' : null,
      videoUrl: g.videoUrl,
    ),
    price: ProductPrice(
      currencySymbol: AppCurrency.symbol,
      amountLabel: formatGroupedWhole(g.price),
      priceUsd: g.price,
      priceInr: usdToInr(g.price),
      displayAmount: g.price,
      unitLabel: 'per carat',
      unitAmountLabel: perCarat == null ? null : formatGroupedWhole(perCarat),
      discountPercent: g.discount,
    ),
    highlights: [
      ProductHighlight('Carat', carat),
      ProductHighlight('Origin', g.origin.isEmpty ? '-' : g.origin),
      ProductHighlight('Color', g.color.isEmpty ? '-' : g.color),
      ProductHighlight('Treatment', g.treatment.isEmpty ? '-' : g.treatment),
    ],
    certification: ProductCertification(
      authority: authority ?? 'Not certified',
      referenceLabel: 'Certificate',
      referenceValue: _optional(g.certificate) ?? g.stockNumber ?? g.id,
      certificateUrl: certificateUrl,
      certificateLabel: certificateLabel,
    ),
    availability: _availability(g),
    availabilityStatus: g.isSold ? 'sold' : g.availability,
    listingSeller: g.listingSeller,
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
        'Hardness': g.hardness > 0 ? '${formatDecimal(g.hardness)} Mohs' : null,
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
    note:
        'Treatment disclosure follows the laboratory report. Untreated '
        'stones of the same grade carry a premium.',
    naturalSpecTabs: _gemstoneSpecTabs(g),
  );
}

/// Same tabbed card layout as diamonds; gemstone tab names and fields.
ProductTabbedSpecs _gemstoneSpecTabs(Gemstone g) {
  final totalPrice = AppCurrency.format(formatGroupedWhole(g.price));
  final caratWeight =
      g.carat > 0 ? '${g.carat.toStringAsFixed(2)} ct' : '-';
  final type = _na(g.type);
  final shape = _na(g.shape);
  final origin = _na(g.origin);
  final treatment = _na(g.treatment);
  final color = _na(g.color);
  final clarity = _na(g.clarity);
  final cut = _na(g.cut);
  final authority = _optional(g.lab, uppercase: true);
  final certStatus = authority == null
      ? 'This gemstone is not certified'
      : 'This gemstone is certified by $authority';

  return ProductTabbedSpecs(
    tabs: [
      ProductSpecTab(
        title: 'Overview',
        rows: [
          ProductSpec('Total Price', totalPrice),
          ProductSpec('Type', type),
          ProductSpec('Shape', shape),
          ProductSpec('Origin', origin),
          ProductSpec('Treatment', treatment),
          ProductSpec('Carat Weight', caratWeight),
          ProductSpec('Color', color),
          ProductSpec('Clarity', clarity),
          ProductSpec('Cut', cut),
        ],
      ),
      ProductSpecTab(
        title: 'Specifications',
        rows: [
          ProductSpec('Total Price', totalPrice),
          ProductSpec('Carat Weight', caratWeight),
          ProductSpec('Color', color),
          ProductSpec('Clarity', clarity),
          ProductSpec('Cut', cut),
          ProductSpec('Shape', shape),
          ProductSpec('Treatment', treatment),
        ],
      ),
      ProductSpecTab(
        title: 'Certification',
        rows: [
          ProductSpec('Certification Status', certStatus),
        ],
      ),
    ],
  );
}

String _na(String? value) => _optional(value) ?? '-';

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
      tone: ProductStockTone.unavailable,
    ),
    'memo' => const ProductAvailability(
      label: 'On memo',
      tone: ProductStockTone.unavailable,
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
  if (t.isEmpty ||
      t == '-' ||
      t == '—' ||
      t == '–' ||
      t.toLowerCase() == 'n/a') {
    return null;
  }
  return uppercase ? t.toUpperCase() : t;
}
