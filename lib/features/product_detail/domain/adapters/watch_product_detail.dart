import 'package:flutter/material.dart';

import '../../../../core/catalog/catalog_purchase_policy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../../../watches/domain/models/watch.dart';
import '../models/listing_seller_info.dart';
import '../models/product_detail.dart';

/// Maps a luxury watch onto the universal detail shape.
ProductDetail watchProductDetail(Watch w) {
  final imageUrl = w.renderableImageUrl;
  final inclusions = [
    if (w.boxIncluded) 'Original box',
    if (w.papersIncluded) 'Papers',
    if (w.warrantyCardIncluded) 'Warranty card',
  ];
  final markdown = catalogMarkdownPercent(w.discount);

  return ProductDetail(
    id: w.id,
    segment: ProductSegment.watch,
    apiProductType: CartProductType.watch,
    title: '${w.brand} ${w.model}',
    subtitle: '${w.collection} · ${w.year}',
    referenceLabel: 'Stock ID',
    referenceValue: w.id,
    badges: [
      const ProductBadge('Watch', tone: ProductBadgeTone.accent),
      ProductBadge(w.condition, tone: ProductBadgeTone.positive),
      if (w.fullSetIncluded) const ProductBadge('Full set'),
      if (markdown != null)
        ProductBadge(
          '${formatDiscountPercent(markdown)}% below list',
          tone: ProductBadgeTone.caution,
        ),
    ],
    media: ProductMedia(
      images: [if (imageUrl != null) ProductImage.network(imageUrl)],
      imageSlots: imageUrl != null ? 1 : 0,
      certificateLabel: null,
      fallbackIcon: Icons.watch_outlined,
      fallbackTint: AppColors.bronze,
      fit: BoxFit.cover,
      hasVideo: false,
    ),
    price: ProductPrice(
      currencySymbol: AppCurrency.symbol,
      amountLabel: formatGroupedWhole(w.price),
      priceUsd: w.price,
      priceInr: usdToInr(w.price),
      displayAmount: w.price,
      discountPercent: markdown,
      listAmount: markdown == null
          ? null
          : catalogListFromNet(w.price, markdown),
    ),
    highlights: [
      ProductHighlight('Case size', '${w.caseSizeMm} mm'),
      ProductHighlight('Movement', w.movement),
      ProductHighlight('Year', '${w.year}'),
      ProductHighlight('Condition', w.condition),
    ],
    availability: _availability(w),
    availabilityStatus: _availabilityStatus(w.availabilityStatus),
    listingSeller: listingSellerFromSellerId(w.sellerId),
    specSections: [
      specSection(ProductSpecGroup.essentials, {
        'Brand': w.brand,
        'Model': w.model,
        'Collection': w.collection,
        'Year': '${w.year}',
        'Category': w.category,
        'Worn by': w.gender,
        'Condition': w.condition,
      }),
      specSection(ProductSpecGroup.quality, {
        'Movement': w.movement,
        'Power reserve': w.powerReserveRange,
        'Water resistance': '${w.waterResistanceM} m',
        'Indexes': w.indexes,
      }),
      specSection(ProductSpecGroup.material, {
        'Case material': w.caseMaterial,
        'Case back': w.caseBack,
        'Bezel': '${w.bezelType} · ${w.bezelMaterial}',
        'Dial color': w.dialColor,
        'Crystal': w.glassMaterial,
        'Crown': w.crownType,
        'Strap': '${w.strapMaterial} · ${w.strapColor}',
        'Clasp': '${w.claspType} · ${w.claspMaterial}',
        'Materials': w.materials.join(' · '),
        'Precious stones': w.preciousStoneTypes.join(' · '),
      }),
      specSection(ProductSpecGroup.measurements, {
        'Case size': '${w.caseSizeMm} mm',
        'Case size band': w.caseSizeRange,
        'Case shape': w.caseShape,
        'Lug width': w.lugWidth,
      }),
      specSection(ProductSpecGroup.provenance, {
        'Certification': w.certification,
        'Production year': '${w.year}',
      }),
      specSection(ProductSpecGroup.inclusions, {
        'In the delivery': inclusions.join(' · '),
        'Configuration': w.configurations.join(' · '),
        'Media': w.hasVideo ? 'Video walkthrough' : null,
      }),
    ],
    note:
        'Condition grade and completeness of the set are the two largest '
        'drivers of resale value on pre-owned references.',
    naturalSpecTabs: _watchSpecTabs(w, inclusions: inclusions),
  );
}

/// Same tabbed card layout as diamonds/gemstones; watch Details / Security fields.
ProductTabbedSpecs _watchSpecTabs(Watch w, {required List<String> inclusions}) {
  final price = AppCurrency.format(formatGroupedWhole(w.price));
  final scope = inclusions.isEmpty ? '-' : inclusions.join(', ');
  final availability = w.inStock
      ? 'Item is in stock'
      : (w.availabilityStatus.trim().isEmpty
            ? 'Availability not listed'
            : w.availabilityStatus);
  final water = w.waterResistanceM > 0 ? '${w.waterResistanceM}m' : '-';
  final caseSize = w.caseSizeMm > 0 ? '${w.caseSizeMm} mm' : '-';
  final year = w.year > 0 ? '${w.year}' : '-';

  return ProductTabbedSpecs(
    tabs: [
      ProductSpecTab(
        title: 'Details',
        sections: [
          ProductSpecTabSection(
            title: 'Basic Info',
            rows: [
              ProductSpec('Listing code', _na(w.id)),
              ProductSpec('Brand', _na(w.brand)),
              ProductSpec('Model', _na(w.model)),
              const ProductSpec('Reference number', '-'),
              ProductSpec('Movement', _na(w.movement)),
              ProductSpec('Case material', _na(w.caseMaterial)),
              ProductSpec('Bracelet material', _na(w.strapMaterial)),
              ProductSpec('Year of production', year),
              ProductSpec('Condition', _na(w.condition)),
              ProductSpec('Scope of delivery', scope),
              ProductSpec('Gender', _na(w.gender)),
              ProductSpec('Price', price),
              ProductSpec('Availability', availability),
            ],
          ),
          ProductSpecTabSection(
            title: 'Caliber',
            rows: [
              ProductSpec('Movement', _na(w.movement)),
              ProductSpec('Caliber/movement', _na(w.collection)),
              ProductSpec('Power reserve', _na(w.powerReserveRange)),
              const ProductSpec('Display', '-'),
            ],
          ),
          ProductSpecTabSection(
            title: 'Case',
            rows: [
              ProductSpec('Case size', caseSize),
              ProductSpec('Case material', _na(w.caseMaterial)),
              ProductSpec('Case shape', _na(w.caseShape)),
              ProductSpec('Glass', _na(w.glassMaterial)),
              ProductSpec('Dial color', _na(w.dialColor)),
              ProductSpec('Water resistance', water),
            ],
          ),
          ProductSpecTabSection(
            title: 'Bracelet/strap',
            rows: [
              ProductSpec('Bracelet material', _na(w.strapMaterial)),
              ProductSpec('Bracelet color', _na(w.strapColor)),
            ],
          ),
        ],
      ),
      const ProductSpecTab(
        title: 'Security',
        rows: [
          ProductSpec(
            'Authenticity and secure checkout',
            'Every listed watch can include box, papers, warranty card, '
                'condition, and seller details so buyers can review the '
                'listing before checkout.',
          ),
        ],
      ),
    ],
  );
}

String _na(String? value) {
  if (value == null) return '-';
  final t = value.trim();
  if (t.isEmpty ||
      t == '-' ||
      t == '—' ||
      t == '–' ||
      t.toLowerCase() == 'n/a') {
    return '-';
  }
  return t;
}

ProductAvailability _availability(Watch w) {
  final status = w.availabilityStatus.trim();
  final normalized = status.toLowerCase();
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
  if (!w.inStock || normalized.contains('sold')) {
    return ProductAvailability(
      label: status.isEmpty ? 'Unavailable' : status,
      tone: ProductStockTone.unavailable,
    );
  }
  return ProductAvailability(
    label: status.isEmpty ? 'Available' : status,
    tone: ProductStockTone.available,
  );
}

String? _availabilityStatus(String status) =>
    CatalogPurchasePolicy.normalizeCode(status);
