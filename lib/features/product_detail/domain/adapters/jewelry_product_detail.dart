import 'package:flutter/material.dart';

import '../../../../core/theme/app_swatches.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../../../jewelry/domain/models/jewelry.dart';
import '../../../jewelry/domain/models/marketplace_enums.dart';
import '../../../jewelry/domain/models/marketplace_listing.dart';
import '../models/listing_seller_info.dart';
import '../models/product_detail.dart';
import '../models/product_jewelry_detail.dart';

/// Maps a marketplace jewellery piece onto the universal detail shape.
///
/// The detail id is the listing slug (the public lookup key); prices are
/// rupees and purchases go to the on-device jewellery bag.
ProductDetail jewelryProductDetail(Jewelry j) {
  final listing = j.listing;
  final jewelryDetail = _jewelryDetail(j, listing);
  final images = j.imageUrls.isNotEmpty ? j.imageUrls : [?j.displayImageUrl];
  final soldOut = jewelryDetail.soldOut;
  final cert = _certificate(listing);
  final shop = jewelryDetail.shop;
  return ProductDetail(
    id: j.id,
    segment: ProductSegment.jewelry,
    apiProductType: CartProductType.marketplaceJewellery,
    title: j.name,
    subtitle: [
      jewelryDetail.subCategory ?? jewelryDetail.category,
      [?jewelryDetail.metalPurity, ?jewelryDetail.metalType].join(' '),
    ].where((s) => s.trim().isNotEmpty).join(' · '),
    referenceLabel: 'Stock no.',
    referenceValue: jewelryDetail.stockNumber ?? '',
    shapeKey: jewelryDetail.primaryShape,
    badges: [
      if (jewelryDetail.gemstoneOrigin != null)
        ProductBadge(jewelryDetail.gemstoneOrigin!),
      if (jewelryDetail.isMadeToOrder)
        const ProductBadge('Made to order', tone: ProductBadgeTone.caution),
      if (jewelryDetail.freeShipping)
        const ProductBadge('Free shipping', tone: ProductBadgeTone.positive),
      if (cert != null)
        ProductBadge(
          '${cert.certificationLab} certified',
          tone: ProductBadgeTone.positive,
        ),
    ],
    media: ProductMedia(
      images: [for (final url in images) ProductImage.network(url)],
      imageSlots: images.length,
      fallbackIcon: Icons.workspace_premium_outlined,
      fallbackTint: AppSwatches.jewelryMetal(j.metalColor),
    ),
    price: ProductPrice(
      currencySymbol: AppCurrency.inrSymbol,
      amountLabel: formatInrPrice(j.price),
      priceUsd: inrToUsd(j.price),
      priceInr: j.price,
      displayAmount: j.price,
    ),
    highlights: const [],
    certification: cert == null
        ? null
        : ProductCertification(
            authority: cert.certificationLab!,
            referenceLabel: cert.reportNumber == null ? null : 'Report',
            referenceValue: cert.reportNumber,
          ),
    availability: soldOut
        ? const ProductAvailability(
            label: 'Sold out',
            tone: ProductStockTone.unavailable,
          )
        : jewelryDetail.isMadeToOrder
        ? ProductAvailability(
            label: 'Made to order',
            tone: ProductStockTone.limited,
            detail: '${jewelryDetail.processingDays} days to make',
          )
        : const ProductAvailability(
            label: 'In stock',
            tone: ProductStockTone.available,
          ),
    availabilityStatus: soldOut ? 'sold' : 'yes',
    listingSeller: shop == null
        ? null
        : ListingSellerInfo(
            id: shop.sellerId,
            displayName: shop.name,
            location: shop.policies['location'],
            registrationType: ListingSellerRegistrationType.business,
          ),
    specSections: const [],
    jewelryDetail: jewelryDetail,
  );
}

ProductJewelryDetail _jewelryDetail(Jewelry j, MarketplaceListing? l) {
  if (l == null) {
    // A piece known only by name and price (e.g. from chat suggestions).
    return ProductJewelryDetail(
      slug: j.slug ?? j.id,
      listingId: j.listingId ?? j.id,
      description: j.description,
      category: j.category,
      price: j.price,
      maxPrice: j.maxPrice ?? j.price,
      currencySymbol: AppCurrency.inrSymbol,
      totalStock: 0,
      coverImageUrl: j.displayImageUrl,
    );
  }
  final d = l.detail;
  final shop = l.shop;
  String? word(String? enumValue) {
    final w = MarketplaceEnums.label(enumValue);
    return w.isEmpty ? null : w;
  }

  return ProductJewelryDetail(
    slug: l.slug,
    listingId: l.id,
    description: l.description,
    category: l.parentCategoryName ?? l.categoryName ?? '',
    subCategory: l.parentCategoryName == null ? null : l.categoryName,
    stockNumber: l.stockNumber,
    taxLabels: l.taxLabels,
    shop: shop == null
        ? null
        : ProductJewelryShop(
            name: shop.name,
            slug: shop.slug,
            sellerId: shop.sellerId,
            logoUrl: shop.logoUrl,
            policies: shop.policies,
            showPriceBreakdown: shop.showPriceBreakdown,
          ),
    price: l.minPrice,
    maxPrice: l.maxPrice,
    currencySymbol: AppCurrency.inrSymbol,
    totalStock: l.totalStock,
    metalType: word(d.metalType),
    metalPurity: d.metalPurity,
    metalWeightG: d.metalWeightGrams,
    grossWeightG: d.grossWeightGrams,
    primaryGemstone: word(d.primaryGemstone),
    gemstoneOrigin: word(d.gemstoneOrigin),
    primaryShape: d.primaryShape,
    totalCaratWeight: d.totalCaratWeight,
    style: d.style,
    occasion: d.occasion,
    tags: l.tags,
    isMadeToOrder: d.isMadeToOrder,
    processingDays: d.processingDays,
    personalizationEnabled: d.personalizationEnabled,
    personalizationInstructions: d.personalizationInstructions,
    freeShipping: d.freeShipping,
    shipsFromCountry: d.shipsFromCountry,
    returnsAccepted: d.returnsAccepted,
    returnWindowDays: d.returnWindowDays,
    cancellationWindowHours: d.cancellationWindowHours,
    stones: [
      for (final g in l.gemstones)
        ProductJewelryStone(
          type: word(g.type),
          origin: word(g.origin),
          shape: g.shape,
          caratWeight: g.caratWeight,
          quantity: g.quantity,
          color: g.color,
          clarity: g.clarity,
          cut: g.cut,
          certificationLab: g.certificationLab,
          reportNumber: g.reportNumber,
        ),
    ],
    variations: [
      for (final v in l.variations)
        ProductJewelryVariation(name: v.name, options: v.options),
    ],
    customOptions: [
      for (final o in l.customOptions)
        if (o.isText) o.name,
    ],
    skus: [
      for (final s in l.skus)
        ProductJewelrySku(
          id: s.id,
          label: s.label,
          price: s.price,
          stock: s.stock,
          isActive: s.isActive,
          options: s.options,
          breakdown: s.breakdown,
        ),
    ],
    coverImageUrl: l.coverImageUrl,
    isFullRecord: l.isFullRecord,
    ratingAverage: l.ratingAverage,
    ratingCount: l.ratingCount,
  );
}

MarketplaceGemstone? _certificate(MarketplaceListing? l) {
  if (l == null) return null;
  for (final g in l.gemstones) {
    if ((g.certificationLab ?? '').trim().isNotEmpty) return g;
  }
  return null;
}
