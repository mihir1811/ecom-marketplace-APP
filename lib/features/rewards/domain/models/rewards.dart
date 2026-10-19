/// Admin-set reward rates from GET /rewards. Never hard-code them.
class RewardSettings {
  const RewardSettings({
    required this.enabled,
    required this.earnRupeesPerPoint,
    required this.redeemPoints,
    required this.redeemRupees,
    required this.minRedeemPoints,
    required this.maxRedeemPercent,
  });

  static const disabled = RewardSettings(
    enabled: false,
    earnRupeesPerPoint: 0,
    redeemPoints: 0,
    redeemRupees: 0,
    minRedeemPoints: 0,
    maxRedeemPercent: 0,
  );

  /// Programme on or off. Off: no spending, new orders don't earn.
  final bool enabled;

  /// ₹ of item value per point earned.
  final double earnRupeesPerPoint;

  /// [redeemPoints] points are worth [redeemRupees] at checkout.
  final int redeemPoints;
  final double redeemRupees;

  /// Smallest balance that can be spent; 0 means any balance.
  final int minRedeemPoints;

  /// Most of an order total points can pay, in % (1–100).
  final double maxRedeemPercent;

  /// ₹ value of one point at checkout.
  double get pointValueInr =>
      redeemPoints <= 0 ? 0 : redeemRupees / redeemPoints;

  bool get canRedeem => enabled && pointValueInr > 0 && maxRedeemPercent > 0;
}

/// What a points movement was. [unknown] keeps future types readable.
enum RewardTxnType {
  earn,
  redeem,
  redeemRefund,
  adminCredit,
  adminDebit,
  unknown,
}

/// One row of the points history.
class RewardTransaction {
  const RewardTransaction({
    required this.id,
    required this.type,
    required this.rawType,
    required this.points,
    required this.balanceAfter,
    this.amountInr,
    this.note,
    this.orderId,
    this.createdAt,
  });

  final String id;
  final RewardTxnType type;

  /// Server value, shown for [RewardTxnType.unknown].
  final String rawType;

  /// Always positive; the sign comes from [type].
  final int points;
  final int balanceAfter;

  /// Rupee value, set on REDEEM and REDEEM_REFUND.
  final double? amountInr;
  final String? note;
  final String? orderId;
  final DateTime? createdAt;

  bool get isCredit =>
      type == RewardTxnType.earn ||
      type == RewardTxnType.redeemRefund ||
      type == RewardTxnType.adminCredit;

  bool get isDebit =>
      type == RewardTxnType.redeem || type == RewardTxnType.adminDebit;

  /// +45 or −300; 0 for an unknown type.
  int get signedPoints => isCredit ? points : (isDebit ? -points : 0);

  String get label => switch (type) {
    RewardTxnType.earn => 'Earned on an order',
    RewardTxnType.redeem => 'Used at checkout',
    RewardTxnType.redeemRefund => 'Returned from a refund',
    RewardTxnType.adminCredit => 'Added by GemWorld',
    RewardTxnType.adminDebit => 'Removed by GemWorld',
    RewardTxnType.unknown => _titleCase(rawType),
  };

  static String _titleCase(String raw) {
    final words = raw
        .trim()
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    if (words.isEmpty) return 'Points update';
    return words
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

/// GET /rewards: balance, its ₹ value, rates and the latest movements.
class RewardsSummary {
  const RewardsSummary({
    required this.balance,
    required this.balanceValueInr,
    required this.settings,
    this.recentTransactions = const [],
    this.club = RewardClubStatus.empty,
  });

  final int balance;

  /// Balance worth at checkout, before the max-% limit.
  final double balanceValueInr;
  final RewardSettings settings;
  final List<RewardTransaction> recentTransactions;
  final RewardClubStatus club;

  /// Bonus orders placed now earn; 1 outside a club.
  double get earnMultiplier => club.current?.earnMultiplier ?? 1;

  /// Points still needed before the balance can be spent.
  int get pointsToUnlock => balance >= settings.minRedeemPoints
      ? 0
      : settings.minRedeemPoints - balance;

  bool get canSpend => settings.canRedeem && balance > 0 && pointsToUnlock == 0;
}

/// An admin-defined club, by lifetime points.
class RewardClub {
  const RewardClub({
    required this.id,
    required this.name,
    required this.minPoints,
    this.maxPoints,
    required this.color,
    this.earnMultiplier = 1,
  });

  final String id;
  final String name;
  final int minPoints;

  /// Null for the top club.
  final int? maxPoints;

  /// Badge colour as 0xAARRGGBB.
  final int color;

  /// Orders placed in this club earn this many times the points.
  final double earnMultiplier;

  bool get hasBonus => earnMultiplier > 1;
}

/// The buyer's club and progress, from the `club` block of GET /rewards.
class RewardClubStatus {
  const RewardClubStatus({
    required this.lifetimePoints,
    this.current,
    this.next,
    this.pointsToNext,
    this.clubs = const [],
  });

  static const empty = RewardClubStatus(lifetimePoints: 0);

  /// Earned plus added by GemWorld, less removals. Spending never lowers it.
  final int lifetimePoints;
  final RewardClub? current;
  final RewardClub? next;
  final int? pointsToNext;

  /// Every club, lowest first. Empty: hide the club UI.
  final List<RewardClub> clubs;

  bool get hasClubs => clubs.isNotEmpty;

  /// 0..1 from the current club's start (or 0) to the next club.
  double get progress {
    final target = next;
    if (target == null) return 1;
    final start = current?.minPoints ?? 0;
    final span = target.minPoints - start;
    if (span <= 0) return 1;
    return ((lifetimePoints - start) / span).clamp(0.0, 1.0).toDouble();
  }
}

/// Paged GET /rewards/transactions.
class RewardTransactionsPage {
  const RewardTransactionsPage({
    required this.transactions,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<RewardTransaction> transactions;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
