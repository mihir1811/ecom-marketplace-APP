import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../diamonds/domain/models/diamond_display.dart';
import '../models/product_detail.dart';

/// Maps a natural or lab grown diamond onto the universal detail shape.
ProductDetail diamondProductDetail(Diamond d) {
  final segment = d.isLabGrown
      ? ProductSegment.labGrownDiamond
      : ProductSegment.naturalDiamond;
  final authority = DiamondDisplay.optional(d.lab ?? d.certificate, uppercase: true);
  final perCarat =
      d.pricePerCarat ?? (d.carat > 0 ? d.price / d.carat : null);
  final carat = d.carat.toStringAsFixed(2);
  final shape = DiamondDisplay.shape(d.shape);
  final color = DiamondDisplay.optional(d.color, uppercase: true);
  final clarity = DiamondDisplay.optional(d.clarity, uppercase: true);
  final cut = DiamondDisplay.optional(d.cut, uppercase: true);

  final subtitleParts = <String>[
    if (color != null) color,
    if (clarity != null) clarity,
    if (cut != null) '$cut cut',
  ];

  final location = [
    if (!DiamondDisplay.isMissing(d.sellerCity)) d.sellerCity!.trim(),
    if (!DiamondDisplay.isMissing(d.sellerCountry)) d.sellerCountry!.trim(),
  ].join(', ');

  return ProductDetail(
    id: d.id,
    segment: segment,
    apiProductType:
        d.isMelee ? CartProductType.meleeDiamond : CartProductType.diamond,
    title: '$carat ct $shape',
    subtitle: subtitleParts.isEmpty
        ? DiamondDisplay.notAvailable
        : subtitleParts.join(' · '),
    referenceLabel: 'Stock ID',
    referenceValue: DiamondDisplay.optional(d.stockNumber) ?? d.id,
    shapeKey: d.shape,
    badges: [
      ProductBadge(segment.label, tone: ProductBadgeTone.accent),
      if (authority != null)
        ProductBadge('$authority certified', tone: ProductBadgeTone.positive),
      if (d.discount != null && d.discount! > 0)
        ProductBadge(
          '${d.discount!.round()}% below list',
          tone: ProductBadgeTone.caution,
        ),
      if (d.isOnAuction)
        const ProductBadge('On auction', tone: ProductBadgeTone.caution),
      if (d.isSold)
        const ProductBadge('Sold', tone: ProductBadgeTone.neutral),
    ],
    media: ProductMedia(
      images: [
        for (final url in d.imageUrls.take(6)) ProductImage.network(url),
        if (d.imageUrls.isEmpty && d.imageUrl != null)
          ProductImage.network(d.imageUrl!),
      ],
      imageSlots: (d.imageUrls.isEmpty
              ? (d.imageUrl != null ? 1 : 0)
              : d.imageUrls.length)
          .clamp(0, 6),
      certificateLabel: DiamondDisplay.optional(d.certificateUrl) == null
          ? null
          : (authority == null ? 'Certificate' : '$authority certificate'),
      certificateUrl: DiamondDisplay.optional(d.certificateUrl),
      shapeKey: d.shape,
      fallbackIcon: Icons.diamond_outlined,
      fallbackTint: AppColors.bronze,
      hasVideo: d.hasVideo,
      videoLabel: d.hasVideo ? '360° video' : null,
      videoUrl: d.videoUrl,
    ),
    price: ProductPrice(
      currencySymbol: AppCurrency.symbol,
      amountLabel: formatCatalogPrice(d.price),
      priceUsd: d.price,
      priceInr: usdToInr(d.price),
      unitLabel: 'per carat',
      unitAmountLabel:
          perCarat == null ? null : formatCatalogPrice(perCarat),
      discountPercent: d.discount,
    ),
    highlights: [
      ProductHighlight('Carat', carat),
      ProductHighlight('Color', color ?? DiamondDisplay.notAvailable),
      ProductHighlight('Clarity', clarity ?? DiamondDisplay.notAvailable),
      ProductHighlight(
        d.isMelee ? 'Sieve' : 'Cut',
        d.isMelee
            ? (DiamondDisplay.optional(d.sieveLabel) ??
                cut ??
                DiamondDisplay.notAvailable)
            : (cut ?? DiamondDisplay.notAvailable),
      ),
    ],
    certification: ProductCertification(
      authority: authority ?? DiamondDisplay.notAvailable,
      referenceLabel: 'Report',
      referenceValue: DiamondDisplay.optional(d.certificateNumber) ??
          DiamondDisplay.optional(d.stockNumber) ??
          d.id,
      certificateUrl: DiamondDisplay.optional(d.certificateUrl),
      certificateLabel: DiamondDisplay.optional(d.certificateUrl) == null
          ? null
          : (authority == null ? 'Certificate' : '$authority certificate'),
    ),
    availability: _availability(d),
    specSections: [
      specSection(ProductSpecGroup.essentials, {
        'Shape': shape,
        'Carat weight': '$carat ct',
        if (d.isMelee)
          'Carat / pcs': DiamondDisplay.number(d.caratPerPcs, decimals: 3, suffix: ' ct'),
        if (d.isMelee) 'Total pcs': DiamondDisplay.number(d.totalPcs, decimals: 0),
        if (d.isMelee)
          'Total carat': DiamondDisplay.number(d.totalCaratWeight, suffix: ' ct'),
        'Origin type': d.isLabGrown ? 'Lab grown' : 'Natural',
        'Growth method': DiamondDisplay.optional(d.growthType, uppercase: true),
        'Availability': DiamondDisplay.optional(d.available) == null
            ? null
            : DiamondDisplay.availability(d.available),
        'Price per carat': perCarat == null
            ? null
            : AppCurrency.format(formatCatalogPrice(perCarat)),
        if (d.isMelee && d.pricePerPcs != null)
          'Price / pcs': AppCurrency.format(formatCatalogPrice(d.pricePerPcs!)),
        'Make an offer': d.isMakeAnOfferAllowed ? 'Allowed' : null,
      }),
      specSection(ProductSpecGroup.quality, {
        'Cut grade': cut,
        'Color grade': color,
        'Clarity grade': clarity,
        'Polish': DiamondDisplay.optional(d.polish, uppercase: true),
        'Symmetry': DiamondDisplay.optional(d.symmetry, uppercase: true),
        'Fluorescence': DiamondDisplay.optional(d.fluorescence, uppercase: true),
        'Fluorescence color':
            DiamondDisplay.optional(d.fluorescenceColor, uppercase: true),
        'Shade': DiamondDisplay.optional(d.shade),
        'Fancy color': DiamondDisplay.optional(d.fancyColor),
        'Fancy intensity': DiamondDisplay.optional(d.fancyIntensity),
        'Fancy overtone': DiamondDisplay.optional(d.fancyOvertone),
        'Milky': DiamondDisplay.optional(d.milky),
        'Eye clean': DiamondDisplay.boolLabel(d.eyeClean),
        'BGM': DiamondDisplay.boolLabel(d.bgm, yes: 'Present', no: 'None'),
        'Heart & arrow': DiamondDisplay.boolLabel(d.heartAndArrow),
        if (d.isMelee) 'Sieve': DiamondDisplay.optional(d.sieveLabel),
        if (d.isMelee) 'Separable': d.isSeparable ? 'Yes' : 'No',
        'Treatment': DiamondDisplay.optional(d.enhancement),
      }),
      specSection(ProductSpecGroup.measurements, {
        'Measurement': DiamondDisplay.optional(d.measurement),
        'Ratio': DiamondDisplay.optional(d.ratio),
        'Table %': DiamondDisplay.optional(d.tablePercent),
        'Depth %': DiamondDisplay.optional(d.depthPercent),
        'Girdle': DiamondDisplay.optional(d.girdleCondition),
        'Culet': DiamondDisplay.optional(d.culetCondition),
      }),
      specSection(ProductSpecGroup.provenance, {
        'Grading lab': authority,
        'Certificate no.': DiamondDisplay.optional(d.certificateNumber),
        'Stock number': DiamondDisplay.optional(d.stockNumber),
        'Origin': DiamondDisplay.optional(d.origin),
        'Rough source': DiamondDisplay.optional(d.roughSource),
        'Seller': DiamondDisplay.optional(d.sellerCompanyName),
        'Seller location': location.isEmpty ? null : location,
      }),
      specSection(ProductSpecGroup.inclusions, {
        'Media': [
          if (d.hasImage) 'Photography',
          if (d.hasVideo) '360° video',
        ].isEmpty
            ? null
            : [
                if (d.hasImage) 'Photography',
                if (d.hasVideo) '360° video',
              ].join(' · '),
        'Notes': DiamondDisplay.optional(d.comment),
      }),
    ],
    note: d.isLabGrown
        ? 'Lab grown diamonds are chemically and optically identical to mined '
            'diamonds and carry the same grading scales.'
        : 'Grades follow the issuing laboratory report. Verify the report '
            'number before payment.',
    isMakeAnOfferAllowed: d.isMakeAnOfferAllowed,
    minimumOfferPrice: d.minimumOfferPrice,
  );
}

ProductAvailability _availability(Diamond d) {
  if (d.isSold) {
    return const ProductAvailability(
      label: 'Sold',
      tone: ProductStockTone.unavailable,
    );
  }
  return switch ((d.available ?? '').toLowerCase()) {
    'hold' => const ProductAvailability(
        label: 'On hold',
        tone: ProductStockTone.limited,
        detail: 'This stone is currently on hold with another buyer.',
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
