import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../application/jewelry_orders_provider.dart';
import '../../domain/models/marketplace_invoice.dart';
import '../jewelry_checkout_format.dart';
import '../jewelry_invoice_pdf.dart';

/// GemWorld's tax invoice for a paid jewellery order, drawn as a document
/// (seller, buyer, ship-to, lines with their GST split, tax summary, totals
/// and later refunds) and shared as a PDF.
class JewelryInvoiceScreen extends ConsumerStatefulWidget {
  const JewelryInvoiceScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<JewelryInvoiceScreen> createState() =>
      _JewelryInvoiceScreenState();
}

class _JewelryInvoiceScreenState extends ConsumerState<JewelryInvoiceScreen> {
  bool _sharing = false;

  Future<void> _share(MarketplaceInvoice invoice, Rect? origin) async {
    setState(() => _sharing = true);
    try {
      final bytes = await buildJewelryInvoicePdf(invoice);
      final name =
          'Invoice-${invoice.number.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '-')}'
          '.pdf';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
          fileNameOverrides: [name],
          subject: 'Tax invoice ${invoice.number}',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      if (mounted) {
        showLuxeToast(
          context,
          context.tr(JewelryMarketL10n.invoiceShareFailed),
          tone: LuxeTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _build));
  }

  Widget _build(BuildContext context) {
    final p = LuxePalette.of(context);
    final async = ref.watch(jewelryInvoiceProvider(widget.orderId));
    final invoice = async.valueOrNull;
    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(title: context.tr(JewelryMarketL10n.taxInvoice)),
      body: async.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            LuxeSkeleton(height: 140, radius: LuxeSpace.radius),
            SizedBox(height: 12),
            LuxeSkeleton(height: 260, radius: LuxeSpace.radius),
          ],
        ),
        error: (e, _) => LuxeStateView(
          icon: Icons.receipt_long_outlined,
          tone: LuxeTone.error,
          title: context.tr(JewelryMarketL10n.invoiceUnavailable),
          message: e is Failure ? e.message : '$e',
          actionLabel: context.tr(CatalogL10n.retry),
          onAction: () =>
              ref.invalidate(jewelryInvoiceProvider(widget.orderId)),
        ),
        data: (inv) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [_InvoiceDocument(invoice: inv)],
        ),
      ),
      bottomNavigationBar: invoice == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Builder(
                  builder: (buttonContext) => LuxeButton(
                    label: context.tr(JewelryMarketL10n.sharePdf),
                    expand: true,
                    icon: Icons.ios_share_rounded,
                    loading: _sharing,
                    onPressed: _sharing
                        ? null
                        : () {
                            final box =
                                buttonContext.findRenderObject() as RenderBox?;
                            _share(
                              invoice,
                              box == null
                                  ? null
                                  : box.localToGlobal(Offset.zero) & box.size,
                            );
                          },
                  ),
                ),
              ),
            ),
    );
  }
}

/// The invoice on a white sheet, like the printed copy.
class _InvoiceDocument extends StatelessWidget {
  const _InvoiceDocument({required this.invoice});

  final MarketplaceInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final inv = invoice;
    final i = inv.issuer;
    final caption = LuxeType.eyebrow(p.inkMuted);
    final body = LuxeType.body(p.ink, size: 13);
    final muted = LuxeType.body(p.inkMuted, size: 12.5);

    Widget block(String title, List<String?> lines) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: caption),
        const SizedBox(height: 4),
        for (final l in lines)
          if (l != null && l.trim().isNotEmpty) Text(l, style: body),
      ],
    );

    Widget sumRow(String label, double amount, {bool strong = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: strong ? LuxeType.label(p.ink, size: 15) : muted,
                ),
              ),
              Text(
                rupees(amount),
                style: LuxeType.figure(
                  p.ink,
                  size: strong ? 16 : 13.5,
                ).copyWith(fontWeight: strong ? FontWeight.w600 : null),
              ),
            ],
          ),
        );

    final supply = [
      inv.placeOfSupplyState,
      if (inv.placeOfSupplyCode != null) '(${inv.placeOfSupplyCode})',
    ].whereType<String>().join(' ');
    final supplyType = switch (inv.supplyType) {
      'INTRA_STATE' => context.tr(JewelryMarketL10n.supplyIntraState),
      'INTER_STATE' => context.tr(JewelryMarketL10n.supplyInterState),
      'EXPORT' => context.tr(JewelryMarketL10n.supplyExport),
      _ => null,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(JewelryMarketL10n.taxInvoice).toUpperCase(),
            style: caption,
          ),
          const SizedBox(height: 4),
          Text(inv.number, style: LuxeType.display(24, p.ink)),
          Text(
            context.tr(JewelryMarketL10n.invoiceMeta, {
              'date': dateTimeLabel(context, inv.issuedAt),
              'order': inv.orderNumber,
            }),
            style: muted,
          ),
          if (inv.paymentMethod != null || inv.paymentReference != null)
            Text(
              [
                inv.paymentMethod?.toUpperCase(),
                inv.paymentReference,
              ].whereType<String>().join(' · '),
              style: muted,
            ),
          Divider(color: p.hairline, height: 28),
          block(context.tr(JewelryMarketL10n.invoiceSoldBy), [
            i.tradeName ?? i.legalName,
            if (i.tradeName != null) i.legalName,
            ...i.addressLines,
            if (i.gstin != null) 'GSTIN ${i.gstin}',
            if (i.pan != null) 'PAN ${i.pan}',
          ]),
          const SizedBox(height: 14),
          block(context.tr(JewelryMarketL10n.invoiceBillTo), [
            inv.buyer.name,
            inv.buyer.email,
            inv.buyer.phone,
          ]),
          const SizedBox(height: 14),
          block(context.tr(JewelryMarketL10n.invoiceShipTo), [
            inv.shipTo.fullName,
            ...inv.shipTo.lines,
            inv.shipTo.phone,
          ]),
          if (supply.isNotEmpty) ...[
            const SizedBox(height: 14),
            block(context.tr(JewelryMarketL10n.invoicePlaceOfSupply), [
              supply,
              supplyType,
            ]),
          ],
          Divider(color: p.hairline, height: 28),
          for (final l in inv.lines) ...[
            _InvoiceLineTile(line: l, defaultHsn: i.defaultHsn),
            Divider(color: p.hairline, height: 20),
          ],
          if (inv.taxSummary.isNotEmpty) ...[
            Text(
              context.tr(JewelryMarketL10n.invoiceTaxSummary).toUpperCase(),
              style: caption,
            ),
            const SizedBox(height: 4),
            for (final t in inv.taxSummary)
              Text(
                context.tr(JewelryMarketL10n.invoiceTaxOn, {
                  'tax': t.display,
                  'base': rupees(t.taxableValue),
                  'amount': rupees(t.amount),
                }),
                style: body,
              ),
            const SizedBox(height: 12),
          ],
          sumRow(
            context.tr(JewelryMarketL10n.invoiceTaxable),
            inv.totals.taxableValue,
          ),
          sumRow(context.tr(JewelryMarketL10n.invoiceTax), inv.totals.taxTotal),
          sumRow(context.tr(JewelryMarketL10n.shipping), inv.totals.shipping),
          Divider(color: p.hairline, height: 16),
          sumRow(
            context.tr(JewelryMarketL10n.total),
            inv.totals.total,
            strong: true,
          ),
          if (inv.totals.inWords != null) ...[
            const SizedBox(height: 6),
            Text(inv.totals.inWords!, style: muted),
          ],
          if (inv.refunds.isNotEmpty) ...[
            Divider(color: p.hairline, height: 28),
            Text(
              context.tr(JewelryMarketL10n.refunded).toUpperCase(),
              style: caption,
            ),
            const SizedBox(height: 4),
            for (final r in inv.refunds)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(r.title, style: body)),
                    Text(
                      '−${rupees(r.amount)}',
                      style: LuxeType.figure(p.positive, size: 13.5),
                    ),
                  ],
                ),
              ),
          ],
          if (i.footerNote != null) ...[
            const SizedBox(height: 16),
            Text(i.footerNote!, style: LuxeType.body(p.inkFaint, size: 11.5)),
          ],
        ],
      ),
    );
  }
}

class _InvoiceLineTile extends StatelessWidget {
  const _InvoiceLineTile({required this.line, required this.defaultHsn});

  final InvoiceLine line;
  final String? defaultHsn;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final l = line;
    final muted = LuxeType.body(p.inkMuted, size: 12.5);
    final hsn = l.hsnCode ?? defaultHsn;
    return Opacity(
      opacity: l.cancelled ? 0.6 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(l.title, style: LuxeType.label(p.ink, size: 14)),
              ),
              const SizedBox(width: 8),
              Text(
                rupees(l.total),
                style: LuxeType.figure(
                  p.ink,
                  size: 14,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (l.maker != null) Text(l.maker!, style: muted),
          if (l.details != null) Text(l.details!, style: muted),
          Text(
            [
              '${l.quantity} × ${rupees(l.unitPrice)}',
              if (hsn != null) 'HSN $hsn',
            ].join(' · '),
            style: muted,
          ),
          for (final t in l.taxes)
            Text('${t.display}: ${rupees(t.amount)}', style: muted),
          if (l.cancelled)
            Text(
              context.tr(JewelryMarketL10n.stepCancelled),
              style: LuxeType.label(p.caution, size: 12.5),
            ),
        ],
      ),
    );
  }
}
