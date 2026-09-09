import 'package:flutter/material.dart';

import '../../../../core/catalog/catalog_purchase_policy.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../../../jewelry/domain/models/jewelry.dart';
import '../models/listing_seller_info.dart';
import '../models/product_detail.dart';
import '../models/product_jewelry_detail.dart';
import '../models/jewelry_unit_pricing.dart';

/// Maps a fine jewelry product onto the universal detail shape.
ProductDetail jewelryProductDetail(Jewelry j) {
  final jewelryDetail = _jewelryDetail(j);
  final pricing = JewelryUnitPricing.from(
    metalPrice: j.metalPrice,
    stonePrice: j.stonePrice,
    makingCharge: j.makingCharge,
    discountAmount: j.discountAmount,
    totalPrice: j.price,
  );
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
      amountLabel: formatInrPrice(pricing.netPrice),
      priceUsd: inrToUsd(pricing.netPrice),
      priceInr: pricing.netPrice,
      // Net unit sell price — discount UI lives in Choose your details.
      displayAmount: pricing.netPrice,
      discountPercent:
          pricing.hasDiscount ? pricing.discountPercent : null,
      displayAmountIsListPrice: false,
    ),
    highlights: const [],
    certification: ProductCertification(
      authority: j.certification,
      referenceLabel: 'SKU',
      referenceValue: j.sku,
    ),
    availability: _availability(j.availability),
    availabilityStatus: _availabilityStatus(j.availability),
    listingSeller: listingSellerFromSellerId(j.sellerId),
    specSections: const [],
    jewelryDetail: jewelryDetail,
  );
}

ProductJewelryDetail _jewelryDetail(Jewelry j) {
  final pricing = JewelryUnitPricing.from(
    metalPrice: j.metalPrice,
    stonePrice: j.stonePrice,
    makingCharge: j.makingCharge,
    discountAmount: j.discountAmount,
    totalPrice: j.price,
  );
  final purityOptions = <String>{
    if (j.metalPurity.trim().isNotEmpty) j.metalPurity.trim(),
    for (final v in j.variants)
      if ((v.metalPurity ?? '').trim().isNotEmpty) v.metalPurity!.trim(),
  }.toList();

  final sizeOptions = <String>{
    ...j.sizeOptions.where((s) => s.trim().isNotEmpty),
    for (final v in j.variants)
      if ((v.sizeLabel ?? '').trim().isNotEmpty) v.sizeLabel!.trim(),
  }.toList();

  final stoneWeightOptions = <String>{
    if (j.stoneWeightCt > 0) _formatCt(j.stoneWeightCt),
    for (final v in j.variants)
      if (v.stoneWeightCt != null && v.stoneWeightCt! > 0)
        _formatCt(v.stoneWeightCt!),
  }.toList();

  final materialBits = [
    if (j.metalPurity.trim().isNotEmpty) j.metalPurity.trim(),
    if (j.metalType.trim().isNotEmpty) j.metalType.trim(),
    if (j.metalColor.trim().isNotEmpty) j.metalColor.trim(),
  ];

  return ProductJewelryDetail(
    description: (j.description?.trim().isNotEmpty ?? false)
        ? j.description!.trim()
        : 'A timeless ${j.metalType.toLowerCase()} ${j.category.toLowerCase()} '
            'set with ${j.stoneShape.toLowerCase()} ${j.stoneType.toLowerCase()} '
            'diamonds.',
    category: j.category,
    gender: j.gender,
    occasion: j.occasion,
    styleNo: j.sku,
    metalType: j.metalType,
    metalColor: j.metalColor,
    metalPurity: j.metalPurity,
    metalFinish: j.metalFinish,
    style: j.style,
    metalWeightG: j.metalWeightG,
    totalWeightG: j.totalWeightG,
    stoneWeightCt: j.stoneWeightCt,
    stoneCount: j.stoneCount,
    braceletSize: j.braceletSize,
    ringSize: j.ringSize,
    chainLength: j.chainLength,
    price: pricing.netPrice,
    currencySymbol: AppCurrency.symbol,
    discountAmount: pricing.hasDiscount ? pricing.discount : null,
    discountPercent: pricing.hasDiscount ? pricing.discountPercent : null,
    metalPrice: pricing.metal > 0 ? pricing.metal : null,
    stonePrice: pricing.stone > 0 ? pricing.stone : null,
    makingCharge: pricing.making > 0 ? pricing.making : null,
    purityOptions: purityOptions,
    sizeOptions: sizeOptions,
    stoneWeightOptions: stoneWeightOptions,
    stones: j.stones
        .map(
          (s) => ProductJewelryStone(
            type: s.type,
            category: s.category,
            shape: s.shape,
            color: s.color,
            clarity: s.clarity,
            weightCt: s.weightCt,
            pieces: s.pieces,
            setting: s.setting,
          ),
        )
        .toList(growable: false),
    variants: j.variants
        .map((v) {
          final vp = JewelryUnitPricing.from(
            metalPrice: v.metalPrice,
            stonePrice: v.stonePrice,
            makingCharge: v.makingCharge,
            discountAmount: v.discountAmount,
            totalPrice: v.price,
          );
          return ProductJewelryVariant(
            id: v.id,
            price: vp.netPrice,
            sku: v.sku,
            metalPurity: v.metalPurity,
            sizeLabel: v.sizeLabel,
            stoneWeightCt: v.stoneWeightCt,
            metalWeightG: v.metalWeightG,
            totalWeightG: v.totalWeightG,
            discountAmount: vp.hasDiscount ? vp.discount : null,
            discountPercent: vp.hasDiscount ? vp.discountPercent : null,
            metalPrice: vp.metal > 0 ? vp.metal : null,
            stonePrice: vp.stone > 0 ? vp.stone : null,
            makingCharge: vp.making > 0 ? vp.making : null,
            metalType: v.metalType,
            metalColor: v.metalColor,
            metalFinish: v.metalFinish,
            braceletSize: v.braceletSize,
            ringSize: v.ringSize,
            chainLength: v.chainLength,
            stoneCount: v.stoneCount,
            stones: v.stones
                .map(
                  (s) => ProductJewelryStone(
                    type: s.type,
                    category: s.category,
                    shape: s.shape,
                    color: s.color,
                    clarity: s.clarity,
                    weightCt: s.weightCt,
                    pieces: s.pieces,
                    setting: s.setting,
                  ),
                )
                .toList(growable: false),
          );
        })
        .toList(growable: false),
    materialLabel: materialBits.isEmpty ? null : materialBits.join(' '),
  );
}

String _formatCt(double ct) {
  final fixed = ct == ct.roundToDouble()
      ? ct.toStringAsFixed(0)
      : ct.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return '${fixed}ct';
}

ProductAvailability _availability(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('sold') || normalized.contains('out of stock')) {
    return ProductAvailability(label: status, tone: ProductStockTone.unavailable);
  }
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
  final tone = switch (normalized) {
    final s when s.contains('made to order') || s.contains('limited') =>
      ProductStockTone.limited,
    _ => ProductStockTone.available,
  };
  return ProductAvailability(label: status, tone: tone);
}

String? _availabilityStatus(String status) =>
    CatalogPurchasePolicy.normalizeCode(status);
