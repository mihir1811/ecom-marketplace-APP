import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../bullions/domain/models/billion.dart';
import '../models/product_detail.dart';

/// Maps a bullion bar/coin onto the universal detail shape.
ProductDetail bullionProductDetail(Bullion b) {
  final metalLabel = _metalLabel(b.metal);
  final perGram = b.weightGrams > 0 ? b.price / b.weightGrams : null;
  final purity = b.purity.toStringAsFixed(1);

  return ProductDetail(
    id: b.id,
    segment: ProductSegment.bullion,
    title: b.name,
    subtitle: '${b.weightLabel} $metalLabel ${b.shape} · $purity fine',
    referenceLabel: 'Stock ID',
    referenceValue: b.id,
    shapeKey: b.shape,
    badges: [
      const ProductBadge('Bullion', tone: ProductBadgeTone.accent),
      ProductBadge(b.certification, tone: ProductBadgeTone.positive),
      ProductBadge(b.presetVariant),
      ProductBadge(b.condition),
    ],
    media: ProductMedia(
      imageSlots: 4,
      certificateLabel: b.certification,
      fallbackIcon: _metalIcon(b.metal),
      fallbackTint: _metalTint(b.metal),
      hasVideo: true,
      videoLabel: 'Bullion video',
    ),
    price: ProductPrice(
      currencySymbol: r'$',
      amountLabel: formatGroupedWhole(b.price),
      priceUsd: b.price,
      priceInr: usdToInr(b.price),
      unitLabel: 'per gram',
      unitAmountLabel: perGram?.toStringAsFixed(2),
    ),
    highlights: [
      ProductHighlight('Weight', b.weightLabel),
      ProductHighlight('Purity', purity),
      ProductHighlight('Metal', metalLabel),
      ProductHighlight('Condition', b.condition),
    ],
    certification: ProductCertification(
      authority: b.certification,
      referenceLabel: 'Mint',
      referenceValue: b.mintMark,
    ),
    availability: ProductAvailability(
      label: b.quantityAvailable > 0 ? 'In stock' : 'Out of stock',
      tone: switch (b.quantityAvailable) {
        0 => ProductStockTone.unavailable,
        < 5 => ProductStockTone.limited,
        _ => ProductStockTone.available,
      },
      detail: b.quantityAvailable > 0
          ? '${b.quantityAvailable} units available'
          : null,
    ),
    specSections: [
      specSection(ProductSpecGroup.essentials, {
        'Metal': metalLabel,
        'Form': b.shape,
        'Weight': b.weightLabel,
        'Purity grade': b.presetVariant,
        'Condition': b.condition,
        'Price per gram':
            perGram == null ? null : '\$${perGram.toStringAsFixed(2)}',
      }),
      specSection(ProductSpecGroup.quality, {
        'Fineness': '$purity / 1000',
        'Purity grade': b.presetVariant,
      }),
      specSection(ProductSpecGroup.material, {
        'Metal': metalLabel,
        'Net metal weight': '${b.weightGrams} g',
      }),
      specSection(ProductSpecGroup.measurements, {
        'Length': '${b.lengthMm} mm',
        'Width': '${b.widthMm} mm',
        'Thickness': '${b.heightMm} mm',
      }),
      specSection(ProductSpecGroup.provenance, {
        'Certification': b.certification,
        'Mint mark': b.mintMark,
      }),
      specSection(ProductSpecGroup.inclusions, {
        'Units available': '${b.quantityAvailable}',
      }),
    ],
    note: 'Bullion is priced against the live spot rate for $metalLabel plus a '
        'mint premium. Fineness and mint mark determine buy-back value.',
  );
}

String _metalLabel(BullionMetal metal) {
  return switch (metal) {
    BullionMetal.gold => 'Gold',
    BullionMetal.silver => 'Silver',
    BullionMetal.platinum => 'Platinum',
    BullionMetal.palladium => 'Palladium',
    BullionMetal.copper => 'Copper',
  };
}

Color _metalTint(BullionMetal metal) {
  return switch (metal) {
    BullionMetal.gold => AppSwatches.yellowGold,
    BullionMetal.silver => AppSwatches.silver,
    BullionMetal.platinum => AppSwatches.platinum,
    BullionMetal.palladium => AppColors.bronzeLight,
    BullionMetal.copper => AppSwatches.copper,
  };
}

IconData _metalIcon(BullionMetal metal) {
  return switch (metal) {
    BullionMetal.gold || BullionMetal.silver => Icons.view_in_ar_outlined,
    BullionMetal.platinum || BullionMetal.palladium => Icons.hexagon_outlined,
    BullionMetal.copper => Icons.hardware_outlined,
  };
}
