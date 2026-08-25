import 'fee_rule.dart';

/// Fallback fee rules when `GET /fees` is unavailable.
abstract final class CartFeeConfig {
  static const double gstRate = 0.03;
  static const double transactionFeeRate = 0.0236;
  static const double platformFeeInr = 100;
  static const double platformFeeThresholdInr = 5000;
  static const double deliveryFeeInr = 99;
}

class CartLineForFees {
  const CartLineForFees({
    required this.productType,
    required this.amountUsd,
  });

  final String productType;
  final double amountUsd;
}

/// Estimated checkout breakdown derived from cart merchandise + live FX + fees.
class CartOrderEstimate {
  const CartOrderEstimate({
    required this.merchandiseUsd,
    required this.verificationUsd,
    required this.merchandiseInr,
    required this.verificationInr,
    required this.gstInr,
    required this.transactionFeeInr,
    required this.platformFeeInr,
    required this.deliveryFeeInr,
    required this.totalInr,
    required this.totalUsd,
    this.gstRateLabel,
    this.transactionFeeRateLabel,
    this.exchangeRate,
  });

  final double merchandiseUsd;
  final double verificationUsd;
  final double merchandiseInr;
  final double verificationInr;
  final double gstInr;
  final double transactionFeeInr;
  final double platformFeeInr;
  final double deliveryFeeInr;
  final double totalInr;
  final double totalUsd;
  final String? gstRateLabel;
  final String? transactionFeeRateLabel;
  final double? exchangeRate;

  double get taxableInr => merchandiseInr + verificationInr;

  bool get hasLiveRate => exchangeRate != null && exchangeRate! > 0;

  String get liveRateLabel {
    final rate = exchangeRate;
    if (rate == null || rate <= 0) return '';
    return 'Live rate · 1 USD = ₹${rate.toStringAsFixed(2)}';
  }

  factory CartOrderEstimate.compute({
    required double merchandiseUsd,
    double? exchangeRate,
    bool wantVerification = false,
    FeeRulesCatalog? fees,
    List<CartLineForFees> lines = const [],
  }) {
    final catalog = fees ?? FeeRulesCatalog.empty;
    final rate =
        (exchangeRate != null && exchangeRate > 0) ? exchangeRate : null;
    final merchandiseInr = rate == null ? 0.0 : merchandiseUsd * rate;

    final verificationOffered = catalog.offersGemworldVerification;
    final verificationRate = verificationOffered
        ? _percentageRate(
            catalog,
            FeeType.gemworldVerification,
            fallback: 0,
          )
        : 0.0;
    final verificationUsd =
        wantVerification && verificationOffered
            ? merchandiseUsd * verificationRate
            : 0.0;
    final verificationInr = rate == null ? 0.0 : verificationUsd * rate;
    final taxableInr = merchandiseInr + verificationInr;

    final gstInr = rate == null
        ? 0.0
        : _gstInr(
            catalog: catalog,
            lines: lines,
            merchandiseUsd: merchandiseUsd,
            taxableInr: taxableInr,
            exchangeRate: rate,
          );

    final txRate = _percentageRate(
      catalog,
      FeeType.transactionFee,
      fallback: CartFeeConfig.transactionFeeRate,
    );
    final transactionFeeInr =
        rate == null ? 0.0 : (taxableInr + gstInr) * txRate;

    final platformFeeInr = rate == null
        ? 0.0
        : _fixedFee(
            catalog,
            FeeType.platformFee,
            cartInr: taxableInr,
            fallbackValue: CartFeeConfig.platformFeeInr,
            fallbackMin: CartFeeConfig.platformFeeThresholdInr,
          );

    final deliveryFeeInr = rate == null
        ? 0.0
        : _fixedFee(
            catalog,
            FeeType.deliveryFee,
            cartInr: taxableInr,
            fallbackValue: CartFeeConfig.deliveryFeeInr,
            fallbackMin: null,
          );

    final totalInr = taxableInr +
        gstInr +
        transactionFeeInr +
        platformFeeInr +
        deliveryFeeInr;
    final totalUsd = rate == null
        ? merchandiseUsd + verificationUsd
        : totalInr / rate;

    return CartOrderEstimate(
      merchandiseUsd: merchandiseUsd,
      verificationUsd: verificationUsd,
      merchandiseInr: merchandiseInr,
      verificationInr: verificationInr,
      gstInr: gstInr,
      transactionFeeInr: transactionFeeInr,
      platformFeeInr: platformFeeInr,
      deliveryFeeInr: deliveryFeeInr,
      totalInr: totalInr,
      totalUsd: totalUsd,
      gstRateLabel: _gstLabel(catalog, lines),
      transactionFeeRateLabel: (txRate * 100).toStringAsFixed(2),
      exchangeRate: rate,
    );
  }

  static double _percentageRate(
    FeeRulesCatalog catalog,
    FeeType type, {
    required double fallback,
  }) {
    final rules = catalog
        .ofType(type)
        .where((r) => r.valueType.isPercentage)
        .toList();
    if (rules.isEmpty) return fallback;
    return rules.first.rateFraction;
  }

  static double _fixedFee(
    FeeRulesCatalog catalog,
    FeeType type, {
    required double cartInr,
    required double fallbackValue,
    required double? fallbackMin,
  }) {
    final rules =
        catalog.ofType(type).where((r) => r.valueType.isFixed).toList();
    if (rules.isEmpty) {
      if (fallbackMin != null && cartInr < fallbackMin) return 0;
      return fallbackValue;
    }
    var total = 0.0;
    for (final rule in rules) {
      if (!rule.appliesToCartValueInr(cartInr)) continue;
      total += rule.value;
    }
    return total;
  }

  static double _gstInr({
    required FeeRulesCatalog catalog,
    required List<CartLineForFees> lines,
    required double merchandiseUsd,
    required double taxableInr,
    required double exchangeRate,
  }) {
    final gstRules =
        catalog.ofType(FeeType.gst).where((r) => r.valueType.isPercentage);
    if (gstRules.isEmpty) {
      return taxableInr * CartFeeConfig.gstRate;
    }

    if (lines.isEmpty || merchandiseUsd <= 0) {
      final rate = gstRules.fold<double>(0, (sum, r) => sum + r.rateFraction) /
          gstRules.length.clamp(1, 100);
      // Prefer global/empty-category rules when no lines.
      final global = gstRules.where((r) => r.productCategories.isEmpty);
      if (global.isNotEmpty) {
        final gRate =
            global.fold<double>(0, (sum, r) => sum + r.rateFraction);
        return taxableInr * gRate;
      }
      return taxableInr * rate;
    }

    var gst = 0.0;
    for (final line in lines) {
      final lineInr = line.amountUsd * exchangeRate;
      // Scale verification proportionally into taxable base for that line.
      final share =
          merchandiseUsd <= 0 ? 0.0 : line.amountUsd / merchandiseUsd;
      final lineTaxable = lineInr + (taxableInr - (merchandiseUsd * exchangeRate)) * share;
      final matching = gstRules.where((r) => r.appliesToCategory(line.productType));
      final rate = matching.fold<double>(0, (sum, r) => sum + r.rateFraction);
      gst += lineTaxable * rate;
    }
    return gst;
  }

  static String? _gstLabel(
    FeeRulesCatalog catalog,
    List<CartLineForFees> lines,
  ) {
    final gstRules =
        catalog.ofType(FeeType.gst).where((r) => r.valueType.isPercentage);
    if (gstRules.isEmpty) {
      return (CartFeeConfig.gstRate * 100).toStringAsFixed(0);
    }
    if (lines.isEmpty) {
      final global = gstRules.where((r) => r.productCategories.isEmpty);
      final source = global.isNotEmpty ? global : gstRules;
      final pct = source.fold<double>(0, (sum, r) => sum + r.value);
      return pct.toStringAsFixed(pct == pct.roundToDouble() ? 0 : 2);
    }
    // Show blended label from unique rates applied.
    final rates = <double>{};
    for (final line in lines) {
      final matching =
          gstRules.where((r) => r.appliesToCategory(line.productType));
      rates.add(matching.fold<double>(0, (sum, r) => sum + r.value));
    }
    if (rates.length == 1) {
      final pct = rates.first;
      return pct.toStringAsFixed(pct == pct.roundToDouble() ? 0 : 2);
    }
    return 'mixed';
  }
}
