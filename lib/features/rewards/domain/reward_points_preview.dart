import 'dart:math' as math;

import 'models/rewards.dart';

/// Checkout preview that mirrors be-ohana's reward-points.util.ts. Only a
/// preview: the create-order response carries the amounts actually charged.

/// Razorpay can't take less than ₹1: what's left is ₹0 or at least ₹1.
const _minGatewayRemainderInr = 1.0;

double _round2(double value) => (value * 100).round() / 100;

/// Points spent on an order and their ₹ value.
class PointsRedemption {
  const PointsRedemption(this.points, this.amountInr);

  static const none = PointsRedemption(0, 0);

  final int points;
  final double amountInr;
}

/// Points the server will take off [totalInr] when the buyer opts in.
PointsRedemption previewPointsRedemption({
  required int balance,
  required double totalInr,
  required RewardSettings? settings,
  required bool usePoints,
}) {
  if (settings == null ||
      !usePoints ||
      !settings.canRedeem ||
      balance <= 0 ||
      balance < settings.minRedeemPoints ||
      totalInr <= 0) {
    return PointsRedemption.none;
  }
  final valuePerPoint = settings.pointValueInr;
  final capInr = _round2(totalInr * settings.maxRedeemPercent / 100);
  int pointsFor(double inr) =>
      math.max(0, (inr / valuePerPoint + 1e-9).floor());
  var points = math.min(balance, pointsFor(capInr));
  var amount = math.min(capInr, _round2(points * valuePerPoint));
  final remainder = _round2(totalInr - amount);
  if (remainder > 0 && remainder < _minGatewayRemainderInr) {
    points = math.min(points, pointsFor(totalInr - _minGatewayRemainderInr));
    amount = _round2(points * valuePerPoint);
  }
  return points > 0 ? PointsRedemption(points, amount) : PointsRedemption.none;
}

/// Wallet after points, as the server applies it.
({double walletInr, double razorpayInr}) previewWalletSplit({
  required double amountInr,
  required double walletBalance,
  required bool useWallet,
}) {
  if (!useWallet || walletBalance <= 0 || amountInr <= 0) {
    return (walletInr: 0.0, razorpayInr: _round2(math.max(0, amountInr)));
  }
  var wallet = _round2(math.min(walletBalance, amountInr));
  var razorpay = _round2(amountInr - wallet);
  if (razorpay > 0 && razorpay < _minGatewayRemainderInr) {
    if (walletBalance >= amountInr) {
      wallet = _round2(amountInr);
      razorpay = 0.0;
    } else {
      wallet = _round2(math.max(0.0, amountInr - _minGatewayRemainderInr));
      if (wallet > walletBalance) wallet = 0.0;
      razorpay = _round2(amountInr - wallet);
    }
  }
  return (walletInr: wallet, razorpayInr: razorpay);
}

/// Points the order should earn once it completes, with the club bonus.
/// The part paid with points earns nothing; rejected or returned items
/// earn less.
int estimateEarnedPoints({
  required double itemsInr,
  required double pointsAmountInr,
  required RewardSettings? settings,
  double earnMultiplier = 1,
}) {
  if (settings == null ||
      !settings.enabled ||
      settings.earnRupeesPerPoint <= 0) {
    return 0;
  }
  final multiplier = earnMultiplier >= 1 ? earnMultiplier : 1.0;
  final base = math.max(0.0, itemsInr - pointsAmountInr) * multiplier;
  return (base / settings.earnRupeesPerPoint + 1e-9).floor();
}

/// Full checkout split: points first, then wallet, then Razorpay.
class CheckoutSplitPreview {
  const CheckoutSplitPreview({
    required this.points,
    required this.walletInr,
    required this.razorpayInr,
    required this.earnPoints,
    this.earnBonus,
  });

  factory CheckoutSplitPreview.compute({
    required double totalInr,
    required double itemsInr,
    required RewardsSummary? rewards,
    required bool usePoints,
    required double walletBalance,
    required bool useWallet,
  }) {
    final points = previewPointsRedemption(
      balance: rewards?.balance ?? 0,
      totalInr: totalInr,
      settings: rewards?.settings,
      usePoints: usePoints,
    );
    final split = previewWalletSplit(
      amountInr: totalInr - points.amountInr,
      walletBalance: walletBalance,
      useWallet: useWallet,
    );
    return CheckoutSplitPreview(
      points: points,
      walletInr: split.walletInr,
      razorpayInr: split.razorpayInr,
      earnPoints: estimateEarnedPoints(
        itemsInr: itemsInr,
        pointsAmountInr: points.amountInr,
        settings: rewards?.settings,
        earnMultiplier: rewards?.earnMultiplier ?? 1,
      ),
      earnBonus: (rewards?.club.current?.hasBonus ?? false)
          ? rewards!.club.current
          : null,
    );
  }

  final PointsRedemption points;
  final double walletInr;
  final double razorpayInr;
  final int earnPoints;

  /// The buyer's club when it boosts [earnPoints].
  final RewardClub? earnBonus;

  bool get usesPoints => points.points > 0;
  bool get usesWallet => walletInr > 0;

  /// Nothing left for Razorpay.
  bool get fullyCovered => razorpayInr <= 0.009 && (usesPoints || usesWallet);
}
