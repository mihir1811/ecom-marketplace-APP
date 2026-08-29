import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../bullions/domain/models/billion.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../models/listing_seller_info.dart';
import '../models/product_detail.dart';

/// Maps a bullion bar/coin onto the universal detail shape.
ProductDetail bullionProductDetail(Bullion b) {
  final metalLabel = _metalLabel(b.metal);
  final perGram = b.weightGrams > 0 ? b.price / b.weightGrams : null;
  final purity = b.purity > 0 ? b.purity.toStringAsFixed(1) : b.presetVariant;
  final networkImages = b.imageUrls.isNotEmpty
      ? b.imageUrls
      : [
          if (b.renderableImageUrl != null) b.renderableImageUrl!,
        ];

  return ProductDetail(
    id: b.id,
    segment: ProductSegment.bullion,
    apiProductType: CartProductType.bullion,
    title: b.name,
    subtitle: '${b.weightLabel} $metalLabel ${b.shape} · $purity fine',
    referenceLabel: 'Stock ID',
    referenceValue: b.stockNumber ?? b.id,
    shapeKey: b.shape,
    badges: [
      const ProductBadge('Bullion', tone: ProductBadgeTone.accent),
      if (b.certification.isNotEmpty)
        ProductBadge(b.certification, tone: ProductBadgeTone.positive),
      if (b.presetVariant.isNotEmpty) ProductBadge(b.presetVariant),
      if (b.condition.isNotEmpty) ProductBadge(b.condition),
    ],
    media: ProductMedia(
      images: [
        for (final url in networkImages) ProductImage.network(url),
      ],
      imageSlots: networkImages.isEmpty ? 0 : networkImages.length,
      certificateLabel: null,
      shapeKey: null,
      fallbackIcon: _metalIcon(b.metal),
      fallbackTint: _metalTint(b.metal),
      hasVideo: false,
    ),
    price: ProductPrice(
      currencySymbol: AppCurrency.symbol,
      amountLabel: formatGroupedWhole(b.price),
      priceUsd: b.price,
      priceInr: usdToInr(b.price),
      displayAmount: b.price,
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
    availability: _availability(b),
    availabilityStatus: _availabilityStatus(b.availability),
    listingSeller: listingSellerFromSellerId(b.sellerId),
    specSections: [
      specSection(ProductSpecGroup.essentials, {
        'Metal': metalLabel,
        'Form': b.shape,
        'Weight': b.weightLabel,
        'Purity grade': b.presetVariant,
        'Condition': b.condition,
        'Price per gram':
            perGram == null ? null : AppCurrency.format(perGram.toStringAsFixed(2)),
      }),
      specSection(ProductSpecGroup.quality, {
        'Fineness': purity.isEmpty ? null : '$purity / 1000',
        'Purity grade': b.presetVariant,
      }),
      specSection(ProductSpecGroup.material, {
        'Metal': metalLabel,
        'Net metal weight': b.weightGrams > 0
            ? '${formatDecimal(b.weightGrams)} g'
            : null,
      }),
      specSection(ProductSpecGroup.measurements, {
        if (b.demention != null && b.demention!.isNotEmpty)
          'Dimensions': b.demention,
        if (b.lengthMm > 0) 'Length': '${formatDecimal(b.lengthMm)} mm',
        if (b.widthMm > 0) 'Width': '${formatDecimal(b.widthMm)} mm',
        if (b.heightMm > 0) 'Thickness': '${formatDecimal(b.heightMm)} mm',
      }),
      specSection(ProductSpecGroup.provenance, {
        'Certification': b.certification,
        'Mint mark': b.mintMark,
        if (b.mintYear != null) 'Mint year': '${b.mintYear}',
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

ProductAvailability _availability(Bullion b) {
  final normalized = b.availability.trim().toLowerCase();
  if (normalized.contains('hold')) {
    return const ProductAvailability(
      label: 'On hold',
      tone: ProductStockTone.unavailable,
    );
  }
  if (normalized.contains('memo')) {
    return const ProductAvailability(
      label: 'On memo',
      tone: ProductStockTone.unavailable,
    );
  }
  if (b.quantityAvailable <= 0) {
    return ProductAvailability(
      label: b.availability,
      tone: ProductStockTone.unavailable,
    );
  }
  return ProductAvailability(
    label: b.availability,
    tone: b.quantityAvailable < 5
        ? ProductStockTone.limited
        : ProductStockTone.available,
    detail: '${b.quantityAvailable} units available',
  );
}

String? _availabilityStatus(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.contains('hold')) return 'hold';
  if (normalized.contains('memo')) return 'memo';
  if (normalized.contains('sold')) return 'sold';
  if (normalized.contains('available') || normalized == 'yes') return 'yes';
  return normalized.isEmpty ? null : normalized;
}
