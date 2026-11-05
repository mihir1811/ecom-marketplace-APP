import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/utils/app_currency.dart';
import 'package:gemworld/features/jewelry/data/mappers/marketplace_mapper.dart';
import 'package:gemworld/features/jewelry_checkout/data/mappers/jewelry_checkout_mapper.dart';
import 'package:gemworld/features/jewelry_checkout/domain/models/marketplace_order.dart';
import 'package:gemworld/features/jewelry_checkout/presentation/jewelry_checkout_format.dart';
import 'package:gemworld/features/jewelry_checkout/presentation/jewelry_invoice_pdf.dart';

void main() {
  const r = AppCurrency.inrSymbol;

  test('rupees shows 2 decimals only when there are paise', () {
    expect(rupees(30400), '${r}30,400');
    expect(rupees(41302.11), '${r}41,302.11');
    expect(rupees(41302.1), '${r}41,302.10');
    expect(rupees(0.5), '${r}0.50');
  });

  test('quote reads taxes, and a missing list as none', () {
    // Live shape (2026-10-31).
    final q = JewelryCheckoutMapper.quote({
      'lines': [
        {
          'skuId': 'b900fe03-807b-415e-a3c3-db99eee08aed',
          'unitPrice': 40955.04,
          'quantity': 1,
          'lineTotal': 40955.04,
          'taxAmount': 1228.65,
          'maxQuantity': 1,
          'problem': null,
          'taxes': [
            {
              'name': 'GST',
              'label': 'GST (3%)',
              'valueType': 'PERCENTAGE',
              'value': 3,
              'amount': 1228.65,
            },
          ],
        },
      ],
      'subtotal': 40955.04,
      'shipping': 0,
      'taxes': [
        {'name': 'GST', 'label': 'GST (3%)', 'amount': 1228.65},
      ],
      'taxTotal': 1228.65,
      'total': 42183.69,
      'ready': true,
    });
    expect(q.taxes.single.label, 'GST (3%)');
    expect(q.taxTotal, 1228.65);
    expect(q.total, 42183.69);
    expect(q.lines.single.taxAmount, 1228.65);

    final old = JewelryCheckoutMapper.quote({
      'lines': [],
      'subtotal': 100,
      'shipping': 0,
      'total': 100,
      'ready': true,
    });
    expect(old.taxes, isEmpty);
    expect(old.taxTotal, 0);
  });

  test('order reads taxes, invoice and country', () {
    final o = JewelryCheckoutMapper.order({
      'id': '9692bbd7-0000-4000-8000-000000000000',
      'orderNumber': 'JW-261030-WUBEJ',
      'status': 'PAID',
      'subtotal': 30400,
      'total': 31312,
      'taxTotal': 912,
      'taxes': [
        {'name': 'GST', 'label': 'GST (3%)', 'amount': 912},
      ],
      'paidAt': '2026-10-30T06:14:53.398Z',
      'invoice': {
        'number': 'JW/26-27/00001',
        'issuedAt': '2026-10-30T06:14:53.398Z',
      },
      'shippingAddress': {
        'fullName': 'Asha Mehta',
        'phone': '+971 50 000 0000',
        'line1': '12 Palm Street',
        'city': 'Dubai',
        'state': '',
        'postalCode': '',
        'country': 'AE',
      },
      'items': [
        {
          'id': 'c1a90d3e-0000-4000-8000-000000000000',
          'title': 'Croissant dome stacking ring',
          'unitPrice': 30400,
          'quantity': 1,
          'lineTotal': 30400,
          'taxAmount': 912,
          'status': 'ACCEPTED',
        },
      ],
    });
    expect(o.taxes.single.amount, 912);
    expect(o.invoice?.number, 'JW/26-27/00001');
    expect(o.canShowInvoice, isTrue);
    expect(o.items.single.paidTotal, 31312);
    expect(o.address?.country, 'AE');
    expect(o.address?.summaryLine, '12 Palm Street, Dubai, AE');

    // A paid order from before invoices existed (no field) shows none.
    final legacy = JewelryCheckoutMapper.order({
      'id': 'x',
      'status': 'PAID',
      'paidAt': '2026-10-01T00:00:00.000Z',
    });
    expect(legacy.canShowInvoice, isFalse);
  });

  test('address sends country and leaves out empty state and postal code', () {
    const abroad = MarketplaceAddress(
      fullName: 'Asha',
      phone: '+971500000000',
      line1: '12 Palm Street',
      city: 'Dubai',
      state: ' ',
      postalCode: '',
      country: 'ae',
    );
    expect(abroad.toJson(), {
      'fullName': 'Asha',
      'phone': '+971500000000',
      'line1': '12 Palm Street',
      'city': 'Dubai',
      'country': 'AE',
    });
  });

  test('listing reads tax labels for the product page', () {
    final l = MarketplaceMapper.listing({
      'id': '243577e9-0fa0-458c-a634-ac1e01a76f12',
      'slug': 'ring',
      'title': 'Ring',
      'taxes': [
        {
          'name': 'GST',
          'label': 'GST (3%)',
          'valueType': 'PERCENTAGE',
          'value': 3,
        },
      ],
    });
    expect(l.taxLabels, ['GST (3%)']);
  });

  test('invoice maps the guide sample and renders a PDF', () async {
    final inv = JewelryCheckoutMapper.invoice({
      'number': 'JW/26-27/00001',
      'issuedAt': '2026-10-30T06:14:53.398Z',
      'orderId': '9692bbd7-0000-4000-8000-000000000000',
      'orderNumber': 'JW-261030-WUBEJ',
      'paymentMethod': 'upi',
      'paymentReference': 'pay_123',
      'currency': 'INR',
      'issuer': {
        'legalName': 'GemWorld Jewels Private Limited',
        'tradeName': 'jewellery by GemWorld',
        'gstin': '08AABCG1234F1Z5',
        'pan': 'AABCG1234F',
        'addressLine1': '1 MI Road',
        'addressLine2': null,
        'city': 'Jaipur',
        'state': 'Rajasthan',
        'stateCode': '08',
        'postalCode': '302003',
        'defaultHsn': '7113',
        'footerNote': 'Thank you – GemWorld ₹',
      },
      'buyer': {'name': 'Asha Mehta'},
      'shipTo': {
        'fullName': 'Asha Mehta',
        'lines': ['12 MG Road', 'Jaipur, Rajasthan 302001'],
        'state': 'Rajasthan',
        'country': 'IN',
      },
      'placeOfSupply': {'state': 'Rajasthan', 'code': '08'},
      'supplyType': 'INTRA_STATE',
      'lines': [
        {
          'id': 'l1',
          'title': 'Croissant dome stacking ring',
          'maker': 'pinksjewel',
          'details': 'Metal: 18K Yellow gold · Ring size: 5',
          'hsnCode': '7113',
          'quantity': 1,
          'unitPrice': 30400,
          'taxableValue': 30400,
          'taxes': [
            {'label': 'CGST', 'rate': 1.5, 'amount': 456},
            {'label': 'SGST', 'rate': 1.5, 'amount': 456},
          ],
          'taxAmount': 912,
          'total': 31312,
          'cancelled': false,
        },
      ],
      'taxSummary': [
        {
          'label': 'CGST',
          'rate': 1.5,
          'taxableValue': 40099.14,
          'amount': 601.49,
        },
      ],
      'totals': {
        'taxableValue': 40099.14,
        'taxTotal': 1202.97,
        'shipping': 0,
        'total': 41302.11,
        'inWords': 'Rupees forty-one thousand three hundred two only',
      },
      'refunds': [
        {'title': 'Ring', 'amount': 3913.11, 'status': 'PROCESSED'},
      ],
      'refundedTotal': 3913.11,
    });
    expect(inv.issuer.addressLines, ['1 MI Road', 'Jaipur, Rajasthan 302003']);
    expect(inv.lines.single.taxes.first.display, 'CGST 1.5%');
    expect(inv.totals.total, 41302.11);
    expect(inv.refunds.single.amount, 3913.11);

    final pdf = await buildJewelryInvoicePdf(inv);
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
  });
}
