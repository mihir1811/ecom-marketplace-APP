/// Shared catalog price formatters. Keep variants separate where UI differs.
library;

/// Diamond / gemstone card style: `1.2K`, `15K`.
String formatCatalogPrice(double price) {
  if (price >= 1000) {
    return '${(price / 1000).toStringAsFixed(price >= 10000 ? 0 : 1)}K';
  }
  return price.toStringAsFixed(0);
}

/// Filter-chip range style: whole-thousands K only.
String formatCatalogPriceWholeK(double price) {
  if (price >= 1000) {
    return '${(price / 1000).toStringAsFixed(0)}K';
  }
  return price.toStringAsFixed(0);
}

/// Watch / bullion style: `1.5M` or comma-grouped thousands.
String formatGroupedPrice(double price) {
  if (price >= 1000000) {
    return '${(price / 1000000).toStringAsFixed(1)}M';
  }
  if (price >= 1000) {
    return formatInrPrice(price);
  }
  return price.toStringAsFixed(0);
}

/// Jewelry INR style: comma-grouped whole units (no K/M).
String formatInrPrice(double price) {
  final s = price.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
  }
  return buf.toString();
}
