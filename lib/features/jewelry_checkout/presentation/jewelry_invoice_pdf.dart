import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/format_catalog_price.dart';
import '../domain/models/marketplace_invoice.dart';

/// GemWorld's tax invoice as an A4 PDF, laid out like the website's
/// `/orders/{id}/invoice`. Uses the built-in PDF fonts, so amounts read
/// "Rs." and text outside Latin-1 is dropped.
Future<Uint8List> buildJewelryInvoicePdf(MarketplaceInvoice inv) {
  final doc = pw.Document(
    title: 'Tax invoice ${inv.number}',
    author: inv.issuer.legalName,
  );
  const ink = PdfColor.fromInt(0xFF1C1B1A);
  const muted = PdfColor.fromInt(0xFF6B6760);
  const line = PdfColor.fromInt(0xFFD9D4CC);
  const small = pw.TextStyle(fontSize: 8.5, color: muted);
  const body = pw.TextStyle(fontSize: 9.5, color: ink);
  const bold = pw.TextStyle(
    fontSize: 9.5,
    color: ink,
    fontWeight: pw.FontWeight.bold,
  );

  pw.Widget block(String title, List<String?> lines) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(_t(title.toUpperCase()), style: small),
      pw.SizedBox(height: 3),
      for (final l in lines)
        if (l != null && l.trim().isNotEmpty) pw.Text(_t(l), style: body),
    ],
  );

  final i = inv.issuer;
  final supply = [
    inv.placeOfSupplyState,
    if (inv.placeOfSupplyCode != null) '(${inv.placeOfSupplyCode})',
  ].whereType<String>().join(' ');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(_t(inv.number), style: small),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: small,
          ),
        ],
      ),
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _t(i.tradeName ?? i.legalName),
                    style: const pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  if (i.tradeName != null)
                    pw.Text(_t(i.legalName), style: body),
                  for (final l in i.addressLines) pw.Text(_t(l), style: body),
                  if (i.gstin != null) pw.Text('GSTIN ${i.gstin}', style: body),
                  if (i.pan != null) pw.Text('PAN ${i.pan}', style: body),
                  if (i.email != null || i.phone != null)
                    pw.Text(
                      _t([i.email, i.phone].whereType<String>().join('  ')),
                      style: body,
                    ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'TAX INVOICE',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: ink,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(_t(inv.number), style: bold),
                pw.Text('Date ${_date(inv.issuedAt)}', style: body),
                pw.Text(_t('Order ${inv.orderNumber}'), style: body),
                if (inv.paidAt != null)
                  pw.Text('Paid ${_date(inv.paidAt)}', style: body),
                if (inv.paymentMethod != null)
                  pw.Text(
                    _t(
                      [
                        inv.paymentMethod!.toUpperCase(),
                        inv.paymentReference,
                      ].whereType<String>().join(' · '),
                    ),
                    style: small,
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: block('Bill to', [
                inv.buyer.name,
                inv.buyer.email,
                inv.buyer.phone,
              ]),
            ),
            pw.Expanded(
              child: block('Ship to', [
                inv.shipTo.fullName,
                ...inv.shipTo.lines,
                inv.shipTo.phone,
              ]),
            ),
            pw.Expanded(
              child: block('Place of supply', [
                supply,
                _supplyLabel(inv.supplyType),
              ]),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: line, width: 0.5),
            bottom: pw.BorderSide(color: line, width: 0.5),
          ),
          headerStyle: const pw.TextStyle(
            fontSize: 8.5,
            color: ink,
            fontWeight: pw.FontWeight.bold,
          ),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF3EFE8),
          ),
          cellStyle: body,
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 5,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(1.1),
            2: const pw.FlexColumnWidth(0.6),
            3: const pw.FlexColumnWidth(1.6),
            4: const pw.FlexColumnWidth(2.2),
            5: const pw.FlexColumnWidth(1.6),
          },
          cellAlignments: {
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
            5: pw.Alignment.centerRight,
          },
          headers: const [
            'Item',
            'HSN',
            'Qty',
            'Taxable (Rs.)',
            'Tax (Rs.)',
            'Total (Rs.)',
          ],
          data: [
            for (final l in inv.lines)
              [
                _t(
                  [
                    l.title + (l.cancelled ? ' (cancelled)' : ''),
                    if (l.maker != null) 'by ${l.maker}',
                    ?l.details,
                  ].join('\n'),
                ),
                l.hsnCode ?? i.defaultHsn ?? '',
                '${l.quantity}',
                _money(l.taxableValue),
                l.taxes.isEmpty
                    ? _money(l.taxAmount)
                    : l.taxes
                          .map((t) => '${_t(t.display)}: ${_money(t.amount)}')
                          .join('\n'),
                _money(l.total),
              ],
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: inv.taxSummary.isEmpty
                  ? pw.SizedBox()
                  : pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TAX SUMMARY', style: small),
                        pw.SizedBox(height: 3),
                        for (final t in inv.taxSummary)
                          pw.Text(
                            _t(
                              '${t.display} on Rs. ${_money(t.taxableValue)}'
                              ' = Rs. ${_money(t.amount)}',
                            ),
                            style: body,
                          ),
                      ],
                    ),
            ),
            pw.SizedBox(width: 24),
            pw.SizedBox(
              width: 200,
              child: pw.Column(
                children: [
                  _sumRow('Taxable value', inv.totals.taxableValue, body),
                  _sumRow('Tax', inv.totals.taxTotal, body),
                  _sumRow('Shipping', inv.totals.shipping, body),
                  pw.Divider(color: line, thickness: 0.5),
                  _sumRow('Total', inv.totals.total, bold),
                ],
              ),
            ),
          ],
        ),
        if (inv.totals.inWords != null) ...[
          pw.SizedBox(height: 6),
          pw.Text(_t(inv.totals.inWords!), style: body),
        ],
        if (inv.refunds.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text('REFUNDS', style: small),
          pw.SizedBox(height: 3),
          for (final r in inv.refunds)
            pw.Text(
              _t(
                '${r.title}: Rs. ${_money(r.amount)}'
                '${r.status == null ? '' : ' (${r.status!.toLowerCase()})'}',
              ),
              style: body,
            ),
          pw.Text(
            'Refunded in total: Rs. ${_money(inv.refundedTotal)}',
            style: bold,
          ),
        ],
        if (i.footerNote != null) ...[
          pw.SizedBox(height: 14),
          pw.Text(_t(i.footerNote!), style: small),
        ],
      ],
    ),
  );
  return doc.save();
}

pw.Widget _sumRow(String label, double amount, pw.TextStyle style) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.Text('Rs. ${_money(amount)}', style: style),
        ],
      ),
    );

String _supplyLabel(String type) => switch (type) {
  'INTRA_STATE' => 'Intra-state supply',
  'INTER_STATE' => 'Inter-state supply',
  'EXPORT' => 'Export',
  _ => '',
};

/// "41,302.11" or "30,400".
String _money(double v) {
  final paise = (v * 100).round();
  final whole = formatGroupedWhole((paise.abs() ~/ 100).toDouble());
  final sign = paise < 0 ? '-' : '';
  if (paise % 100 == 0) return '$sign$whole';
  return '$sign$whole.${(paise.abs() % 100).toString().padLeft(2, '0')}';
}

String _date(DateTime? at) {
  if (at == null) return '-';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${at.day} ${months[at.month - 1]} ${at.year}';
}

/// Keeps what the built-in PDF fonts can draw (Latin-1), swapping the
/// rupee sign and common punctuation first.
String _t(String s) {
  final swapped = s
      .replaceAll('₹', 'Rs. ')
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('‘', "'")
      .replaceAll('’', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('…', '...');
  return String.fromCharCodes(swapped.runes.where((r) => r < 0x100));
}
