/// Shared catalog price formatters. Keep variants separate where UI differs.
library;

/// Exact backend price with at most 2 decimal places.
/// Whole amounts omit `.00`; a single trailing zero is dropped (`4.50` → `4.5`).
String formatCatalogPrice(double price) => _formatExact(price, group: false);

/// Filter-chip range style — same precision rules as [formatCatalogPrice].
String formatCatalogPriceWholeK(double price) => formatCatalogPrice(price);

/// Watch / bullion style: comma-grouped exact price (no K/M).
String formatGroupedPrice(double price) => formatGroupedWhole(price);

/// Currency-agnostic exact style: comma-grouped, up to 2 decimals.
String formatGroupedWhole(double price) => _formatExact(price, group: true);

/// Jewelry INR style: comma-grouped whole/fractional units (no K/M).
String formatInrPrice(double price) => formatGroupedWhole(price);

/// Fixed fractional precision for product-detail measurements/weights.
/// Example: `34.78564` → `34.78`.
String formatDecimal(double value, {int fractionDigits = 2}) =>
    value.toStringAsFixed(fractionDigits);

/// Discount % for badges/labels: truncate toward zero to 2 decimals.
/// Examples: `3.16` → `3.16`, `3.1575` → `3.15`.
String formatDiscountPercent(double value) {
  final truncated = (value * 100).truncateToDouble() / 100;
  return truncated.toStringAsFixed(2);
}

/// Markdown % for UI badges and dual-price display (exclusive 0–100).
///
/// Diamonds send a signed RAP discount (negative = below list). Watches /
/// jewelry / gemstones send a positive "% off" when present.
double? catalogMarkdownPercent(double? raw) {
  if (raw == null || raw == 0) return null;
  final percent = raw < 0 ? raw.abs() : raw;
  if (percent <= 0 || percent >= 100) return null;
  return percent;
}

/// Diamond `discount` from the detail API is a signed percent versus `rap`.
/// Prefer [catalogMarkdownPercent] for shared UI.
double? belowListDiscountPercent(double? signed) =>
    catalogMarkdownPercent(signed);

/// Infers list / RAP total from an already-discounted net price.
double? catalogListFromNet(double net, double markdownPercent) {
  if (net <= 0 || markdownPercent <= 0 || markdownPercent >= 100) return null;
  return net / (1 - markdownPercent / 100);
}

String _formatExact(double price, {required bool group}) {
  final fixed = price.toStringAsFixed(2);
  final negative = fixed.startsWith('-');
  final raw = negative ? fixed.substring(1) : fixed;
  final parts = raw.split('.');
  final whole = group ? _groupDigits(parts[0]) : parts[0];
  final frac = parts[1];
  final body = frac == '00'
      ? whole
      : frac.endsWith('0')
          ? '$whole.${frac[0]}'
          : '$whole.$frac';
  return negative ? '-$body' : body;
}

String _groupDigits(String digits) {
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    buf.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
  }
  return buf.toString();
}
