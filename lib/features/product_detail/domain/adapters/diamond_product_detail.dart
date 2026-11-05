import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_rates.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../../../diamonds/domain/melee_lot_figures.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../diamonds/domain/models/diamond_display.dart';
import '../models/product_detail.dart';
import '../models/listing_seller_info.dart';

/// Maps a natural or lab grown diamond onto the universal detail shape.
ProductDetail diamondProductDetail(Diamond d) {
  final segment = d.isLabGrown
      ? ProductSegment.labGrownDiamond
      : ProductSegment.naturalDiamond;
  final authority = DiamondDisplay.optional(
    d.lab ?? d.certificate,
    uppercase: true,
  );
  // Melee: seller figures, gaps estimated from the sieve chart.
  final lot = d.isMelee ? MeleeLotFigures.of(d) : null;
  final perCarat =
      lot?.pricePerCarat ??
      d.pricePerCarat ??
      (d.carat > 0 ? d.price / d.carat : null);
  final carat = (lot?.totalCarat ?? d.carat).toStringAsFixed(2);
  String approx(bool estimated) => estimated ? ' (approx.)' : '';
  final shape = DiamondDisplay.shape(d.shape);
  final color = DiamondDisplay.displayPrimaryColor(
    color: d.color,
    fancyColor: d.fancyColor,
    fancyIntensity: d.fancyIntensity,
    uppercase: true,
  );
  final colorIsMissing = color == DiamondDisplay.missing;
  final clarity = DiamondDisplay.optional(d.clarity, uppercase: true);
  final cut = DiamondDisplay.optional(d.cut, uppercase: true);

  final subtitleParts = <String>[
    if (!colorIsMissing) color,
    if (clarity != null) clarity,
    if (cut != null) '$cut cut',
  ];

  final location = [
    if (!DiamondDisplay.isMissing(d.sellerCity)) d.sellerCity!.trim(),
    if (!DiamondDisplay.isMissing(d.sellerCountry)) d.sellerCountry!.trim(),
  ].join(', ');

  final belowList = catalogMarkdownPercent(d.discount);
  final listFromRap = (d.rap != null && d.rap! > 0 && d.carat > 0)
      ? d.rap! * d.carat
      : null;
  final listAmount = belowList == null
      ? null
      : (listFromRap != null && listFromRap > d.price
            ? listFromRap
            : catalogListFromNet(d.price, belowList));

  final sellerInfo =
      d.listingSeller ??
      (DiamondDisplay.optional(d.sellerCompanyName) == null
          ? null
          : ListingSellerInfo(
              displayName: d.sellerCompanyName!.trim(),
              location: location.isEmpty ? null : location,
            ));

  return ProductDetail(
    id: d.id,
    segment: segment,
    apiProductType: d.isMelee
        ? CartProductType.meleeDiamond
        : CartProductType.diamond,
    title: '$carat ct $shape',
    subtitle: subtitleParts.isEmpty
        ? DiamondDisplay.missing
        : subtitleParts.join(' · '),
    referenceLabel: 'Stock ID',
    referenceValue: DiamondDisplay.optional(d.stockNumber) ?? d.id,
    shapeKey: d.shape,
    stoneColor: ProductStoneColor(
      grade: d.color,
      fancyColor: d.fancyColor,
      intensity: d.fancyIntensity,
      overtone: d.fancyOvertone,
    ),
    badges: [
      ProductBadge(segment.label, tone: ProductBadgeTone.accent),
      if (authority != null)
        ProductBadge('$authority certified', tone: ProductBadgeTone.positive),
      if (belowList != null)
        ProductBadge(
          '${formatDiscountPercent(belowList)}% below list',
          tone: ProductBadgeTone.caution,
        ),
      if (d.isOnAuction)
        const ProductBadge('On auction', tone: ProductBadgeTone.caution),
      if (d.isSold) const ProductBadge('Sold', tone: ProductBadgeTone.neutral),
    ],
    media: ProductMedia(
      images: [
        for (final url in d.imageUrls.take(6)) ProductImage.network(url),
        if (d.imageUrls.isEmpty && d.imageUrl != null)
          ProductImage.network(d.imageUrl!),
      ],
      imageSlots:
          (d.imageUrls.isEmpty
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
      displayAmount: d.price,
      unitLabel: 'per carat',
      unitAmountLabel: perCarat == null ? null : formatCatalogPrice(perCarat),
      discountPercent: belowList,
      listAmount: listAmount,
    ),
    highlights: [
      ProductHighlight('Carat', carat),
      ProductHighlight('Color', color),
      ProductHighlight('Clarity', clarity ?? DiamondDisplay.missing),
      ProductHighlight(
        d.isMelee ? 'Sieve' : 'Cut',
        d.isMelee
            ? (DiamondDisplay.optional(d.sieveLabel) ??
                  cut ??
                  DiamondDisplay.missing)
            : (cut ?? DiamondDisplay.missing),
      ),
    ],
    certification: ProductCertification(
      authority: authority ?? DiamondDisplay.missing,
      referenceLabel: 'Report',
      referenceValue:
          DiamondDisplay.optional(d.certificateNumber) ??
          DiamondDisplay.optional(d.stockNumber) ??
          d.id,
      certificateUrl: DiamondDisplay.optional(d.certificateUrl),
      certificateLabel: DiamondDisplay.optional(d.certificateUrl) == null
          ? null
          : (authority == null ? 'Certificate' : '$authority certificate'),
    ),
    availability: _availability(d),
    availabilityStatus: d.isSold ? 'sold' : d.available,
    listingSeller: sellerInfo,
    specSections: [
      specSection(ProductSpecGroup.essentials, {
        'Shape': shape,
        'Carat weight': '$carat ct',
        if (lot != null)
          'Carat / pcs': DiamondDisplay.number(
            lot.caratPerPcs,
            decimals: 3,
            suffix: ' ct${approx(lot.caratPerPcsApprox)}',
          ),
        if (lot != null)
          'Total pcs': DiamondDisplay.number(
            lot.totalPcs,
            decimals: 0,
            suffix: approx(lot.totalPcsApprox),
          ),
        if (lot != null)
          'Total carat': DiamondDisplay.number(
            lot.totalCarat,
            suffix: ' ct${approx(lot.totalCaratApprox)}',
          ),
        'Origin type': d.isLabGrown ? 'Lab grown' : 'Natural',
        'Growth method': DiamondDisplay.optional(d.growthType, uppercase: true),
        'Availability': DiamondDisplay.optional(d.available) == null
            ? null
            : DiamondDisplay.availability(d.available),
        'Price per carat': perCarat == null
            ? null
            : '${AppCurrency.format(formatCatalogPrice(perCarat))}'
                  '${approx(lot?.pricePerCaratApprox ?? false)}',
        if (lot?.pricePerPcs case final ppp?)
          'Price / pcs':
              '${AppCurrency.format(formatCatalogPrice(ppp))}'
              '${approx(lot!.pricePerPcsApprox)}',
        'Make an offer': d.isMakeAnOfferAllowed ? 'Allowed' : null,
      }),
      specSection(ProductSpecGroup.quality, {
        'Cut grade': cut,
        'Color grade': colorIsMissing ? null : color,
        'Clarity grade': clarity,
        'Polish': DiamondDisplay.optional(d.polish, uppercase: true),
        'Symmetry': DiamondDisplay.optional(d.symmetry, uppercase: true),
        'Fluorescence': DiamondDisplay.optional(
          d.fluorescence,
          uppercase: true,
        ),
        'Fluorescence color': DiamondDisplay.optional(
          d.fluorescenceColor,
          uppercase: true,
        ),
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
      }),
      specSection(ProductSpecGroup.inclusions, {
        'Media':
            [
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
    maxOfferAttemptsPerUser: d.maxOfferAttemptsPerUser,
    isSold: d.isSold,
    isOnAuction: d.isOnAuction,
    naturalSpecTabs: d.isMelee ? _meleeSpecTabs(d) : _singleSpecTabs(d),
    meleeLot: lot == null
        ? null
        : ProductMeleeQty(
            totalPcs: lot.totalPcs,
            totalCarat: lot.totalCarat,
            caratPerPcs: lot.caratPerPcs,
            pricePerPcs: lot.pricePerPcs,
            pricePerCarat: lot.pricePerCarat,
            pcsApprox: lot.pcsApprox,
            caratApprox: lot.caratApprox,
            shape: shape == DiamondDisplay.missing ? null : shape,
          ),
  );
}

const _emDash = '—';

String _dash(String? value) {
  final text = DiamondDisplay.optional(value);
  return text ?? _emDash;
}

String _orDash(String value) =>
    DiamondDisplay.isMissing(value) ? _emDash : value;

String _grade(String? value) {
  if (DiamondDisplay.isMissing(value)) return _emDash;
  return DiamondDisplay.gradeChip(value);
}

String _percent(String? value) {
  if (DiamondDisplay.isMissing(value)) return _emDash;
  final t = value!.trim();
  return t.endsWith('%') ? t : '$t%';
}

String _weightCt(double carat) {
  final text = carat == carat.roundToDouble()
      ? carat.toInt().toString()
      : carat.toString();
  return '$text CT';
}

String _cutSymPol(Diamond d) {
  return '${_grade(d.cut)} - ${_grade(d.symmetry)} - ${_grade(d.polish)}';
}

ProductTabbedSpecs _meleeSpecTabs(Diamond d) {
  final comment = DiamondDisplay.optional(d.comment);
  final origin =
      DiamondDisplay.optional(d.origin) ??
      (d.isLabGrown ? 'Lab-Grown Melee' : null);

  return ProductTabbedSpecs(
    tabs: [
      ProductSpecTab(
        title: 'Summary',
        rows: [
          ProductSpec('Shape', DiamondDisplay.shape(d.shape)),
          ProductSpec(
            'Weight per piece',
            DiamondDisplay.number(d.caratPerPcs, decimals: 2, suffix: ' ct') ??
                _emDash,
          ),
          ProductSpec('Total pieces', d.totalPcs?.toString() ?? _emDash),
          ProductSpec(
            'Total Weight',
            DiamondDisplay.number(d.totalCaratWeight, suffix: ' ct') ??
                _weightCt(d.carat),
          ),
          ProductSpec('Color', _dash(d.color)),
          ProductSpec('Clarity', _dash(d.clarity)),
          ProductSpec('Cut', _dash(d.cut)),
        ],
      ),
      ProductSpecTab(
        title: 'Details',
        rows: [
          ProductSpec('Sieve', _dash(d.sieveLabel)),
          ProductSpec('Measurement min', _dash(d.measurementMin)),
          ProductSpec('Measurement max', _dash(d.measurementMax)),
          ProductSpec('Ratio', _dash(d.ratio)),
          ProductSpec('Shade', _dash(d.shade)),
          ProductSpec('Origin', origin ?? _emDash),
          ProductSpec('Growth', _dash(d.growthType)),
          ProductSpec(
            'Certificate #',
            _dash(d.certificateNumber ?? d.certificate),
          ),
          ProductSpec('Treatment', _dash(d.enhancement)),
          ProductSpec('Polish', _dash(d.polish)),
        ],
      ),
      ProductSpecTab(
        title: 'Comment',
        isComment: true,
        commentBody: comment ?? 'No Comment Available',
      ),
    ],
    meleeQty: d.isSeparable
        ? ProductMeleeQty(
            totalPcs: d.totalPcs,
            totalCarat: d.totalCaratWeight,
            caratPerPcs: d.caratPerPcs,
          )
        : null,
  );
}

ProductTabbedSpecs _singleSpecTabs(Diamond d) {
  final comment = DiamondDisplay.optional(d.comment);
  final measurement =
      DiamondDisplay.optional(d.measurement) ??
      _measurementRange(d.measurementMin, d.measurementMax);
  final bgm =
      DiamondDisplay.boolLabel(
        d.bgm,
        yes: d.isLabGrown ? 'YES' : 'Present',
        no: d.isLabGrown ? 'NO' : 'None',
      ) ??
      _emDash;
  final lastRow = d.isLabGrown
      ? ProductSpec('Growth Type', _dash(d.growthType))
      : ProductSpec('Rough Source', _dash(d.roughSource));

  return ProductTabbedSpecs(
    tabs: [
      ProductSpecTab(
        title: 'Overview',
        rows: [
          ProductSpec(
            'Certificate',
            _dash(d.certificateNumber ?? d.certificate),
          ),
          ProductSpec(
            'Shape',
            _orDash(DiamondDisplay.shape(d.shape).toUpperCase()),
          ),
          ProductSpec('Weight', _weightCt(d.carat)),
          ProductSpec(
            'Color',
            _orDash(
              DiamondDisplay.displayPrimaryColor(
                color: d.color,
                fancyColor: d.fancyColor,
                fancyIntensity: d.fancyIntensity,
                uppercase: true,
              ),
            ),
          ),
          ProductSpec('Clarity', _grade(d.clarity)),
          ProductSpec('Cut - Sym - Pol', _cutSymPol(d)),
          ProductSpec('BGM', bgm),
          ProductSpec('Floro', _dash(d.fluorescence)),
          lastRow,
        ],
      ),
      ProductSpecTab(
        title: 'Advance',
        rows: [
          ProductSpec('Measurement', measurement ?? _emDash),
          ProductSpec('Ratio', _dash(d.ratio)),
          ProductSpec('Table Percent', _percent(d.tablePercent)),
          ProductSpec('Depth Percent', _percent(d.depthPercent)),
          const ProductSpec('Crown', _emDash),
          const ProductSpec('Pavilion', _emDash),
          ProductSpec('Girdle', _dash(d.girdleCondition)),
          ProductSpec('Culet Condition', _dash(d.culetCondition)),
          ProductSpec('Treatment', _dash(d.enhancement)),
        ],
      ),
      ProductSpecTab(
        title: 'Comment',
        isComment: true,
        commentBody: comment ?? 'No Comment Available',
      ),
    ],
  );
}

String? _measurementRange(String? min, String? max) {
  final a = DiamondDisplay.optional(min);
  final b = DiamondDisplay.optional(max);
  if (a != null && b != null) {
    if (a.toLowerCase() == b.toLowerCase()) return a;
    return '$a × $b';
  }
  return a ?? b;
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
      tone: ProductStockTone.unavailable,
      detail: 'This stone is currently on hold with another buyer.',
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
