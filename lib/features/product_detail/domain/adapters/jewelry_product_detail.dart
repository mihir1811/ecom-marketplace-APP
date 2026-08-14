import 'package:flutter/material.dart';

import '../../../../core/theme/app_swatches.dart';
import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../../../jewelry/domain/models/jewelry.dart';
import '../models/product_detail.dart';

/// Maps a fine jewelry product onto the universal detail shape.
ProductDetail jewelryProductDetail(Jewelry j) {
  return ProductDetail(
    id: j.id,
    segment: ProductSegment.jewelry,
    apiProductType: CartProductType.jewellery,
    title: j.name,
    subtitle: '${j.category} · ${j.metalPurity} ${j.metalColor}',
    referenceLabel: 'SKU',
    referenceValue: j.sku,
    shapeKey: j.stoneShape,
    badges: [
      const ProductBadge('Jewelry', tone: ProductBadgeTone.accent),
      ProductBadge('${j.certification} certified',
          tone: ProductBadgeTone.positive),
      if (j.badge != null) ProductBadge(j.badge!),
      if (j.rating != null)
        ProductBadge(
          '★ ${j.rating}${j.reviewCount == null ? '' : ' · ${j.reviewCount} reviews'}',
        ),
      if (j.discount != null && j.discount! > 0)
        ProductBadge(
          '${formatDiscountPercent(j.discount!)}% off',
          tone: ProductBadgeTone.caution,
        ),
    ],
    media: ProductMedia(
      images: [
        if (j.displayImageUrl != null) ProductImage.network(j.displayImageUrl!),
      ],
      imageSlots: j.displayImageUrl != null ? 1 : 0,
      certificateLabel: null,
      shapeKey: null,
      fallbackIcon: Icons.workspace_premium_outlined,
      fallbackTint: AppSwatches.jewelryMetal(j.metalColor),
      hasVideo: false,
    ),
    price: ProductPrice(
      currencySymbol: AppCurrency.symbol,
      amountLabel: formatInrPrice(j.price),
      priceUsd: inrToUsd(j.price),
      priceInr: j.price,
      displayAmount: j.price,
      discountPercent: j.discount,
      displayAmountIsListPrice: true,
    ),
    highlights: [
      ProductHighlight('Purity', j.metalPurity),
      ProductHighlight('Metal weight', '${formatDecimal(j.metalWeightG)} g'),
      ProductHighlight('Stone weight', '${formatDecimal(j.stoneWeightCt)} ct'),
      ProductHighlight('Stones', '${j.stoneCount}'),
    ],
    certification: ProductCertification(
      authority: j.certification,
      referenceLabel: 'SKU',
      referenceValue: j.sku,
    ),
    availability: _availability(j.availability),
    specSections: [
      specSection(ProductSpecGroup.essentials, {
        'Category': j.category,
        'Sub category': j.subCategory,
        'Worn by': j.gender,
        'Occasion': j.occasion,
        'Condition': j.condition,
      }),
      specSection(ProductSpecGroup.material, {
        'Metal': j.metalType,
        'Metal color': j.metalColor,
        'Purity': j.metalPurity,
        'Stone type': j.stoneType,
        'Stone category': j.stoneCategory,
        'Stone shape': j.stoneShape,
      }),
      specSection(ProductSpecGroup.measurements, {
        'Metal weight': '${formatDecimal(j.metalWeightG)} g',
        'Stone weight': '${formatDecimal(j.stoneWeightCt)} ct',
        'Stone count': '${j.stoneCount}',
        'Ring size': j.ringSize,
        'Bracelet size': j.braceletSize,
        'Bracelet length': j.braceletLength,
        'Chain length': j.chainLength,
        'Necklace length': j.necklaceLength,
      }),
      specSection(ProductSpecGroup.provenance, {
        'Certification': j.certification,
        'SKU': j.sku,
      }),
      specSection(ProductSpecGroup.inclusions, {
        'Metal color options': j.colorVariants.join(' · '),
        'Size options': j.sizeOptions.join(' · '),
      }),
    ],
    note: 'Making charges and applicable taxes are calculated at checkout. '
        'Metal weight may vary marginally by finished size.',
  );
}

ProductAvailability _availability(String status) {
  final normalized = status.toLowerCase();
  final tone = switch (normalized) {
    final s when s.contains('out of stock') || s.contains('sold') =>
      ProductStockTone.unavailable,
    final s when s.contains('made to order') || s.contains('limited') =>
      ProductStockTone.limited,
    _ => ProductStockTone.available,
  };
  return ProductAvailability(label: status, tone: tone);
}
