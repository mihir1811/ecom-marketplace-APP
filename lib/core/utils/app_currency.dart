/// Marketplace display currency — single switch for the whole app.
///
/// Change [symbol] (and optionally [code]) once; every price UI that imports
/// this file picks up the new symbol automatically.
abstract final class AppCurrency {
  const AppCurrency._();

  /// Display symbol. Flip to `r'$'` (or another currency) to switch app-wide.
  static const String symbol = '₹';

  /// ISO 4217 code for copy, filters, and localization context.
  static const String code = 'INR';

  /// Prefixes a pre-formatted amount with [symbol].
  static String format(Object amount) => '$symbol$amount';
}
