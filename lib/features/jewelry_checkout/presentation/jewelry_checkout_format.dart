import 'package:flutter/material.dart';

import '../../../core/utils/app_currency.dart';
import '../../../core/utils/format_catalog_price.dart';

/// "₹98,610" (paise shown only when present).
String rupees(double v) => '${AppCurrency.inrSymbol}${formatGroupedWhole(v)}';

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
