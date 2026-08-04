/// Market display currencies — USD (primary) and INR (secondary).
///
/// Keep the single source for symbols/formats here so every price UI that
/// imports this file renders both currencies consistently.
abstract final class AppCurrency {
  const AppCurrency._();

  /// USD display symbol.
  static const String usdSymbol = '\$';

  /// INR display symbol.
  static const String inrSymbol = '₹';

  /// ISO 4217 codes.
  static const String usdCode = 'USD';
  static const String inrCode = 'INR';

  /// Legacy aliases (USD) kept for callers referencing them directly.
  static const String symbol = usdSymbol;
  static const String code = usdCode;

  /// Prefixes a pre-formatted amount with the USD symbol (legacy helper).
  static String format(Object amount) => '$usdSymbol$amount';

  /// Formats a USD amount with [decimals] places.
  static String usd(num amount, {int decimals = 2}) =>
      '$usdSymbol${amount.toStringAsFixed(decimals)}';

  /// Formats an INR amount with [decimals] places.
  static String inr(num amount, {int decimals = 2}) =>
      '$inrSymbol${amount.toStringAsFixed(decimals)}';

  /// Combines a USD and an equivalent INR value, e.g. `$12.50 · ₹1,080.00`.
  static String dual(num usdAmount, num inrAmount, {int decimals = 2}) =>
      '${usd(usdAmount, decimals: decimals)} · '
      '${inr(inrAmount, decimals: decimals)}';

  /// Converts a USD amount to an estimated INR using [rate] (null-safe → 0).
  static double toInr(num usdAmount, double? rate) =>
      (rate == null || rate <= 0) ? 0 : usdAmount * rate;
}