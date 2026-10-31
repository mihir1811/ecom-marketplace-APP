/// GemWorld's tax invoice for a paid order
/// (`GET /marketplace/orders/{id}/invoice`). It never changes once issued:
/// a piece cancelled later stays with [InvoiceLine.cancelled] and its
/// refund is in [refunds]. The API has already split GST (CGST + SGST,
/// UTGST or IGST), so taxes are drawn as they come.
class MarketplaceInvoice {
  const MarketplaceInvoice({
    required this.number,
    required this.orderId,
    required this.orderNumber,
    required this.issuer,
    required this.buyer,
    required this.shipTo,
    required this.lines,
    required this.totals,
    this.issuedAt,
    this.orderedAt,
    this.paidAt,
    this.paymentMethod,
    this.paymentReference,
    this.currency = 'INR',
    this.placeOfSupplyState,
    this.placeOfSupplyCode,
    this.supplyType = 'UNKNOWN',
    this.taxSummary = const [],
    this.refunds = const [],
    this.refundedTotal = 0,
  });

  /// `JW/26-27/00001`.
  final String number;
  final DateTime? issuedAt;
  final String orderId;
  final String orderNumber;
  final DateTime? orderedAt;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? paymentReference;
  final String currency;
  final InvoiceIssuer issuer;
  final InvoiceBuyer buyer;
  final InvoiceShipTo shipTo;
  final String? placeOfSupplyState;
  final String? placeOfSupplyCode;

  /// `INTRA_STATE`, `INTER_STATE`, `EXPORT` or `UNKNOWN`.
  final String supplyType;
  final List<InvoiceLine> lines;
  final List<InvoiceTax> taxSummary;
  final InvoiceTotals totals;
  final List<InvoiceRefund> refunds;
  final double refundedTotal;
}

/// GemWorld, the seller of record.
class InvoiceIssuer {
  const InvoiceIssuer({
    this.legalName = '',
    this.tradeName,
    this.gstin,
    this.pan,
    this.addressLines = const [],
    this.state,
    this.stateCode,
    this.email,
    this.phone,
    this.defaultHsn,
    this.footerNote,
  });

  final String legalName;
  final String? tradeName;
  final String? gstin;
  final String? pan;

  /// Street lines, then "City, State PIN".
  final List<String> addressLines;
  final String? state;
  final String? stateCode;
  final String? email;
  final String? phone;
  final String? defaultHsn;
  final String? footerNote;
}

class InvoiceBuyer {
  const InvoiceBuyer({this.name = '', this.email, this.phone});

  final String name;
  final String? email;
  final String? phone;
}

class InvoiceShipTo {
  const InvoiceShipTo({
    this.fullName = '',
    this.phone,
    this.lines = const [],
    this.state,
    this.country,
  });

  final String fullName;
  final String? phone;

  /// Address lines, ready to print.
  final List<String> lines;
  final String? state;
  final String? country;
}

class InvoiceLine {
  const InvoiceLine({
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.taxableValue,
    required this.taxAmount,
    required this.total,
    this.id = '',
    this.maker,
    this.details,
    this.hsnCode,
    this.taxes = const [],
    this.cancelled = false,
  });

  final String id;
  final String title;

  /// The shop that made it.
  final String? maker;

  /// "Metal: 18K Yellow gold · Ring size: 5".
  final String? details;
  final String? hsnCode;
  final int quantity;
  final double unitPrice;
  final double taxableValue;
  final List<InvoiceTax> taxes;
  final double taxAmount;
  final double total;
  final bool cancelled;
}

/// A tax on an invoice line or in its summary: CGST, SGST, UTGST, IGST or
/// the tax's own name.
class InvoiceTax {
  const InvoiceTax({
    required this.label,
    required this.amount,
    this.rate,
    this.taxableValue = 0,
  });

  final String label;

  /// Percent; null for a fixed amount.
  final double? rate;

  /// Summary rows only.
  final double taxableValue;
  final double amount;

  /// "CGST 1.5%".
  String get display {
    final r = rate;
    if (r == null) return label;
    final pct = r == r.roundToDouble() ? r.toStringAsFixed(0) : '$r';
    return '$label $pct%';
  }
}

class InvoiceTotals {
  const InvoiceTotals({
    this.taxableValue = 0,
    this.taxTotal = 0,
    this.shipping = 0,
    this.total = 0,
    this.inWords,
  });

  final double taxableValue;
  final double taxTotal;
  final double shipping;
  final double total;

  /// "Rupees forty-one thousand … paise only".
  final String? inWords;
}

class InvoiceRefund {
  const InvoiceRefund({
    required this.title,
    required this.amount,
    this.status,
    this.cancelledAt,
    this.refundedAt,
  });

  final String title;
  final double amount;

  /// `PENDING`, `PROCESSED` or `FAILED`.
  final String? status;
  final DateTime? cancelledAt;
  final DateTime? refundedAt;
}
