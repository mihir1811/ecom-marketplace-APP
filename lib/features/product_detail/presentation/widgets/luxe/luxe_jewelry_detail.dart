import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../../../core/utils/format_catalog_price.dart';
import '../../../../../core/widgets/filters/filter_chip.dart';
import '../../../../../core/widgets/luxe/luxe_dropdown_field.dart';
import '../../../../../core/widgets/luxe/luxe_metal_swatch.dart';
import '../../../../../core/widgets/luxe/luxe_quantity_stepper.dart';
import '../../../application/jewelry_config_draft_provider.dart';
import '../../../domain/models/jewelry_unit_pricing.dart';
import '../../../domain/models/product_detail.dart';
import '../../../domain/models/product_jewelry_detail.dart';
import '../../../domain/models/product_price_labels.dart';
import 'luxe_detail_parts.dart';
import 'luxe_purchase_bar.dart';

/// Unit pricing for the chosen variant, or the listing's own when nothing
/// has been chosen yet.
JewelryUnitPricing _pricing(ProductJewelryDetail j, JewelryConfigDraft? d) =>
    JewelryUnitPricing.from(
      metalPrice: d?.metalPrice ?? j.metalPrice,
      stonePrice: d?.stonePrice ?? j.stonePrice,
      makingCharge: d?.makingCharge ?? j.makingCharge,
      discountAmount: d?.discountAmount ?? j.discountAmount,
      totalPrice: d?.price ?? j.price,
    );

String _money(String symbol, double v) => '$symbol${formatGroupedWhole(v)}';

String _fmt(double v) => v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : v
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');

String _dash(String? v) => v == null || v.trim().isEmpty ? '—' : v.trim();

/// Price labels for the chosen variant. With [quantity] the amounts are the
/// line total (purchase bar); otherwise per piece (price card).
ProductPriceLabels jewelryPriceLabels(
  BuildContext context,
  ProductDetail detail,
  JewelryConfigDraft? draft, {
  int quantity = 1,
}) {
  final j = detail.jewelryDetail!;
  final symbol = j.currencySymbol;
  if (detail.price.isOnRequest) {
    return ProductPriceLabels(
      sale: context.tr(JewelryFlowL10n.priceOnRequest),
      list: null,
      discountPercent: null,
      unit: null,
      currencySymbol: symbol,
    );
  }
  final p = _pricing(j, draft);
  return ProductPriceLabels(
    sale: _money(symbol, p.netPrice * quantity),
    list: p.hasDiscount ? _money(symbol, p.listPrice * quantity) : null,
    discountPercent: p.hasDiscount ? p.discountPercent : null,
    unit: null,
    saveAmount: p.hasDiscount ? p.discount * quantity : null,
    currencySymbol: symbol,
  );
}

/// Live price card plus the "Make it yours" configurator (purity, size,
/// stone weight, quantity). Seeds the variant draft on first build; every
/// choice re-prices the card, the glance tiles, the record and the
/// purchase bar.
class LuxeJewelryPurchasePanel extends ConsumerStatefulWidget {
  const LuxeJewelryPurchasePanel({required this.detail, super.key});

  final ProductDetail detail;

  @override
  ConsumerState<LuxeJewelryPurchasePanel> createState() =>
      _LuxeJewelryPurchasePanelState();
}

class _LuxeJewelryPurchasePanelState
    extends ConsumerState<LuxeJewelryPurchasePanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(jewelryConfigDraftProvider(widget.detail.id).notifier)
          .ensureSeeded(widget.detail.jewelryDetail!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final detail = widget.detail;
    final j = detail.jewelryDetail!;
    final draft = ref.watch(jewelryConfigDraftProvider(detail.id));
    final n = ref.read(jewelryConfigDraftProvider(detail.id).notifier);
    final labels = jewelryPriceLabels(context, detail, draft);
    final sku = draft?.sku ?? j.styleNo;
    final purity =
        draft?.purity ?? (j.metalPurity.trim().isEmpty ? null : j.metalPurity);
    final qty = draft?.quantity ?? 1;
    final hasOptions =
        j.purityOptions.isNotEmpty ||
        j.sizeOptions.isNotEmpty ||
        j.stoneWeightOptions.isNotEmpty;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(), style: LuxeType.eyebrow(p.inkMuted)),
    );

    Widget options(
      List<String> values,
      String? selected,
      ValueChanged<String> onTap,
    ) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          FilterChipWidget(
            label: v,
            isSelected: v == selected,
            onTap: () => onTap(v),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuxePriceCard(
          labels: labels,
          footer: Text(
            [
              context.tr(JewelryFlowL10n.inclTaxes),
              if (sku.trim().isNotEmpty)
                context.tr(JewelryFlowL10n.sku, {'sku': sku}),
            ].join('  ·  '),
            style: LuxeType.label(p.inkMuted, size: 12),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(LuxeSpace.radius),
            border: Border.all(color: p.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasOptions) ...[
                Text(
                  context.tr(JewelryFlowL10n.configureTitle),
                  style: LuxeType.display(26, p.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(JewelryFlowL10n.configureIntro),
                  style: LuxeType.body(p.inkMuted, size: 13.5),
                ),
              ],
              if (j.purityOptions.isNotEmpty) ...[
                const SizedBox(height: 20),
                label(context.tr(CatalogL10n.purity)),
                options(j.purityOptions, purity, (v) => n.selectPurity(v, j)),
              ],
              if (j.sizeOptions.isNotEmpty) ...[
                const SizedBox(height: 20),
                label(context.tr(JewelryFlowL10n.size)),
                // Long size runs read better as a menu than a chip wall.
                if (j.sizeOptions.length > 8)
                  LuxeDropdownField<String>(
                    value: j.sizeOptions.contains(draft?.size)
                        ? draft?.size
                        : null,
                    hint: context.tr(JewelryFlowL10n.size),
                    items: [
                      for (final s in j.sizeOptions)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) => n.selectSize(v, j),
                  )
                else
                  options(j.sizeOptions, draft?.size, (v) => n.selectSize(v, j)),
              ],
              if (j.stoneWeightOptions.isNotEmpty) ...[
                const SizedBox(height: 20),
                label(context.tr(CatalogL10n.stoneWeight)),
                options(
                  j.stoneWeightOptions,
                  draft?.stoneWeightLabel,
                  (v) => n.selectStoneWeight(v, j),
                ),
              ],
              if (hasOptions) ...[
                const SizedBox(height: 20),
                Divider(height: 1, color: p.hairline),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(CatalogL10n.quantity),
                          style: LuxeType.label(p.ink, size: 14),
                        ),
                        AnimatedSize(
                          duration: LuxeMotion.medium,
                          curve: LuxeMotion.settle,
                          alignment: Alignment.topLeft,
                          child: qty > 1 && !detail.price.isOnRequest
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    jewelryPriceLabels(
                                      context,
                                      detail,
                                      draft,
                                      quantity: qty,
                                    ).sale,
                                    style: LuxeType.figure(
                                      p.accent,
                                      size: 13,
                                    ),
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ],
                    ),
                  ),
                  LuxeQuantityStepper(
                    value: qty,
                    onChanged: n.setQuantity,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Four quiet tiles for the chosen variant: metal, purity, stones, weight.
class LuxeJewelryGlance extends ConsumerWidget {
  const LuxeJewelryGlance({required this.detail, super.key});

  final ProductDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final j = detail.jewelryDetail!;
    final d = ref.watch(jewelryConfigDraftProvider(detail.id));
    final metalColor = d?.metalColor ?? j.metalColor;
    final metalType = d?.metalType ?? j.metalType;
    final purity = d?.purity ?? j.metalPurity;
    final stoneCt = d?.stoneWeightCt ?? j.stoneWeightCt;
    final weight = d?.totalWeightG ?? j.totalWeightG ?? 0;
    final metalWeight = d?.metalWeightG ?? j.metalWeightG;
    final grams = weight > 0 ? weight : metalWeight;
    final highlights = [
      if (metalColor.trim().isNotEmpty || metalType.trim().isNotEmpty)
        ProductHighlight(
          context.tr(CatalogL10n.metal),
          metalColor.trim().isNotEmpty ? metalColor : metalType,
        ),
      if (purity.trim().isNotEmpty)
        ProductHighlight(context.tr(CatalogL10n.purity), purity),
      if (stoneCt > 0)
        ProductHighlight(context.tr(CatalogL10n.stones), '${_fmt(stoneCt)}ct'),
      if (grams > 0)
        ProductHighlight(context.tr(CatalogL10n.weight), '${_fmt(grams)}g'),
    ];
    if (highlights.isEmpty) return const SizedBox.shrink();
    return Stack(
      children: [
        LuxeGlance(highlights: highlights),
        if (metalColor.trim().isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            child: LuxeMetalSwatch(label: metalColor, size: 16),
          ),
      ],
    );
  }
}

/// About / Specifications / Care for the chosen variant.
class LuxeJewelryRecord extends ConsumerWidget {
  const LuxeJewelryRecord({required this.detail, super.key});

  final ProductDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final j = detail.jewelryDetail!;
    final d = ref.watch(jewelryConfigDraftProvider(detail.id));
    return LuxeTabbedPanel(
      title: context.tr(JewelryFlowL10n.aboutPiece),
      tabs: [
        context.tr(CatalogL10n.details),
        context.tr(CatalogL10n.specifications),
        context.tr(JewelryFlowL10n.tabCare),
      ],
      bodyOf: (context, i) => switch (i) {
        0 => _Details(jewelry: j),
        1 => _Specs(
          jewelry: j,
          draft: d,
          priceOnRequest: detail.price.isOnRequest,
        ),
        _ => const _Care(),
      },
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.jewelry});

  final ProductJewelryDetail jewelry;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final j = jewelry;
    final info = [
      if (j.materialLabel != null)
        LuxeSpecLine(context.tr(JewelryFlowL10n.material), j.materialLabel!),
      if (j.category.trim().isNotEmpty)
        LuxeSpecLine(context.tr(JewelryFlowL10n.category), j.category),
      if (j.gender.trim().isNotEmpty)
        LuxeSpecLine(context.tr(CatalogL10n.gender), j.gender),
      if (j.occasion.trim().isNotEmpty)
        LuxeSpecLine(context.tr(CatalogL10n.occasion), j.occasion),
      if ((j.style ?? '').trim().isNotEmpty)
        LuxeSpecLine(context.tr(JewelryFlowL10n.style), j.style!),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Text(j.description, style: LuxeType.body(p.inkMuted, size: 14.5)),
        if (info.isNotEmpty)
          LuxeSpecGroup(
            title: context.tr(JewelryFlowL10n.productInfo),
            lines: info,
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Specs extends StatelessWidget {
  const _Specs({
    required this.jewelry,
    required this.draft,
    required this.priceOnRequest,
  });

  final ProductJewelryDetail jewelry;
  final JewelryConfigDraft? draft;
  final bool priceOnRequest;

  String _sizeLabel(BuildContext context) {
    final j = jewelry;
    if ((j.braceletSize ?? '').isNotEmpty) {
      return context.tr(CatalogL10n.braceletSize);
    }
    if ((j.ringSize ?? '').isNotEmpty) return context.tr(CatalogL10n.ringSize);
    if ((j.chainLength ?? '').isNotEmpty) {
      return context.tr(CatalogL10n.chainLength);
    }
    return context.tr(JewelryFlowL10n.size);
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final j = jewelry;
    final d = draft;
    final symbol = j.currencySymbol;
    final pricing = _pricing(j, d);
    final metalW = d?.metalWeightG ?? j.metalWeightG;
    final totalW = d?.totalWeightG ?? j.totalWeightG;
    String grams(double v) => v > 0 ? '${_fmt(v)}g' : '—';
    final size =
        d?.braceletSize ?? d?.ringSize ?? d?.chainLength ?? j.sizeLabel;
    final stones = (d?.stones.isNotEmpty ?? false) ? d!.stones : j.stones;

    final price = <LuxeSpecLine>[
      if (priceOnRequest)
        LuxeSpecLine(
          context.tr(JewelryFlowL10n.grandTotal),
          context.tr(JewelryFlowL10n.priceOnRequest),
          emphasis: true,
        )
      else ...[
        if (pricing.metal > 0)
          LuxeSpecLine(
            context.tr(CatalogL10n.metal),
            _money(symbol, pricing.metal),
          ),
        if (pricing.stone > 0)
          LuxeSpecLine(
            context.tr(JewelryFlowL10n.diamond),
            _money(symbol, pricing.stone),
          ),
        if (pricing.making > 0)
          LuxeSpecLine(
            context.tr(JewelryFlowL10n.makingCharges),
            _money(symbol, pricing.making),
          ),
        if (pricing.hasDiscount)
          LuxeSpecLine(
            context.tr(JewelryFlowL10n.discount),
            '−${_money(symbol, pricing.discount)}',
            tone: p.positive,
          ),
        LuxeSpecLine(
          context.tr(JewelryFlowL10n.grandTotal),
          _money(symbol, pricing.netPrice),
          emphasis: true,
        ),
        LuxeSpecLine(
          context.tr(JewelryFlowL10n.mrp),
          context.tr(JewelryFlowL10n.inclTaxes),
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuxeSpecGroup(
          title: context.tr(JewelryFlowL10n.productSummary),
          lines: [
            LuxeSpecLine(
              context.tr(JewelryFlowL10n.styleNo),
              _dash(d?.sku ?? j.styleNo),
            ),
            LuxeSpecLine(context.tr(CatalogL10n.metalWeight), grams(metalW)),
            LuxeSpecLine(
              context.tr(JewelryFlowL10n.totalWeight),
              grams(totalW ?? 0),
            ),
          ],
        ),
        LuxeSpecGroup(
          title: context.tr(JewelryFlowL10n.priceBreakup),
          lines: price,
        ),
        LuxeSpecGroup(
          title: context.tr(JewelryFlowL10n.metalDetails),
          lines: [
            LuxeSpecLine(
              context.tr(CatalogL10n.metalType),
              _dash(d?.metalType ?? j.metalType),
            ),
            LuxeSpecLine(
              context.tr(CatalogL10n.metalColor),
              _dash(d?.metalColor ?? j.metalColor),
            ),
            LuxeSpecLine(
              context.tr(CatalogL10n.metalPurity),
              _dash(d?.purity ?? j.metalPurity),
            ),
            LuxeSpecLine(
              context.tr(CatalogL10n.metalFinish),
              _dash(d?.metalFinish ?? j.metalFinish),
            ),
            LuxeSpecLine(context.tr(CatalogL10n.metalWeight), grams(metalW)),
            LuxeSpecLine(_sizeLabel(context), _dash(size)),
            LuxeSpecLine(
              context.tr(JewelryFlowL10n.totalWeight),
              grams(totalW ?? 0),
            ),
          ],
        ),
        for (var i = 0; i < stones.length; i++)
          LuxeSpecGroup(
            title: stones.length == 1
                ? context.tr(JewelryFlowL10n.diamondDetails)
                : context.tr(JewelryFlowL10n.stoneNumber, {'n': i + 1}),
            lines: [
              LuxeSpecLine(
                context.tr(JewelryFlowL10n.centerType),
                _dash(stones[i].type?.toUpperCase()),
              ),
              LuxeSpecLine(
                context.tr(CatalogL10n.shape),
                _dash(stones[i].shape),
              ),
              LuxeSpecLine(
                context.tr(CatalogL10n.carat),
                (stones[i].weightCt ?? 0) > 0
                    ? '${_fmt(stones[i].weightCt!)}ct'
                    : '—',
              ),
              LuxeSpecLine(
                context.tr(CatalogL10n.color),
                _dash(stones[i].color),
              ),
              LuxeSpecLine(
                context.tr(CatalogL10n.clarity),
                _dash(stones[i].clarity),
              ),
              LuxeSpecLine(
                context.tr(CatalogL10n.pieces),
                (stones[i].pieces ?? 0) > 0 ? '${stones[i].pieces}' : '—',
              ),
              LuxeSpecLine(
                context.tr(JewelryFlowL10n.setting),
                _dash(stones[i].setting),
              ),
            ],
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Care extends StatelessWidget {
  const _Care();

  static const _tips = [
    JewelryFlowL10n.careStore,
    JewelryFlowL10n.careClean,
    JewelryFlowL10n.careAvoid,
    JewelryFlowL10n.careRemove,
  ];

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(JewelryFlowL10n.careTitle).toUpperCase(),
            style: LuxeType.eyebrow(p.accent),
          ),
          const SizedBox(height: 14),
          for (final tip in _tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 12, top: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.positive.withValues(alpha: 0.1),
                    ),
                    child: Icon(Icons.check_rounded, size: 14, color: p.positive),
                  ),
                  Expanded(
                    child: Text(
                      context.tr(tip),
                      style: LuxeType.body(p.inkMuted, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            context.tr(JewelryFlowL10n.serviceTitle).toUpperCase(),
            style: LuxeType.eyebrow(p.accent),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(JewelryFlowL10n.serviceBody),
            style: LuxeType.body(p.inkMuted, size: 14),
          ),
        ],
      ),
    );
  }
}

/// Purchase bar priced for the chosen variant and quantity.
class LuxeJewelryPurchaseBar extends ConsumerWidget {
  const LuxeJewelryPurchaseBar({required this.detail, super.key});

  final ProductDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(jewelryConfigDraftProvider(detail.id));
    final qty = draft?.quantity ?? 1;
    final unit = jewelryPriceLabels(context, detail, draft);
    return LuxePurchaseBar(
      detail: detail,
      priceLabels: jewelryPriceLabels(context, detail, draft, quantity: qty),
      caption: qty > 1 && !detail.price.isOnRequest
          ? context.tr(JewelryFlowL10n.lineTotal, {
              'count': qty,
              'price': unit.sale,
            })
          : null,
    );
  }
}
