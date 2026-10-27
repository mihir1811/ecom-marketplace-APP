import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/auth/auth_providers.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../../../core/utils/format_catalog_price.dart';
import '../../../../../core/widgets/filters/filter_chip.dart';
import '../../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../../core/widgets/luxe/luxe_dropdown_field.dart';
import '../../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../../core/widgets/luxe/luxe_metal_swatch.dart';
import '../../../../../core/widgets/luxe/luxe_quantity_stepper.dart';
import '../../../../jewelry_checkout/application/jewelry_bag_provider.dart';
import '../../../../jewelry_checkout/domain/models/bag_line.dart';
import '../../../application/jewelry_config_draft_provider.dart';
import '../../../domain/models/product_detail.dart';
import '../../../domain/models/product_jewelry_detail.dart';
import '../../../domain/models/product_price_labels.dart';
import 'luxe_detail_parts.dart';

String _money(String symbol, double v) => '$symbol${formatGroupedWhole(v)}';

String _fmt(double v) => v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : v
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');

String _dash(String? v) => v == null || v.trim().isEmpty ? '—' : v.trim();

/// The SKU the buyer's choices point at (null = unavailable combination).
ProductJewelrySku? _selectedSku(
  ProductJewelryDetail j,
  JewelryConfigDraft? d,
) => d == null ? null : j.skuFor(d.selected);

/// Price labels for the chosen SKU. With [quantity] the amount is the line
/// total (purchase bar); otherwise per piece (price card). Before a SKU is
/// chosen a price range reads "from ₹…".
ProductPriceLabels jewelryPriceLabels(
  BuildContext context,
  ProductDetail detail,
  JewelryConfigDraft? draft, {
  int quantity = 1,
}) {
  final j = detail.jewelryDetail!;
  final symbol = j.currencySymbol;
  final sku = _selectedSku(j, draft);
  final amount = (sku?.price ?? j.price) * quantity;
  final from = sku == null && j.hasPriceRange;
  return ProductPriceLabels(
    sale: from
        ? '${context.tr(JewelryMarketL10n.from)} ${_money(symbol, amount)}'
        : _money(symbol, amount),
    list: null,
    discountPercent: null,
    unit: null,
    currencySymbol: symbol,
  );
}

/// Live price card plus the "Make it yours" configurator: one selector per
/// variation (options with no purchasable SKU are greyed), personalisation,
/// custom text and quantity. Seeds the choices on first build and again
/// when the full record replaces the card.
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
    _seed();
  }

  @override
  void didUpdateWidget(LuxeJewelryPurchasePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.detail.jewelryDetail, widget.detail.jewelryDetail)) {
      _seed();
    }
  }

  void _seed() {
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
    final sku = _selectedSku(j, draft);
    final qty = draft?.quantity ?? 1;
    final maxQty = j.maxQuantityFor(sku);
    final selected = draft?.selected ?? const <String, String>{};
    final hasOptions = j.variations.isNotEmpty;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(), style: LuxeType.eyebrow(p.inkMuted)),
    );

    Widget options(ProductJewelryVariation v) {
      final chosen = selected[v.name];
      // Options no active SKU carries at all can't be chosen.
      bool exists(String o) =>
          j.activeSkus.any((s) => s.options[v.name] == o);
      if (v.options.length > 8) {
        return LuxeDropdownField<String>(
          value: v.options.contains(chosen) ? chosen : null,
          hint: v.name,
          items: [
            for (final o in v.options)
              DropdownMenuItem(
                value: o,
                enabled: exists(o),
                child: Text(
                  o,
                  style: TextStyle(
                    color: j.optionAvailable(v.name, o, selected)
                        ? null
                        : p.inkFaint,
                  ),
                ),
              ),
          ],
          onChanged: (o) {
            if (o != null) n.select(v.name, o, j);
          },
        );
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in v.options)
            IgnorePointer(
              ignoring: !exists(o),
              child: Opacity(
                opacity: o == chosen || j.optionAvailable(v.name, o, selected)
                    ? 1
                    : 0.42,
                child: FilterChipWidget(
                  label: o,
                  isSelected: o == chosen,
                  onTap: () => n.select(v.name, o, j),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuxePriceCard(
          labels: labels,
          footer: Text(
            [
              context.tr(JewelryFlowL10n.inclTaxes),
              if ((j.stockNumber ?? '').trim().isNotEmpty)
                context.tr(JewelryFlowL10n.sku, {'sku': j.stockNumber}),
            ].join('  ·  '),
            style: LuxeType.label(p.inkMuted, size: 12),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
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
                for (final v in j.variations) ...[
                  const SizedBox(height: 20),
                  label(v.name),
                  options(v),
                ],
                const SizedBox(height: 16),
              ],
              _StockNote(jewelry: j, sku: sku, hasDraft: draft != null),
              if (j.personalizationEnabled) ...[
                const SizedBox(height: 20),
                _TextOption(
                  label: context.tr(JewelryMarketL10n.personalisation),
                  hint:
                      j.personalizationInstructions ??
                      context.tr(JewelryMarketL10n.personalisationHint),
                  value:
                      draft?.customValues[JewelryConfigDraft
                          .personalisationKey] ??
                      '',
                  onChanged: (v) => n.setCustomValue(
                    JewelryConfigDraft.personalisationKey,
                    v,
                  ),
                ),
              ],
              for (final name in j.customOptions) ...[
                const SizedBox(height: 16),
                _TextOption(
                  label: name,
                  value: draft?.customValues[name] ?? '',
                  onChanged: (v) => n.setCustomValue(name, v),
                ),
              ],
              const SizedBox(height: 20),
              Divider(height: 1, color: p.hairline),
              const SizedBox(height: 16),
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
                          child: qty > 1 && sku != null
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    jewelryPriceLabels(
                                      context,
                                      detail,
                                      draft,
                                      quantity: qty,
                                    ).sale,
                                    style: LuxeType.figure(p.accent, size: 13),
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ],
                    ),
                  ),
                  LuxeQuantityStepper(
                    value: qty,
                    max: maxQty < 1 ? 1 : maxQty,
                    onChanged: (v) => n.setQuantity(v, max: maxQty),
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

/// "Only 2 left", "Made to order · ready in 7 days", "Sold out" or
/// "This combination isn't available".
class _StockNote extends StatelessWidget {
  const _StockNote({
    required this.jewelry,
    required this.sku,
    required this.hasDraft,
  });

  final ProductJewelryDetail jewelry;
  final ProductJewelrySku? sku;
  final bool hasDraft;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final j = jewelry;
    final (IconData icon, Color tone, String text) = switch (sku) {
      null when !hasDraft => (
        Icons.hourglass_empty_rounded,
        p.inkMuted,
        context.tr(DiamondFlowL10n.searching),
      ),
      null => (
        Icons.block_rounded,
        p.caution,
        context.tr(JewelryMarketL10n.comboUnavailable),
      ),
      _ when j.isMadeToOrder => (
        Icons.handyman_outlined,
        p.accent,
        context.tr(JewelryMarketL10n.madeToOrderNote, {
          'days': j.processingDays,
        }),
      ),
      ProductJewelrySku(stock: final left) when left <= 0 => (
        Icons.block_rounded,
        p.caution,
        context.tr(JewelryMarketL10n.soldOut),
      ),
      ProductJewelrySku(stock: final left) when left <= 3 => (
        Icons.local_fire_department_outlined,
        p.caution,
        context.tr(JewelryMarketL10n.onlyLeft, {'count': left}),
      ),
      _ => (
        Icons.check_circle_outline_rounded,
        p.positive,
        context.tr(JewelryMarketL10n.readyToShipNote, {
          'days': j.processingDays,
        }),
      ),
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: tone),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: LuxeType.label(tone, size: 13)),
        ),
      ],
    );
  }
}

/// Engraving box or a seller's custom text option.
class _TextOption extends StatefulWidget {
  const _TextOption({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_TextOption> createState() => _TextOptionState();
}

class _TextOptionState extends State<_TextOption> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            widget.label.toUpperCase(),
            style: LuxeType.eyebrow(p.inkMuted),
          ),
        ),
        TextField(
          controller: _controller,
          maxLength: 500,
          minLines: 1,
          maxLines: 3,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
          ),
        ),
      ],
    );
  }
}

/// Four quiet tiles: metal, main stone, carat weight and weight.
class LuxeJewelryGlance extends StatelessWidget {
  const LuxeJewelryGlance({required this.detail, super.key});

  final ProductDetail detail;

  @override
  Widget build(BuildContext context) {
    final j = detail.jewelryDetail!;
    final metal = [?j.metalPurity, ?j.metalType].join(' ');
    final stone = [?j.gemstoneOrigin, ?j.primaryGemstone].join(' ');
    final grams = j.grossWeightG ?? j.metalWeightG ?? 0;
    final highlights = [
      if (metal.trim().isNotEmpty)
        ProductHighlight(context.tr(CatalogL10n.metal), metal),
      if (stone.trim().isNotEmpty)
        ProductHighlight(context.tr(CatalogL10n.stones), stone),
      if ((j.totalCaratWeight ?? 0) > 0)
        ProductHighlight(
          context.tr(CatalogL10n.carat),
          '${_fmt(j.totalCaratWeight!)}ct',
        ),
      if ((j.primaryShape ?? '').isNotEmpty && grams <= 0)
        ProductHighlight(context.tr(CatalogL10n.shape), j.primaryShape!),
      if (grams > 0)
        ProductHighlight(context.tr(CatalogL10n.weight), '${_fmt(grams)}g'),
    ];
    if (highlights.isEmpty) return const SizedBox.shrink();
    return Stack(
      children: [
        LuxeGlance(highlights: highlights.take(4).toList()),
        if ((j.metalType ?? '').isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            child: LuxeMetalSwatch(
              label: j.metalType == 'Sterling Silver' ? 'Silver' : j.metalType!,
              size: 16,
            ),
          ),
      ],
    );
  }
}

/// About / Specifications / Shipping & returns / Care.
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
        context.tr(JewelryMarketL10n.tabShipping),
        context.tr(JewelryFlowL10n.tabCare),
      ],
      bodyOf: (context, i) => switch (i) {
        0 => _Details(jewelry: j),
        1 => _Specs(jewelry: j, draft: d),
        2 => _Shipping(jewelry: j),
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
    final description = j.description?.trim();
    final info = [
      if (j.category.trim().isNotEmpty)
        LuxeSpecLine(context.tr(JewelryFlowL10n.category), j.category),
      if ((j.subCategory ?? '').trim().isNotEmpty)
        LuxeSpecLine(context.tr(JewelryFlowL10n.style), j.subCategory!),
      if ((j.style ?? '').trim().isNotEmpty)
        LuxeSpecLine(context.tr(JewelryMarketL10n.design), j.style!),
      if ((j.occasion ?? '').trim().isNotEmpty)
        LuxeSpecLine(context.tr(CatalogL10n.occasion), j.occasion!),
      if ((j.stockNumber ?? '').trim().isNotEmpty)
        LuxeSpecLine(context.tr(JewelryFlowL10n.styleNo), j.stockNumber!),
      if (j.shop != null)
        LuxeSpecLine(context.tr(JewelryMarketL10n.soldBy), j.shop!.name),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        if (description != null && description.isNotEmpty)
          Text(description, style: LuxeType.body(p.inkMuted, size: 14.5))
        else if (!j.isFullRecord)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LuxeSkeleton(height: 13),
              SizedBox(height: 8),
              LuxeSkeleton(height: 13),
              SizedBox(height: 8),
              LuxeSkeleton(width: 180, height: 13),
            ],
          ),
        if (info.isNotEmpty)
          LuxeSpecGroup(
            title: context.tr(JewelryFlowL10n.productInfo),
            lines: info,
          ),
        if (j.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in j.tags.take(13))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: ShapeDecoration(
                    color: p.surfaceRaised,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(t, style: LuxeType.label(p.inkMuted, size: 12)),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Specs extends StatelessWidget {
  const _Specs({required this.jewelry, required this.draft});

  final ProductJewelryDetail jewelry;
  final JewelryConfigDraft? draft;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final j = jewelry;
    final symbol = j.currencySymbol;
    final sku = _selectedSku(j, draft);
    String grams(double? v) => (v ?? 0) > 0 ? '${_fmt(v!)}g' : '—';
    final breakdown = j.shop?.showPriceBreakdown == true ? sku?.breakdown : null;
    final parts = <(String, String)>[
      ('metal', context.tr(CatalogL10n.metal)),
      ('stone', context.tr(CatalogL10n.stones)),
      ('making', context.tr(JewelryFlowL10n.makingCharges)),
      ('extra', context.tr(JewelryMarketL10n.extraCharges)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sku != null && sku.options.isNotEmpty)
          LuxeSpecGroup(
            title: context.tr(JewelryMarketL10n.yourChoice),
            lines: [
              for (final e in sku.options.entries) LuxeSpecLine(e.key, e.value),
            ],
          ),
        if (breakdown != null)
          LuxeSpecGroup(
            title: context.tr(JewelryFlowL10n.priceBreakup),
            lines: [
              for (final (key, label) in parts)
                if ((breakdown[key] ?? 0) > 0)
                  LuxeSpecLine(label, _money(symbol, breakdown[key]!)),
              LuxeSpecLine(
                context.tr(JewelryFlowL10n.grandTotal),
                _money(symbol, sku!.price),
                emphasis: true,
              ),
            ],
          ),
        LuxeSpecGroup(
          title: context.tr(JewelryFlowL10n.metalDetails),
          lines: [
            LuxeSpecLine(context.tr(CatalogL10n.metalType), _dash(j.metalType)),
            LuxeSpecLine(
              context.tr(CatalogL10n.metalPurity),
              _dash(j.metalPurity),
            ),
            LuxeSpecLine(
              context.tr(CatalogL10n.metalWeight),
              grams(j.metalWeightG),
            ),
            LuxeSpecLine(
              context.tr(JewelryFlowL10n.totalWeight),
              grams(j.grossWeightG),
            ),
          ],
        ),
        if (j.stones.isEmpty && (j.primaryGemstone ?? '').isNotEmpty)
          LuxeSpecGroup(
            title: context.tr(JewelryMarketL10n.mainStone),
            lines: [
              LuxeSpecLine(
                context.tr(CatalogL10n.stoneCategory),
                _dash(j.primaryGemstone),
              ),
              LuxeSpecLine(
                context.tr(CatalogL10n.stoneType),
                _dash(j.gemstoneOrigin),
              ),
              LuxeSpecLine(context.tr(CatalogL10n.shape), _dash(j.primaryShape)),
              LuxeSpecLine(
                context.tr(CatalogL10n.carat),
                (j.totalCaratWeight ?? 0) > 0
                    ? '${_fmt(j.totalCaratWeight!)}ct'
                    : '—',
              ),
            ],
          ),
        for (var i = 0; i < j.stones.length; i++)
          LuxeSpecGroup(
            title: j.stones.length == 1
                ? context.tr(JewelryMarketL10n.mainStone)
                : context.tr(JewelryFlowL10n.stoneNumber, {'n': i + 1}),
            lines: [
              LuxeSpecLine(
                context.tr(CatalogL10n.stoneCategory),
                _dash(j.stones[i].type),
              ),
              LuxeSpecLine(
                context.tr(CatalogL10n.stoneType),
                _dash(j.stones[i].origin),
              ),
              LuxeSpecLine(context.tr(CatalogL10n.shape), _dash(j.stones[i].shape)),
              LuxeSpecLine(
                context.tr(CatalogL10n.carat),
                (j.stones[i].caratWeight ?? 0) > 0
                    ? '${_fmt(j.stones[i].caratWeight!)}ct'
                    : '—',
              ),
              LuxeSpecLine(
                context.tr(CatalogL10n.pieces),
                (j.stones[i].quantity ?? 0) > 0
                    ? '${j.stones[i].quantity}'
                    : '—',
              ),
              LuxeSpecLine(context.tr(CatalogL10n.color), _dash(j.stones[i].color)),
              LuxeSpecLine(
                context.tr(CatalogL10n.clarity),
                _dash(j.stones[i].clarity),
              ),
              LuxeSpecLine(context.tr(CatalogL10n.cut), _dash(j.stones[i].cut)),
              if ((j.stones[i].certificationLab ?? '').isNotEmpty)
                LuxeSpecLine(
                  context.tr(CatalogL10n.certification),
                  [
                    j.stones[i].certificationLab!,
                    ?j.stones[i].reportNumber,
                  ].join(' · '),
                  tone: p.positive,
                ),
            ],
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Shipping extends StatelessWidget {
  const _Shipping({required this.jewelry});

  final ProductJewelryDetail jewelry;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final j = jewelry;
    final policies = j.shop?.policies ?? const <String, String>{};
    final cancel = j.cancellationWindowHours;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuxeSpecGroup(
          title: context.tr(JewelryMarketL10n.delivery),
          lines: [
            LuxeSpecLine(
              context.tr(JewelryMarketL10n.availability),
              context.tr(
                j.isMadeToOrder
                    ? JewelryMarketL10n.madeToOrder
                    : JewelryMarketL10n.readyToShip,
              ),
            ),
            LuxeSpecLine(
              context.tr(JewelryMarketL10n.processingTime),
              context.tr(JewelryMarketL10n.days, {'days': j.processingDays}),
            ),
            LuxeSpecLine(
              context.tr(JewelryMarketL10n.shipping),
              context.tr(
                j.freeShipping
                    ? JewelryMarketL10n.freeShipping
                    : JewelryMarketL10n.shippingAtCheckout,
              ),
              tone: j.freeShipping ? p.positive : null,
            ),
            if ((j.shipsFromCountry ?? '').isNotEmpty)
              LuxeSpecLine(
                context.tr(JewelryMarketL10n.shipsFrom),
                j.shipsFromCountry == 'IN' ? 'India' : j.shipsFromCountry!,
              ),
          ],
        ),
        LuxeSpecGroup(
          title: context.tr(JewelryMarketL10n.returnsAndCancellation),
          lines: [
            LuxeSpecLine(
              context.tr(JewelryMarketL10n.returns),
              j.returnsAccepted
                  ? context.tr(JewelryMarketL10n.returnsWithin, {
                      'days': j.returnWindowDays ?? 14,
                    })
                  : context.tr(JewelryMarketL10n.returnsNotAccepted),
            ),
            LuxeSpecLine(
              context.tr(JewelryMarketL10n.cancellation),
              cancel > 0
                  ? context.tr(JewelryMarketL10n.cancelWithin, {
                      'hours': cancel,
                    })
                  : context.tr(JewelryMarketL10n.cancelNotAccepted),
            ),
          ],
        ),
        if (policies.isNotEmpty)
          LuxeSpecGroup(
            title: context.tr(JewelryMarketL10n.shopPolicies, {
              'shop': j.shop!.name,
            }),
            lines: [
              if (policies['processingTime'] case final v?)
                LuxeSpecLine(context.tr(JewelryMarketL10n.processingTime), v),
              if (policies['shipping'] case final v?)
                LuxeSpecLine(context.tr(JewelryMarketL10n.shipping), v),
              if (policies['returns'] case final v?)
                LuxeSpecLine(context.tr(JewelryMarketL10n.returns), v),
              if (policies['location'] case final v?)
                LuxeSpecLine(context.tr(JewelryMarketL10n.location), v),
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

/// Purchase bar priced for the chosen SKU and quantity. Adds to the
/// on-device jewellery bag (no sign-in needed until checkout).
class LuxeJewelryPurchaseBar extends ConsumerWidget {
  const LuxeJewelryPurchaseBar({required this.detail, super.key});

  final ProductDetail detail;

  void _add(BuildContext context, WidgetRef ref, BagLine line, int max) {
    final issue = ref
        .read(jewelryBagProvider.notifier)
        .add(line, maxQuantity: max);
    final message = switch (issue) {
      null => context.tr(JewelryMarketL10n.addedToBag),
      BagAddIssue.full => context.tr(JewelryMarketL10n.bagFull),
      BagAddIssue.maxQuantity => context.tr(JewelryMarketL10n.bagMaxQuantity),
    };
    showLuxeToast(
      context,
      message,
      tone: issue == null ? LuxeTone.success : LuxeTone.info,
      actionLabel: context.tr(JewelryMarketL10n.viewBag),
      onAction: () => context.push(AppRouteNames.jewelryBag),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final j = detail.jewelryDetail!;
    final draft = ref.watch(jewelryConfigDraftProvider(detail.id));
    final sku = _selectedSku(j, draft);
    final qty = draft?.quantity ?? 1;
    final custom = draft?.filledCustomValues ?? const <String, String>{};
    final key = sku == null ? null : BagLine.keyFor(sku.id, custom);
    final inBag = key != null && ref.watch(isInJewelryBagProvider(key));
    final auth = ref.watch(authProvider);
    final own = detail.isOwnedByCurrentAccount(
      userId: auth.user?.id,
      sellerId: auth.sellerId,
    );
    final soldOut = sku != null && sku.stock <= 0 && !j.isMadeToOrder;
    final max = j.maxQuantityFor(sku);

    final (String label, IconData? icon, VoidCallback? onPressed) = own
        ? (context.tr(DiamondFlowL10n.yourListing), null, null)
        : sku == null
        ? (context.tr(DiamondFlowL10n.unavailable), null, null)
        : soldOut
        ? (context.tr(JewelryMarketL10n.soldOut), null, null)
        : inBag
        ? (
            context.tr(JewelryMarketL10n.viewBag),
            Icons.shopping_bag_rounded,
            () => context.push(AppRouteNames.jewelryBag),
          )
        : (
            context.tr(JewelryMarketL10n.addToBag),
            Icons.add_rounded,
            () => _add(
              context,
              ref,
              BagLine(
                skuId: sku.id,
                quantity: qty,
                listingSlug: j.slug,
                title: detail.title,
                imageUrl: detail.media.firstNetworkUrl ?? j.coverImageUrl,
                shopName: j.shop?.name,
                options: sku.options,
                customValues: custom,
                unitPrice: sku.price,
              ),
              max,
            ),
          );

    final unit = jewelryPriceLabels(context, detail, draft);
    final total = jewelryPriceLabels(context, detail, draft, quantity: qty);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.hairline, width: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: LuxeMotion.medium,
                  switchInCurve: LuxeMotion.settle,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: FittedBox(
                    key: ValueKey(total.sale),
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      total.sale,
                      style: LuxeType.figure(
                        p.ink,
                        size: 18,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (qty > 1 && sku != null)
                  Text(
                    context.tr(JewelryFlowL10n.lineTotal, {
                      'count': qty,
                      'price': unit.sale,
                    }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(p.inkMuted, size: 11.5),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: LuxeButton(
              label: label,
              expand: true,
              icon: icon,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
