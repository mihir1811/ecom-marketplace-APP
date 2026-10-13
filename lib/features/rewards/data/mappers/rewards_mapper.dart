import '../../domain/models/rewards.dart';

/// Parses reward points JSON into domain models.
abstract final class RewardsMapper {
  static RewardsSummary summaryFromJson(Map<String, dynamic> json) {
    final settings = json['settings'];
    return RewardsSummary(
      balance: _int(json['balance']) ?? 0,
      balanceValueInr: _num(json['balanceValueInr']) ?? 0,
      settings: settings is Map<String, dynamic>
          ? settingsFromJson(settings)
          : RewardSettings.disabled,
      recentTransactions: _transactions(json['recentTransactions']),
    );
  }

  static RewardSettings settingsFromJson(Map<String, dynamic> json) {
    return RewardSettings(
      enabled: json['enabled'] == true,
      earnRupeesPerPoint: _num(json['earnRupeesPerPoint']) ?? 0,
      redeemPoints: _int(json['redeemPoints']) ?? 0,
      redeemRupees: _num(json['redeemRupees']) ?? 0,
      minRedeemPoints: _int(json['minRedeemPoints']) ?? 0,
      maxRedeemPercent: _num(json['maxRedeemPercent']) ?? 0,
    );
  }

  static RewardTransaction transactionFromJson(Map<String, dynamic> json) {
    final raw = _str(json['type']) ?? '';
    return RewardTransaction(
      id: _str(json['id']) ?? '',
      type: _type(raw),
      rawType: raw,
      points: (_int(json['points']) ?? 0).abs(),
      balanceAfter: _int(json['balanceAfter']) ?? 0,
      amountInr: _num(json['amountInr']),
      note: _str(json['note']),
      orderId: _str(json['orderId']),
      createdAt: _date(json['createdAt']),
    );
  }

  static RewardTransactionsPage transactionsPageFromJson(
    Map<String, dynamic> root,
  ) {
    final data = root['data'];
    final dataMap = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};
    final txns = _transactions(dataMap['transactions']);
    final pagination = dataMap['pagination'];
    final pageMap = pagination is Map<String, dynamic>
        ? pagination
        : const <String, dynamic>{};
    return RewardTransactionsPage(
      transactions: txns,
      page: _int(pageMap['page']) ?? 1,
      limit: _int(pageMap['limit']) ?? txns.length,
      total: _int(pageMap['total']) ?? txns.length,
      totalPages: _int(pageMap['totalPages']) ?? 1,
    );
  }

  static List<RewardTransaction> _transactions(Object? raw) {
    final txns = <RewardTransaction>[];
    if (raw is! List) return txns;
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final txn = transactionFromJson(item);
      if (txn.id.isEmpty) continue;
      txns.add(txn);
    }
    return txns;
  }

  static RewardTxnType _type(String value) => switch (value.toUpperCase()) {
    'EARN' => RewardTxnType.earn,
    'REDEEM' => RewardTxnType.redeem,
    'REDEEM_REFUND' => RewardTxnType.redeemRefund,
    'ADMIN_CREDIT' => RewardTxnType.adminCredit,
    'ADMIN_DEBIT' => RewardTxnType.adminDebit,
    _ => RewardTxnType.unknown,
  };

  static String? _str(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _int(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return num.tryParse(v.toString())?.toInt();
  }

  static DateTime? _date(Object? v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toLocal();
  }
}
