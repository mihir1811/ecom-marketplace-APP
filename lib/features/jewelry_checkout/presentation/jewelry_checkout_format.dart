import 'package:flutter/material.dart';

import '../../../core/utils/app_currency.dart';
import '../../../core/utils/format_catalog_price.dart';

/// "₹98,610", or "₹41,302.10" when there are paise: always 2 decimals then,
/// so the screen matches what Razorpay charges.
String rupees(double v) {
  final paise = (v * 100).round();
  if (paise % 100 == 0) {
    return '${AppCurrency.inrSymbol}${formatGroupedWhole(v)}';
  }
  final whole = formatGroupedWhole((paise.abs() ~/ 100).toDouble());
  final frac = (paise.abs() % 100).toString().padLeft(2, '0');
  return '${paise < 0 ? '-' : ''}${AppCurrency.inrSymbol}$whole.$frac';
}

/// "GST (3%)" rows joined: "GST (3%) + Cess (1%)".
String taxLabels(Iterable<String> labels) => labels.join(' + ');

/// "Metal: 14K Yellow Gold · Ring size: 7".
String optionsLine(Map<String, String> options) =>
    options.entries.map((e) => '${e.key}: ${e.value}').join(' · ');

/// Localized "26 Oct 2026, 4:05 PM".
String dateTimeLabel(BuildContext context, DateTime? at) {
  if (at == null) return '—';
  final l = MaterialLocalizations.of(context);
  return '${l.formatMediumDate(at)}, '
      '${l.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
}

/// Localized date for a `YYYY-MM-DD` calendar date (no time zone shift).
String calendarDateLabel(BuildContext context, String? ymd) {
  if (ymd == null) return '—';
  final parts = ymd.split('-');
  if (parts.length != 3) return ymd;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return ymd;
  return MaterialLocalizations.of(context).formatMediumDate(DateTime(y, m, d));
}
