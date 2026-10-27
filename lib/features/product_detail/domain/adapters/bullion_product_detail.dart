import 'package:flutter/material.dart';

import '../../../../core/catalog/catalog_purchase_policy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../bullions/domain/models/billion.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../models/listing_seller_info.dart';
import '../models/product_bullion_detail.dart';
import '../models/product_detail.dart';

/// Maps a bullion bar/coin onto the universal detail shape.
ProductDetail bullionProductDetail(Bullion b) {
  final metalLabel = _metalLabel(b.metal);
  final perGram = b.weightGrams > 0 ? b.price / b.weightGrams : null;
  final purity = b.purity > 0 ? b.purity.toStringAsFixed(1) : b.presetVariant;
  final networkImages = b.imageUrls.isNotEmpty
      ? b.imageUrls
      : [if (b.renderableImageUrl != null) b.renderableImageUrl!];

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
      images: [for (final url in networkImages) ProductImage.network(url)],
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
    // Shown as the at-a-glance tiles on the luxe detail screen.
    highlights: [
      if (b.weightLabel.trim().isNotEmpty)
        ProductHighlight('Weight', b.weightLabel.trim()),
      ProductHighlight('Purity', purity.isEmpty ? '-' : purity),
      ProductHighlight('Metal', metalLabel),
      if (b.shape.trim().isNotEmpty) ProductHighlight('Form', b.shape.trim()),
    ],
    certification: ProductCertification(
      authority: b.certification,
      referenceLabel: 'Mint',
      referenceValue: b.mintMark,
    ),
    availability: _availability(b),
    availabilityStatus: _availabilityStatus(b.availability),
    listingSeller: listingSellerFromSellerId(b.sellerId),
    specSections: const [],
    bullionDetail: _bullionDetail(b, metalLabel: metalLabel),
  );
}

ProductBullionDetail _bullionDetail(Bullion b, {required String metalLabel}) {
  final metalUpper = metalLabel.toUpperCase();
  final shapeUpper = b.shape.trim().isEmpty ? 'BAR' : b.shape.toUpperCase();
  final weightValue = () {
    if (b.weightGrams > 0) {
      if (b.weightGrams == b.weightGrams.roundToDouble()) {
        return b.weightGrams.round().toString();
      }
      return formatDecimal(b.weightGrams);
    }
    final label = b.weightLabel.trim();
    if (label.isEmpty) return '';
    return label.replaceAll(RegExp(r'\s*g$', caseSensitive: false), '');
  }();
  final mint = b.mintMark.trim().isNotEmpty ? b.mintMark.trim() : 'the mint';
  final condition = b.condition.trim().isNotEmpty
      ? b.condition.trim()
      : 'as listed';

  final overview =
      'This ${weightValue.isEmpty ? metalUpper : '$weightValue $metalUpper'} '
      '$shapeUpper from $mint is a premium investment grade bullion. '
      'Featuring the ${b.name} design. Condition: $condition.';

  final dimensions = () {
    final free = b.demention?.trim();
    if (free != null && free.isNotEmpty) return free;
    final parts = <String>[
      if (b.lengthMm > 0) formatDecimal(b.lengthMm),
      if (b.widthMm > 0) formatDecimal(b.widthMm),
      if (b.heightMm > 0) formatDecimal(b.heightMm),
    ];
    if (parts.isEmpty) return null;
    return '${parts.join(' x ')} mm';
  }();

  final rows = <ProductBullionSpecRow>[
    if ((b.stockNumber ?? '').trim().isNotEmpty)
      ProductBullionSpecRow('Stock Number', b.stockNumber!.trim()),
    ProductBullionSpecRow('Metal Type', metalUpper),
    if (b.shape.trim().isNotEmpty) ProductBullionSpecRow('Shape', shapeUpper),
    if (weightValue.isNotEmpty) ProductBullionSpecRow('Weight', weightValue),
    if (b.mintMark.trim().isNotEmpty)
      ProductBullionSpecRow('Mint Mark', b.mintMark.trim()),
    if (b.mintYear != null) ProductBullionSpecRow('Mint Year', '${b.mintYear}'),
    if (b.condition.trim().isNotEmpty)
      ProductBullionSpecRow('Condition', b.condition.trim()),
    if (dimensions != null) ProductBullionSpecRow('Dimensions', dimensions),
    if ((b.certificateNumber ?? '').trim().isNotEmpty)
      ProductBullionSpecRow('Certificate', b.certificateNumber!.trim()),
    if (b.certification.trim().isNotEmpty)
      ProductBullionSpecRow('Certification', b.certification.trim()),
  ];

  return ProductBullionDetail(overview: overview, specRows: rows);
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

String? _availabilityStatus(String status) =>
    CatalogPurchasePolicy.normalizeCode(status);
