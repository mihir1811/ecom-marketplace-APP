import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/models/seller_product.dart';
import '../../domain/models/seller_product_column.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_theme.dart';

/// Gallery of inventory cards with selection, quick view, edit and delete.
class SellerProductCardsView extends StatelessWidget {
  const SellerProductCardsView({
    required this.products,
    required this.selectedIds,
    required this.onToggleSelection,
    this.onEdit,
    this.onDelete,
    this.onQuickView,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final List<SellerProduct> products;
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggleSelection;
  final ValueChanged<SellerProduct>? onEdit;
  final ValueChanged<SellerProduct>? onDelete;
  final ValueChanged<SellerProduct>? onQuickView;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1280
            ? 5
            : width >= 1000
            ? 4
            : width >= 680
            ? 3
            : 2;
        return GridView.builder(
          padding: padding,
          physics: const AlwaysScrollableScrollPhysics(),
          addAutomaticKeepAlives: false,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AtelierSpace.s16,
            crossAxisSpacing: AtelierSpace.s16,
            mainAxisExtent: width < 400 ? 284 : 300,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return RepaintBoundary(
              child: Reveal(
                key: ValueKey(p.id),
                // Only the first screenful staggers; later cells appear at once.
                index: index < 12 ? index : 0,
                child: _ProductCard(
                  product: p,
                  selected: selectedIds.contains(p.id),
                  onSelected: (v) => onToggleSelection(p.id, v),
                  onOpen: () => (onQuickView ?? onEdit)?.call(p),
                  onEdit: onEdit == null ? null : () => onEdit!(p),
                  onDelete: onDelete == null ? null : () => onDelete!(p),
                  onQuickView: onQuickView == null
                      ? null
                      : () => onQuickView!(p),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

enum _CardAction { quickView, edit, delete }

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.selected,
    required this.onSelected,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
    this.onQuickView,
  });

  final SellerProduct product;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onQuickView;

  Future<void> _openMenu(BuildContext context) async {
    final action = await showAtelierOptions<_CardAction>(
      context: context,
      title: sellerProductTitle(product),
      subtitle: product.stockNumber,
      options: [
        AtelierOption(
          value: _CardAction.quickView,
          label: context.tr(RemainingL10n.quickView),
          icon: Icons.visibility_outlined,
        ),
        AtelierOption(
          value: _CardAction.edit,
          label: context.tr(RemainingL10n.editProduct),
          icon: Icons.edit_outlined,
        ),
        AtelierOption(
          value: _CardAction.delete,
          label: context.tr(RemainingL10n.deleteProduct),
          icon: Icons.delete_outline_rounded,
          destructive: true,
        ),
      ],
    );
    switch (action) {
      case _CardAction.quickView:
        onQuickView?.call();
      case _CardAction.edit:
        onEdit?.call();
      case _CardAction.delete:
        onDelete?.call();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final grades = sellerProductGradesLine(product);
    final meta = sellerProductMetaLine(context, product);

    return Pressable(
      onTap: onOpen,
      onLongPress: () => onSelected(!selected),
      semanticLabel: '${sellerProductTitle(product)}, ${product.stockNumber}',
      child: AnimatedContainer(
        duration: AtelierMotion.base,
        curve: AtelierMotion.emphasized,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.lg),
          border: Border.all(
            color: selected ? p.gold : p.hairline,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: p.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _ProductThumb(product: product)),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: AtelierIconButton(
                      icon: Icons.more_horiz_rounded,
                      tooltip: context.tr(RemainingL10n.actions),
                      size: 36,
                      filled: true,
                      onPressed: () => _openMenu(context),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    right: 10,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (product.isOnAuction)
                          AtelierPill(
                            label: context.tr(RemainingL10n.onAuction),
                            tone: AtelierTone.sapphire,
                            icon: Icons.gavel_rounded,
                            filled: true,
                            dense: true,
                          ),
                        if (product.isSold)
                          AtelierPill(
                            label: context.tr(RemainingL10n.sold),
                            tone: AtelierTone.ruby,
                            filled: true,
                            dense: true,
                          ),
                        if (product.isExpired)
                          AtelierPill(
                            label: context.tr(RemainingL10n.expired),
                            tone: AtelierTone.amber,
                            filled: true,
                            dense: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sellerProductTitle(product),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.display(p.ink, size: 20),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [?grades, ?meta].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.caption(p.muted, size: 11.5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sellerProductPrice(product.field('total_price')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.figure(p.ink, size: 15),
                        ),
                      ),
                      Text(
                        product.stockNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.caption(p.muted, size: 10.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product});

  final SellerProduct product;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final url = sellerProductImages(product).firstOrNull;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(colors: [p.raised, p.sunken], radius: 0.9),
      ),
      child: url != null
          ? Padding(
              padding: const EdgeInsets.all(10),
              child: AppNetworkImage(
                url: url,
                fit: BoxFit.contain,
                memCacheWidth: 400,
                error: const _MissingImage(),
              ),
            )
          : const _MissingImage(),
    );
  }
}

class _MissingImage extends StatelessWidget {
  const _MissingImage();

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Center(
      child: Icon(
        Icons.diamond_outlined,
        size: 38,
        color: p.gold.withValues(alpha: 0.45),
      ),
    );
  }
}

/// Opens a product summary sheet with every non-empty field.
Future<void> showSellerProductQuickView(
  BuildContext context, {
  required SellerProduct product,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) {
  return showAtelierSheet<void>(
    context: context,
    title: sellerProductTitle(product),
    subtitle: product.stockNumber,
    builder: (sheetContext) {
      final p = sheetContext.atelier;
      final images = sellerProductImages(product);
      final keyFields = <(String, String)>[
        for (final id in const [
          'shape',
          'carat_weight',
          'color',
          'clarity',
          'cut',
          'polish',
          'symmetry',
          'measurement',
          'ratio',
          'price_per_carat',
          'discount',
          'rap',
        ])
          if (_present(product.field(id))) (_labelFor(id), product.field(id)!),
      ];
      final otherFields = <(String, String)>[
        for (final col in kSellerProductColumns)
          if (col.id != 'selection' &&
              col.id != 'actions' &&
              !col.id.startsWith('image') &&
              !keyFields.any((k) => k.$1 == col.label) &&
              _present(product.field(col.id)))
            (col.label, product.field(col.id)!),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AtelierRadius.lg),
            child: Container(
              height: 220,
              color: p.sunken,
              child: images.isEmpty
                  ? const _MissingImage()
                  : PageView(
                      children: [
                        for (final url in images)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: AppNetworkImage(
                              url: url,
                              fit: BoxFit.contain,
                              error: const _MissingImage(),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          if (images.length > 1) ...[
            const SizedBox(height: 8),
            Text(
              '${images.length} images · swipe to browse',
              textAlign: TextAlign.center,
              style: AtelierType.caption(p.muted, size: 11),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL PRICE', style: AtelierType.overline(p.muted)),
                    const SizedBox(height: 4),
                    Text(
                      sellerProductPrice(product.field('total_price')),
                      style: AtelierType.display(p.ink, size: 32),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  AtelierPill(
                    label: product.isNatural
                        ? sheetContext.tr(RemainingL10n.naturalDiamond)
                        : sheetContext.tr(RemainingL10n.meleeDiamond),
                    tone: AtelierTone.gold,
                    dense: true,
                  ),
                  AtelierPill(
                    label: product.isExpired
                        ? sheetContext.tr(RemainingL10n.expired)
                        : sheetContext.tr(RemainingL10n.active),
                    tone: product.isExpired
                        ? AtelierTone.amber
                        : AtelierTone.emerald,
                    dense: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (keyFields.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 480 ? 3 : 2;
                final w = (constraints.maxWidth - 12 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    for (final (label, value) in keyFields)
                      SizedBox(
                        width: w,
                        child: AtelierKeyValue(label: label, value: value),
                      ),
                  ],
                );
              },
            ),
          if (otherFields.isNotEmpty) ...[
            const SizedBox(height: 18),
            Theme(
              data: Theme.of(
                sheetContext,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                iconColor: p.gold,
                collapsedIconColor: p.muted,
                title: Text(
                  'All details',
                  style: AtelierType.title(p.ink, size: 14),
                ),
                children: [
                  for (final (label, value) in otherFields)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 140,
                            child: Text(
                              label,
                              style: AtelierType.caption(p.muted),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              value,
                              style: AtelierType.label(p.ink, size: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              if (onDelete != null)
                Expanded(
                  child: AtelierButton(
                    label: sheetContext.tr(RemainingL10n.delete),
                    icon: Icons.delete_outline_rounded,
                    variant: AtelierButtonVariant.danger,
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onDelete();
                    },
                  ),
                ),
              if (onDelete != null && onEdit != null) const SizedBox(width: 10),
              if (onEdit != null)
                Expanded(
                  child: AtelierButton(
                    label: sheetContext.tr(RemainingL10n.editProduct),
                    icon: Icons.edit_outlined,
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onEdit();
                    },
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );
}

String _labelFor(String id) =>
    kSellerProductColumns.where((c) => c.id == id).firstOrNull?.label ?? id;

bool _present(String? value) => sellerOptionalText(value) != null;

/// "1.02ct Round" style headline for a product.
String sellerProductTitle(SellerProduct product) {
  final carat = _caratLabel(product.field('carat_weight'));
  final shape = sellerOptionalText(product.field('shape'));
  if (carat != null && shape != null) return '$carat $shape';
  if (carat != null) return carat;
  if (shape != null) return shape;
  return product.stockNumber;
}

String? sellerProductGradesLine(SellerProduct product) {
  final parts = <String>[
    ?sellerOptionalText(product.field('color')),
    ?sellerOptionalText(product.field('clarity')),
    ?sellerOptionalText(product.field('cut')),
  ];
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

String? sellerProductMetaLine(BuildContext context, SellerProduct product) {
  final parts = <String>[];
  final ppc = _parseAmount(product.field('price_per_carat'));
  if (ppc != null && ppc > 0) {
    parts.add('${AppCurrency.format(formatCatalogPrice(ppc))}/ct');
  }
  final dims = sellerOptionalText(product.field('measurement'));
  if (dims != null) parts.add(dims);
  if (parts.isEmpty) {
    parts.add(
      product.isNatural
          ? context.tr(RemainingL10n.naturalDiamond)
          : context.tr(RemainingL10n.meleeDiamond),
    );
  }
  return parts.join(' · ');
}

String sellerProductPrice(String? raw) {
  final amount = _parseAmount(raw);
  if (amount == null) return '—';
  return AppCurrency.format(formatCatalogPrice(amount));
}

String? _caratLabel(String? raw) {
  final text = sellerOptionalText(raw);
  if (text == null) return null;
  if (text.toLowerCase().endsWith('ct')) return text;
  final amount = _parseAmount(text);
  if (amount != null) return '${amount.toStringAsFixed(2)}ct';
  return '${text}ct';
}

/// Every http(s) image URL on the product, in column order.
List<String> sellerProductImages(SellerProduct product) {
  const keys = ['image1', 'image2', 'image3', 'image4', 'image5', 'image6'];
  return [
    for (final key in keys)
      if ((product.field(key)?.trim() ?? '').startsWith(RegExp('https?://')))
        product.field(key)!.trim(),
  ];
}

double? _parseAmount(String? raw) {
  if (raw == null) return null;
  return double.tryParse(raw.trim().replaceAll(',', ''));
}

String? sellerOptionalText(String? value) {
  if (value == null) return null;
  final t = value.trim();
  if (t.isEmpty ||
      t == '-' ||
      t == '—' ||
      t == '–' ||
      t.toLowerCase() == 'n/a' ||
      t == 'placeholder') {
    return null;
  }
  return t;
}
