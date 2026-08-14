import '../../domain/models/wallet.dart';

/// Parses wallet JSON into domain models.
abstract final class WalletMapper {
  static Wallet walletFromJson(Map<String, dynamic> json) {
    final txns = <WalletTransaction>[];
    final recent = json['recentTransactions'];
    if (recent is List) {
      for (final item in recent) {
        if (item is! Map<String, dynamic>) continue;
        final txn = transactionFromJson(item);
        if (txn.id.isEmpty) continue;
        txns.add(txn);
      }
    }
    return Wallet(
      id: _str(json['id']) ?? '',
      balance: _num(json['balance']) ?? 0,
      currency: _str(json['currency']) ?? 'INR',
      recentTransactions: txns,
    );
  }

  static WalletTransaction transactionFromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: _str(json['id']) ?? '',
      type: _str(json['type']) ?? '',
      amount: _num(json['amount']) ?? 0,
      balanceAfter: _num(json['balanceAfter']) ?? 0,
      currency: _str(json['currency']) ?? 'INR',
      note: _anyText(json['note']),
      orderId: _anyText(json['orderId']),
      razorpayOrderId: _anyText(json['razorpayOrderId']),
      razorpayPaymentId: _anyText(json['razorpayPaymentId']),
      createdAt: _date(json['createdAt']),
    );
  }

  static WalletTransactionsPage transactionsPageFromJson(
    Map<String, dynamic> root,
  ) {
    final data = root['data'];
    final dataMap =
        data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final listJson = dataMap['transactions'];
    final txns = <WalletTransaction>[];
    if (listJson is List) {
      for (final item in listJson) {
        if (item is! Map<String, dynamic>) continue;
        final txn = transactionFromJson(item);
        if (txn.id.isEmpty) continue;
        txns.add(txn);
      }
    }

    final pagination = dataMap['pagination'];
    final pageMap = pagination is Map<String, dynamic>
        ? pagination
        : const <String, dynamic>{};

    return WalletTransactionsPage(
      transactions: txns,
      page: _int(pageMap['page']) ?? 1,
      limit: _int(pageMap['limit']) ?? txns.length,
      total: _int(pageMap['total']) ?? txns.length,
      totalPages: _int(pageMap['totalPages']) ?? 1,
    );
  }

  static WalletTopUpSession topUpSessionFromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap =
        user is Map<String, dynamic> ? user : const <String, dynamic>{};
    return WalletTopUpSession(
      razorpayOrderId: _str(json['razorpayOrderId']) ?? '',
      amountPaise: _int(json['amount']) ?? 0,
      amountInr: _num(json['amountInr']) ?? 0,
      currency: _str(json['currency']) ?? 'INR',
      keyId: _str(json['keyId']) ?? '',
      userName: _str(userMap['name']),
      userEmail: _str(userMap['email']),
    );
  }

  static String? _str(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String? _anyText(Object? v) {
    if (v == null) return null;
    if (v is String) {
      final s = v.trim();
      return s.isEmpty ? null : s;
    }
    if (v is num || v is bool) return v.toString();
    if (v is Map) {
      final text = v['text'] ?? v['message'] ?? v['note'] ?? v['id'];
      return _str(text);
    }
    return null;
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
    return int.tryParse(v.toString());
  }

  static DateTime? _date(Object? v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
