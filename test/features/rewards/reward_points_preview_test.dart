import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/rewards/data/mappers/rewards_mapper.dart';
import 'package:gemstone/features/rewards/domain/models/rewards.dart';
import 'package:gemstone/features/rewards/domain/reward_points_preview.dart';

void main() {
  const settings = RewardSettings(
    enabled: true,
    earnRupeesPerPoint: 5000,
    redeemPoints: 100,
    redeemRupees: 100,
    minRedeemPoints: 100,
    maxRedeemPercent: 20,
  );

  RewardsSummary summary(int balance, {RewardSettings s = settings}) =>
      RewardsSummary(balance: balance, balanceValueInr: 0, settings: s);

  test('API reference example: 1,250 pts on ₹2,45,000', () {
    final split = CheckoutSplitPreview.compute(
      totalInr: 245000,
      itemsInr: 230000,
      rewards: summary(1250),
      usePoints: true,
      walletBalance: 0,
      useWallet: false,
    );
    expect(split.points.points, 1250);
    expect(split.points.amountInr, 1250);
    expect(split.razorpayInr, 243750);
    expect(split.earnPoints, 45);
    expect(split.fullyCovered, isFalse);
  });

  test('caps at maxRedeemPercent of the total', () {
    final r = previewPointsRedemption(
      balance: 100000,
      totalInr: 10000,
      settings: settings,
      usePoints: true,
    );
    expect(r.points, 2000);
    expect(r.amountInr, 2000);
  });

  test('below the minimum or switched off spends nothing', () {
    expect(
      previewPointsRedemption(
        balance: 99,
        totalInr: 10000,
        settings: settings,
        usePoints: true,
      ).points,
      0,
    );
    expect(
      previewPointsRedemption(
        balance: 500,
        totalInr: 10000,
        settings: RewardSettings.disabled,
        usePoints: true,
      ).points,
      0,
    );
    expect(summary(99).pointsToUnlock, 1);
    expect(summary(99).canSpend, isFalse);
  });

  test('never leaves between ₹0 and ₹1 for Razorpay', () {
    const full = RewardSettings(
      enabled: true,
      earnRupeesPerPoint: 100,
      redeemPoints: 1,
      redeemRupees: 1,
      minRedeemPoints: 0,
      maxRedeemPercent: 100,
    );
    final r = previewPointsRedemption(
      balance: 1000,
      totalInr: 100.5,
      settings: full,
      usePoints: true,
    );
    expect(r.points, 99);
    final covered = CheckoutSplitPreview.compute(
      totalInr: 100,
      itemsInr: 100,
      rewards: summary(1000, s: full),
      usePoints: true,
      walletBalance: 0,
      useWallet: false,
    );
    expect(covered.razorpayInr, 0);
    expect(covered.fullyCovered, isTrue);
    expect(covered.earnPoints, 0);
  });

  test('wallet pays after points', () {
    final split = CheckoutSplitPreview.compute(
      totalInr: 10000,
      itemsInr: 9000,
      rewards: summary(500),
      usePoints: true,
      walletBalance: 20000,
      useWallet: true,
    );
    expect(split.points.amountInr, 500);
    expect(split.walletInr, 9500);
    expect(split.razorpayInr, 0);
    expect(split.fullyCovered, isTrue);
  });

  test('mapper keeps unknown types neutral', () {
    final page = RewardsMapper.transactionsPageFromJson({
      'data': {
        'transactions': [
          {
            'id': 'a',
            'type': 'REDEEM',
            'points': 300,
            'balanceAfter': 1205,
            'amountInr': 300,
            'note': 'Used on order #4E7A1C93',
            'orderId': 'o1',
            'createdAt': '2026-10-03T14:05:12.004Z',
          },
          {
            'id': 'b',
            'type': 'BONUS_DROP',
            'points': 10,
            'balanceAfter': 1215,
            'amountInr': null,
            'note': 'Festive bonus',
            'orderId': null,
            'createdAt': '2026-10-04T10:00:00.000Z',
          },
        ],
        'pagination': {'page': 1, 'limit': 20, 'total': 2, 'totalPages': 1},
      },
    });
    expect(page.transactions.first.signedPoints, -300);
    expect(page.transactions.last.type, RewardTxnType.unknown);
    expect(page.transactions.last.signedPoints, 0);
    expect(page.transactions.last.label, 'Bonus Drop');
    expect(page.hasMore, isFalse);
  });

  test('club bonus multiplies the earn estimate', () {
    expect(
      estimateEarnedPoints(
        itemsInr: 230000,
        pointsAmountInr: 1250,
        settings: settings,
        earnMultiplier: 1.5,
      ),
      68,
    );
  });

  test('parses the club block', () {
    final summary = RewardsMapper.summaryFromJson({
      'balance': 1250,
      'balanceValueInr': 1250,
      'settings': {'enabled': true, 'earnRupeesPerPoint': 5000},
      'recentTransactions': [],
      'club': {
        'lifetimePoints': 1480,
        'current': {
          'id': 'g',
          'name': 'Gold',
          'minPoints': 1000,
          'maxPoints': 2499,
          'color': '#D4AF37',
          'earnMultiplier': 1.5,
        },
        'next': {
          'id': 'p',
          'name': 'Platinum',
          'minPoints': 2500,
          'maxPoints': null,
          'color': '#7F8C9A',
          'earnMultiplier': 2,
        },
        'pointsToNext': 1020,
        'clubs': [
          {
            'id': 'p',
            'name': 'Platinum',
            'minPoints': 2500,
            'color': '#7F8C9A',
            'earnMultiplier': 2,
          },
          {
            'id': 's',
            'name': 'Silver',
            'minPoints': 500,
            'color': '#A8A9AD',
            'earnMultiplier': 1,
          },
        ],
      },
    });
    expect(summary.club.current?.color, 0xFFD4AF37);
    expect(summary.earnMultiplier, 1.5);
    expect(summary.club.next?.maxPoints, isNull);
    expect(summary.club.clubs.first.name, 'Silver');
    expect(summary.club.progress, closeTo(0.32, 1e-9));
  });

  test('missing club block hides clubs', () {
    final summary = RewardsMapper.summaryFromJson({'balance': 10});
    expect(summary.club.hasClubs, isFalse);
    expect(summary.earnMultiplier, 1);
  });
}
