import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../application/melee_qty_draft_provider.dart';
import '../../domain/models/product_detail.dart';

/// Spec tabs for natural and lab-grown diamonds. Melee qty when separable.
class ProductDetailNaturalSpecs extends StatefulWidget {
  const ProductDetailNaturalSpecs({
    required this.specs,
    required this.productId,
    required this.lotPrice,
    required this.currencySymbol,
    super.key,
  });

  final ProductTabbedSpecs specs;
  final String productId;
  final double lotPrice;
  final String currencySymbol;

  @override
  State<ProductDetailNaturalSpecs> createState() =>
      _ProductDetailNaturalSpecsState();
}

class _ProductDetailNaturalSpecsState extends State<ProductDetailNaturalSpecs> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = widget.specs.tabs;
    if (tabs.isEmpty) return const SizedBox.shrink();
    final index = _tabIndex.clamp(0, tabs.length - 1);
    final tab = tabs[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: _TabLabel(
                  title: tabs[i].title,
                  selected: i == index,
                  onTap: () => setState(() => _tabIndex = i),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        if (tab.isComment)
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppSpacing.r20),
              border: Border.all(color: AppColors.border(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s32,
              ),
              child: Text(
                tab.commentBody ?? 'No Comment Available',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textMuted(context),
                  fontSize: 14,
                ),
              ),
            ),
          )
        else if (tab.hasSections)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tab.sections.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.s24),
                _SectionCard(section: tab.sections[i]),
              ],
            ],
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppSpacing.r20),
              border: Border.all(color: AppColors.border(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < tab.rows.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: AppColors.border(context)),
                  _Row(spec: tab.rows[i]),
                ],
              ],
            ),
          ),
        if (widget.specs.meleeQty != null) ...[
          const SizedBox(height: AppSpacing.s16),
          _MeleeQtyBar(
            productId: widget.productId,
            qty: widget.specs.meleeQty!,
            lotPrice: widget.lotPrice,
            currencySymbol: widget.currencySymbol,
          ),
        ],
      ],
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(
                color: selected
                    ? AppColors.textPrimary(context)
                    : AppColors.textMuted(context),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),
          ColoredBox(
            color: selected ? AppColors.bronze : AppColors.border(context),
            child: SizedBox(height: selected ? 2 : 1, width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final ProductSpecTabSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.s4,
            bottom: AppSpacing.s12,
          ),
          child: Text(
            _catalogText(context, section.title),
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(AppSpacing.r20),
            border: Border.all(color: AppColors.border(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < section.rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: AppColors.border(context)),
                _Row(spec: section.rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.spec});

  final ProductSpec spec;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              _catalogText(context, spec.label),
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            flex: 5,
            child: Text(
              spec.value,
              textAlign: TextAlign.right,
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _catalogText(BuildContext context, String value) {
  final key = catalogDisplayMessageKeys[value];
  return key == null ? value : context.tr(key);
}

class _MeleeQtyBar extends ConsumerStatefulWidget {
  const _MeleeQtyBar({
    required this.productId,
    required this.qty,
    required this.lotPrice,
    required this.currencySymbol,
  });

  final String productId;
  final ProductMeleeQty qty;
  final double lotPrice;
  final String currencySymbol;

  @override
  ConsumerState<_MeleeQtyBar> createState() => _MeleeQtyBarState();
}

class _MeleeQtyBarState extends ConsumerState<_MeleeQtyBar> {
  late final TextEditingController _controller;
  var _syncing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(meleeQtyDraftProvider(widget.productId).notifier)
          .ensureSeeded(widget.qty);
      _writeFieldFromDraft();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _writeFieldFromDraft() {
    final draft = ref.read(meleeQtyDraftProvider(widget.productId));
    if (draft == null) return;
    final text = draft.inCarat
        ? _formatCarat(draft.carat)
        : (draft.pieces == 0 ? '' : '${draft.pieces}');
    if (_controller.text == text) return;
    _syncing = true;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _syncing = false;
  }

  String _formatCarat(double value) {
    if (value <= 0) return '';
    final asFixed = value.toStringAsFixed(4);
    return asFixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _proportionalPriceLabel(MeleeQtyDraft? draft) {
    if (draft == null) return '';
    if (draft.pieces <= 0 && draft.carat <= 0) return '';
    final amount = draft.proportionalPrice(widget.lotPrice, widget.qty);
    if (amount <= 0) return '';
    return '${widget.currencySymbol}${formatCatalogPrice(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final qty = widget.qty;
    ref.listen(meleeQtyDraftProvider(widget.productId), (_, __) {
      _writeFieldFromDraft();
    });
    final draft = ref.watch(meleeQtyDraftProvider(widget.productId));
    final inCarat = draft?.inCarat ?? false;
    final pcs = qty.totalPcs;
    final carat = qty.totalCarat;
    final ofLabel = inCarat
        ? (carat == null ? '' : 'of ${carat.toString()} ct')
        : (pcs == null ? '' : 'of $pcs pcs');
    final priceLabel = _proportionalPriceLabel(draft);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r20),
        border: Border.all(color: AppColors.border(context)),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _UnitChip(
                  label: context.tr(CatalogL10n.pieces),
                  selected: !inCarat,
                  onTap: () {
                    ref
                        .read(meleeQtyDraftProvider(widget.productId).notifier)
                        .setUnit(inCarat: false, qty: qty);
                    _writeFieldFromDraft();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: _UnitChip(
                  label: context.tr(CatalogL10n.carat),
                  selected: inCarat,
                  onTap: () {
                    ref
                        .read(meleeQtyDraftProvider(widget.productId).notifier)
                        .setUnit(inCarat: true, qty: qty);
                    _writeFieldFromDraft();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      inCarat ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
                    ),
                  ],
                  onChanged: (raw) {
                    if (_syncing) return;
                    final notifier = ref.read(
                      meleeQtyDraftProvider(widget.productId).notifier,
                    );
                    if (inCarat) {
                      notifier.setFromCarat(double.tryParse(raw) ?? 0, qty);
                    } else {
                      notifier.setFromPieces(int.tryParse(raw) ?? 0, qty);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: inCarat ? 'Qty ct' : 'Qty pcs',
                    filled: true,
                    fillColor: AppColors.surface(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                ),
              ),
              if (ofLabel.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.s12),
                Text(
                  ofLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          if (priceLabel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              priceLabel,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.bronze : AppColors.surface(context),
      borderRadius: BorderRadius.circular(AppSpacing.r12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.label.copyWith(
              color: selected
                  ? AppColors.warmWhite
                  : AppColors.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
