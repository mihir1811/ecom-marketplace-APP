/// Frontend-only cart fee rules used to build the order summary UI.
///
/// These values are not returned by cart APIs; keep them here until the backend
/// owns the same policy.
abstract final class CartFeeConfig {
  static const double gstRate = 0.03;
  static const double transactionFeeRate = 0.0218;
  static const double platformFeeInr = 100;
  static const double platformFeeThresholdInr = 10000;
  static const double verificationRate = 0.01;
}

/// Estimated checkout breakdown derived from cart merchandise + live FX.
class CartOrderEstimate {
  const CartOrderEstimate({
    required this.merchandiseUsd,
    required this.verificationUsd,
    required this.merchandiseInr,
    required this.verificationInr,
    required this.gstInr,
    required this.transactionFeeInr,
    required this.platformFeeInr,
    required this.totalInr,
    required this.totalUsd,
    this.exchangeRate,
  });

  /// Discounted merchandise in USD (before frontend fees).
  final double merchandiseUsd;
  final double verificationUsd;
  final double merchandiseInr;
  final double verificationInr;
  final double gstInr;
  final double transactionFeeInr;
  final double platformFeeInr;
  final double totalInr;
  final double totalUsd;
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
  }) {
    final verificationUsd = wantVerification
        ? merchandiseUsd * CartFeeConfig.verificationRate
        : 0.0;
    final rate =
        (exchangeRate != null && exchangeRate > 0) ? exchangeRate : null;
    final merchandiseInr = rate == null ? 0.0 : merchandiseUsd * rate;
    final verificationInr = rate == null ? 0.0 : verificationUsd * rate;
    final taxableInr = merchandiseInr + verificationInr;
    final gstInr = taxableInr * CartFeeConfig.gstRate;
    final transactionFeeInr =
        (taxableInr + gstInr) * CartFeeConfig.transactionFeeRate;
    final platformFeeInr =
        taxableInr > CartFeeConfig.platformFeeThresholdInr
            ? CartFeeConfig.platformFeeInr
            : 0.0;
    final totalInr =
        taxableInr + gstInr + transactionFeeInr + platformFeeInr;
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
      totalInr: totalInr,
      totalUsd: totalUsd,
      exchangeRate: rate,
    );
  }
}
