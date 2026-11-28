import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../../../rough_diamonds/domain/models/rough_parcel.dart';
import '../models/listing_seller_info.dart';
import '../models/product_detail.dart';
import '../models/product_rough_detail.dart';

/// Shape key of the rough crystal glyph (placeholder art, cart line icon).
const roughShapeKey = 'Rough';

/// "12.40 ct" with trailing zeros kept to two places.
String roughCarat(double ct) => '${ct.toStringAsFixed(2)} ct';

/// "136 pcs" / "1 pc".
String roughPieces(int pcs) =>
    '${formatGroupedWhole(pcs.toDouble())} ${pcs == 1 ? 'pc' : 'pcs'}';

/// "$4,120/ct".
String roughPerCarat(double usd) =>
    '${AppCurrency.format(formatGroupedWhole(usd.roundToDouble()))}/ct';

/// Maps a rough parcel onto the universal detail shape. [gone] marks a
/// parcel deleted since the list was loaded.
ProductDetail roughProductDetail(RoughParcel p, {bool gone = false}) {
  final typeLabel = p.isLab ? 'Lab-grown rough' : 'Natural rough';
  final rough = ProductRoughDetail(parcel: p, isGone: gone);
  final onSale = rough.onSale;
  final tag = p.availabilityTag;
  final cpp = p.caratPerPiece;
  final hasLabReport =
      p.labReportAvailable &&
      (_text(p.labName) != null || _text(p.labReportUrl) != null);

  return ProductDetail(
    id: p.id,
    segment: ProductSegment.roughDiamond,
    apiProductType: CartProductType.roughDiamond,
    title: p.displayName,
    subtitle: [
      typeLabel,
      ?(p.isLab ? _text(p.growthType) : null),
      ?_text(p.crystalShape),
      ?_text(p.roughQuality),
    ].join(' · '),
    referenceLabel: 'Stock number',
    referenceValue: p.stockNumber.isEmpty ? p.id : p.stockNumber,
    shapeKey: roughShapeKey,
    badges: [
      ProductBadge(
        p.isLab ? 'Lab-grown' : 'Natural',
        tone: ProductBadgeTone.accent,
      ),
      if (p.isLab && _text(p.growthType) != null) ProductBadge(p.growthType!),
      if (tag != null) ProductBadge(tag, tone: ProductBadgeTone.caution),
      if (p.inAuction)
        const ProductBadge('On auction', tone: ProductBadgeTone.accent),
      if (p.buy.separable)
        const ProductBadge('Sold by lot', tone: ProductBadgeTone.positive),
      if (p.seller?.isVerified ?? false)
        const ProductBadge('Verified seller', tone: ProductBadgeTone.positive),
    ],
    media: ProductMedia(
      images: [for (final url in p.images) ProductImage.network(url)],
      imageSlots: p.images.length,
      shapeKey: roughShapeKey,
      fallbackIcon: Icons.diamond_outlined,
      fallbackTint: AppColors.bronzeLight,
      hasVideo: _text(p.videoUrl) != null,
      videoLabel: _text(p.videoUrl) == null ? null : 'Video',
      videoUrl: _text(p.videoUrl),
    ),
    price: ProductPrice(
      currencySymbol: AppCurrency.symbol,
      amountLabel: formatGroupedWhole(p.totalPrice),
      priceUsd: p.totalPrice,
      priceInr: usdToInr(p.totalPrice),
      displayAmount: p.totalPrice,
      unitLabel: 'per carat',
      unitAmountLabel: p.pricePerCarat > 0
          ? formatGroupedWhole(p.pricePerCarat.roundToDouble())
          : null,
    ),
    highlights: [
      ProductHighlight('Weight', roughCarat(p.totalCaratWeight)),
      ProductHighlight('Pieces', roughPieces(p.totalPcs)),
      if (cpp != null) ProductHighlight('Avg ct/pc', cpp.toStringAsFixed(2)),
      ProductHighlight(
        'Quality',
        _text(p.roughQuality) ?? _text(p.manufacturingPotential) ?? '-',
      ),
    ],
    certification: hasLabReport
        ? ProductCertification(
            authority: _text(p.labName) ?? 'Lab',
            referenceLabel: 'Report',
            referenceValue: _text(p.labReportNumber),
            certificateUrl: _text(p.labReportUrl),
            certificateLabel: 'Lab report',
          )
        : null,
    availability: _availability(p, gone: gone),
    availabilityStatus: gone ? 'unavailable' : p.statusCode,
    listingSeller: _seller(p),
    note: gone
        ? 'This parcel is no longer available.'
        : p.isExpired
        ? 'This listing has expired.'
        : null,
    isMakeAnOfferAllowed:
        p.isMakeAnOfferAllowed && onSale && p.buy.canBuyWhole && !p.inAuction,
    maxOfferAttemptsPerUser: p.maxOfferAttemptsPerUser,
    isSold: !onSale,
    isOnAuction: p.inAuction,
    specSections: const [],
    naturalSpecTabs: _specTabs(p),
    roughDetail: rough,
  );
}

ProductAvailability _availability(RoughParcel p, {required bool gone}) {
  if (gone || p.isSold || p.isExpired || !p.buy.onSale) {
    final tag = p.availabilityTag;
    if (!gone && !p.isSold && !p.isExpired && tag != null) {
      return ProductAvailability(
        label: tag == 'Hold' ? 'On hold' : 'On memo',
        tone: ProductStockTone.unavailable,
      );
    }
    return ProductAvailability(
      label: p.isSold ? 'Sold' : 'Not available',
      tone: ProductStockTone.unavailable,
    );
  }
  if (p.buy.separable) {
    return ProductAvailability(
      label: 'Available',
      tone: ProductStockTone.limited,
      detail:
          'Left: ${roughCarat(p.buy.remainingCarat)}, '
          '${AppCurrency.format(formatGroupedWhole(p.buy.remainingPrice))}',
    );
  }
  return const ProductAvailability(
    label: 'Available',
    tone: ProductStockTone.available,
  );
}

ListingSellerInfo? _seller(RoughParcel p) {
  final s = p.seller;
  if (s == null) return listingSellerFromSellerId(p.sellerId);
  return ListingSellerInfo(
    id: s.id.isEmpty ? p.sellerId : s.id,
    userId: s.userId,
    displayName: _text(s.companyName) ?? 'Seller',
    location: s.location,
  );
}

/// Seller-form groups as luxe spec tabs; empty rows and tabs are dropped.
ProductTabbedSpecs _specTabs(RoughParcel p) {
  String? mm(double? v) => v == null || v <= 0 ? null : formatDecimal(v);
  final dims = [mm(p.length), mm(p.width), mm(p.height)];
  final dimensions = dims.every((d) => d == null)
      ? null
      : '${dims.map((d) => d ?? '–').join(' × ')} mm';
  final cpp = p.caratPerPiece;

  final details = <ProductSpecTabSection>[
    _section('Parcel', {
      'Parcel type': p.parcelType,
      'Total weight': roughCarat(p.totalCaratWeight),
      'Pieces': roughPieces(p.totalPcs),
      'Average ct/pc': cpp?.toStringAsFixed(2),
      'Price per carat': p.pricePerCarat > 0
          ? roughPerCarat(p.pricePerCarat)
          : null,
      'Price per piece': (p.pricePerPiece ?? 0) > 0
          ? AppCurrency.format(formatGroupedWhole(p.pricePerPiece!))
          : null,
      'Consistency': p.parcelConsistency,
      'Composition': p.compositionType,
      'Separable': p.isSeparable,
    }),
    _section('Origin', {
      'Country': p.countryOfOrigin,
      'Mine / source': p.mineSource,
      'Growth type': p.isLab ? p.growthType : null,
      'Kimberley Process': p.kpStatus,
      'KP certificate': p.kpCertificateNumber,
    }),
    _section('Crystal', {
      'Shape': p.crystalShape,
      'Condition': p.crystalCondition,
      'Transparency': p.transparency,
      'Surface': p.surfaceCondition,
      'Structure': p.crystalStructure,
      'Twinning': p.twinning,
      'Fluorescence': p.fluorescence,
    }),
    _section('Colour & clarity', {
      'Colour': p.colorRange,
      'Colour distribution': p.colorDistribution,
      'Clarity': p.clarityRange,
    }),
    _section('Manufacturing', {
      'Rough quality': p.roughQuality,
      'Potential': p.manufacturingPotential,
      'Estimated yield': p.estimatedYield == null
          ? null
          : '${formatDecimal(p.estimatedYield!)}%',
      'Dimensions (L × W × H)': dimensions,
    }),
  ].where((s) => s.rows.isNotEmpty).toList(growable: false);

  final terms = _rows({
    'Payment': p.paymentTerms,
    'Delivery': p.deliveryTerms,
    'Delivery time': p.deliveryDays == null
        ? null
        : '${p.deliveryDays} ${p.deliveryDays == 1 ? 'day' : 'days'}',
    'Inspection': p.inspectionAllowed == null
        ? null
        : (p.inspectionAllowed! ? 'Allowed' : 'Not allowed'),
    'Returns': p.returnTerms,
  });
  final description = _text(p.description);

  return ProductTabbedSpecs(
    tabs: [
      if (details.isNotEmpty)
        ProductSpecTab(title: 'Details', sections: details),
      if (terms.isNotEmpty) ProductSpecTab(title: 'Terms', rows: terms),
      if (description != null)
        ProductSpecTab(
          title: 'Description',
          isComment: true,
          commentBody: description,
        ),
    ],
  );
}

ProductSpecTabSection _section(String title, Map<String, String?> entries) =>
    ProductSpecTabSection(title: title, rows: _rows(entries));

List<ProductSpec> _rows(Map<String, String?> entries) => [
  for (final e in entries.entries)
    if (_text(e.value) case final v?) ProductSpec(e.key, v),
];

String? _text(String? value) {
  final t = value?.trim() ?? '';
  if (t.isEmpty || t == '-' || t == '—' || t.toLowerCase() == 'n/a') {
    return null;
  }
  return t;
}
