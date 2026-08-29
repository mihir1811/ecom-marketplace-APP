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

/// One order-summary fee row (from `GET /fees` rule or local fallback).
class CartFeeLine {
  const CartFeeLine({
    required this.feeType,
    required this.label,
    required this.amountInr,
    this.rateLabel,
  });

  final FeeType feeType;
  final String label;
  final double amountInr;

  /// e.g. `2.36` for percentage display as `2.36%`.
  final String? rateLabel;
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
    this.feeLines = const [],
    this.gstRateLabel,
    this.transactionFeeRateLabel,
    this.exchangeRate,
    this.totalFromApi = false,
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
  final List<CartFeeLine> feeLines;
  final String? gstRateLabel;
  final String? transactionFeeRateLabel;
  final double? exchangeRate;

  /// True when [totalInr]/[totalUsd] came from a cart/payment API total field.
  final bool totalFromApi;

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
    double? apiTotalInr,
    double? apiTotalUsd,
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

    final feeLines = <CartFeeLine>[];

    if (rate != null) {
      feeLines.addAll(
        _gstLines(
          catalog: catalog,
          lines: lines,
          merchandiseUsd: merchandiseUsd,
          taxableInr: taxableInr,
          exchangeRate: rate,
        ),
      );

      final gstInr =
          feeLines.fold<double>(0, (sum, l) => sum + l.amountInr);

      feeLines.addAll(
        _percentageLines(
          catalog: catalog,
          type: FeeType.transactionFee,
          baseInr: taxableInr + gstInr,
          fallbackRate: CartFeeConfig.transactionFeeRate,
          fallbackName: 'Transaction fee',
        ),
      );

      feeLines.addAll(
        _fixedLines(
          catalog: catalog,
          type: FeeType.platformFee,
          cartInr: taxableInr,
          fallbackValue: CartFeeConfig.platformFeeInr,
          fallbackMin: CartFeeConfig.platformFeeThresholdInr,
          fallbackName: 'Platform fee',
        ),
      );

      feeLines.addAll(
        _fixedLines(
          catalog: catalog,
          type: FeeType.deliveryFee,
          cartInr: taxableInr,
          fallbackValue: CartFeeConfig.deliveryFeeInr,
          fallbackMin: null,
          fallbackName: 'Delivery fee',
        ),
      );
    }

    final gstInr = feeLines
        .where((l) => l.feeType == FeeType.gst)
        .fold<double>(0, (sum, l) => sum + l.amountInr);
    final transactionFeeInr = feeLines
        .where((l) => l.feeType == FeeType.transactionFee)
        .fold<double>(0, (sum, l) => sum + l.amountInr);
    final platformFeeInr = feeLines
        .where((l) => l.feeType == FeeType.platformFee)
        .fold<double>(0, (sum, l) => sum + l.amountInr);
    final deliveryFeeInr = feeLines
        .where((l) => l.feeType == FeeType.deliveryFee)
        .fold<double>(0, (sum, l) => sum + l.amountInr);

    final feesInr =
        feeLines.fold<double>(0, (sum, l) => sum + l.amountInr);
    final calculatedTotalInr = taxableInr + feesInr;
    final calculatedTotalUsd = rate == null
        ? merchandiseUsd + verificationUsd
        : calculatedTotalInr / rate;

    final hasApiTotalInr = apiTotalInr != null && apiTotalInr > 0;
    final hasApiTotalUsd = apiTotalUsd != null && apiTotalUsd > 0;
    final totalFromApi = hasApiTotalInr || hasApiTotalUsd;
    final totalInr = hasApiTotalInr
        ? apiTotalInr
        : (rate == null ? 0.0 : calculatedTotalInr);
    final totalUsd = hasApiTotalUsd
        ? apiTotalUsd
        : (hasApiTotalInr && rate != null
            ? apiTotalInr / rate
            : calculatedTotalUsd);

    final txRules = feeLines.where((l) => l.feeType == FeeType.transactionFee);
    String? txLabel;
    for (final line in txRules) {
      if (line.rateLabel != null) {
        txLabel = line.rateLabel;
        break;
      }
    }

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
      feeLines: feeLines.where((l) => l.amountInr > 0.009).toList(),
      gstRateLabel: _gstLabel(catalog, lines),
      transactionFeeRateLabel: txLabel,
      exchangeRate: rate,
      totalFromApi: totalFromApi,
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
    if (rules.isEmpty) {
      return catalog.isFromApi ? 0 : fallback;
    }
    return rules.first.rateFraction;
  }

  static List<CartFeeLine> _percentageLines({
    required FeeRulesCatalog catalog,
    required FeeType type,
    required double baseInr,
    required double fallbackRate,
    required String fallbackName,
  }) {
    final rules = catalog
        .ofType(type)
        .where((r) => r.valueType.isPercentage)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    if (rules.isEmpty) {
      if (catalog.isFromApi || fallbackRate <= 0 || baseInr <= 0) {
        return const [];
      }
      final pct = fallbackRate * 100;
      return [
        CartFeeLine(
          feeType: type,
          label: fallbackName,
          amountInr: baseInr * fallbackRate,
          rateLabel: pct.toStringAsFixed(pct == pct.roundToDouble() ? 0 : 2),
        ),
      ];
    }

    return [
      for (final rule in rules)
        if (baseInr > 0 && rule.rateFraction > 0)
          CartFeeLine(
            feeType: type,
            label: _displayName(rule, fallbackName),
            amountInr: baseInr * rule.rateFraction,
            rateLabel: rule.value.toStringAsFixed(
              rule.value == rule.value.roundToDouble() ? 0 : 2,
            ),
          ),
    ];
  }

  static List<CartFeeLine> _fixedLines({
    required FeeRulesCatalog catalog,
    required FeeType type,
    required double cartInr,
    required double fallbackValue,
    required double? fallbackMin,
    required String fallbackName,
  }) {
    final rules = catalog
        .ofType(type)
        .where((r) => r.valueType.isFixed)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    if (rules.isEmpty) {
      if (catalog.isFromApi) return const [];
      if (fallbackMin != null && cartInr < fallbackMin) return const [];
      if (fallbackValue <= 0) return const [];
      return [
        CartFeeLine(
          feeType: type,
          label: fallbackName,
          amountInr: fallbackValue,
        ),
      ];
    }

    return [
      for (final rule in rules)
        if (rule.appliesToCartValueInr(cartInr) && rule.value > 0)
          CartFeeLine(
            feeType: type,
            label: _displayName(rule, fallbackName),
            amountInr: rule.value,
          ),
    ];
  }

  static List<CartFeeLine> _gstLines({
    required FeeRulesCatalog catalog,
    required List<CartLineForFees> lines,
    required double merchandiseUsd,
    required double taxableInr,
    required double exchangeRate,
  }) {
    final gstRules = catalog
        .ofType(FeeType.gst)
        .where((r) => r.valueType.isPercentage)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    if (gstRules.isEmpty) {
      if (catalog.isFromApi || taxableInr <= 0) return const [];
      final pct = CartFeeConfig.gstRate * 100;
      return [
        CartFeeLine(
          feeType: FeeType.gst,
          label: 'GST',
          amountInr: taxableInr * CartFeeConfig.gstRate,
          rateLabel: pct.toStringAsFixed(pct == pct.roundToDouble() ? 0 : 2),
        ),
      ];
    }

    // Per-rule amounts so CGST / SGST / jewellery GST show separately.
    final amounts = <String, double>{};
    final labels = <String, String>{};
    final rates = <String, double>{};

    void addRule(FeeRule rule, double baseInr) {
      if (baseInr <= 0 || rule.rateFraction <= 0) return;
      if (!rule.appliesToCartValueInr(baseInr)) return;
      final key = rule.id.isNotEmpty ? rule.id : rule.name;
      amounts[key] = (amounts[key] ?? 0) + baseInr * rule.rateFraction;
      labels[key] = _displayName(rule, 'GST');
      rates[key] = rule.value;
    }

    if (lines.isEmpty || merchandiseUsd <= 0) {
      final global = gstRules.where((r) => r.productCategories.isEmpty);
      final source = global.isNotEmpty ? global : gstRules;
      for (final rule in source) {
        addRule(rule, taxableInr);
      }
    } else {
      for (final line in lines) {
        final lineInr = line.amountUsd * exchangeRate;
        final share =
            merchandiseUsd <= 0 ? 0.0 : line.amountUsd / merchandiseUsd;
        final lineTaxable = lineInr +
            (taxableInr - (merchandiseUsd * exchangeRate)) * share;
        final matching =
            gstRules.where((r) => r.appliesToCategory(line.productType));
        for (final rule in matching) {
          addRule(rule, lineTaxable);
        }
      }
    }

    return [
      for (final key in amounts.keys)
        if ((amounts[key] ?? 0) > 0.009)
          CartFeeLine(
            feeType: FeeType.gst,
            label: labels[key] ?? 'GST',
            amountInr: amounts[key]!,
            rateLabel: () {
              final pct = rates[key] ?? 0;
              return pct.toStringAsFixed(
                pct == pct.roundToDouble() ? 0 : 2,
              );
            }(),
          ),
    ];
  }

  static String _displayName(FeeRule rule, String fallback) {
    final name = rule.name.trim();
    return name.isEmpty ? fallback : name;
  }

  static String? _gstLabel(
    FeeRulesCatalog catalog,
    List<CartLineForFees> lines,
  ) {
    final gstRules =
        catalog.ofType(FeeType.gst).where((r) => r.valueType.isPercentage);
    if (gstRules.isEmpty) {
      return catalog.isFromApi
          ? null
          : (CartFeeConfig.gstRate * 100).toStringAsFixed(0);
    }
    if (lines.isEmpty) {
      final global = gstRules.where((r) => r.productCategories.isEmpty);
      final source = global.isNotEmpty ? global : gstRules;
      final pct = source.fold<double>(0, (sum, r) => sum + r.value);
      return pct.toStringAsFixed(pct == pct.roundToDouble() ? 0 : 2);
    }
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
