/// Current-user wallet from GET /wallet.
class Wallet {
  const Wallet({
    required this.id,
    required this.balance,
    required this.currency,
    this.recentTransactions = const [],
  });

  final String id;
  final double balance;
  final String currency;
  final List<WalletTransaction> recentTransactions;
}

/// One ledger row from wallet APIs.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.currency,
    this.note,
    this.orderId,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.createdAt,
  });

  final String id;
  final String type;
  final double amount;
  final double balanceAfter;
  final String currency;
  final String? note;
  final String? orderId;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final DateTime? createdAt;

  String get typeLabel {
    final raw = type.trim();
    if (raw.isEmpty) return 'Transaction';
    return raw
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  bool get isCredit {
    final t = type.toUpperCase();
    if (t.contains('DEBIT') ||
        t.contains('WITHDRAW') ||
        t.contains('PAYMENT')) {
      return false;
    }
    if (t.contains('CREDIT') || t.contains('TOP') || t.contains('REFUND')) {
      return true;
    }
    return amount >= 0;
  }
}

/// Paginated GET /wallet/transactions payload.
class WalletTransactionsPage {
  const WalletTransactionsPage({
    required this.transactions,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<WalletTransaction> transactions;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

/// Razorpay order from POST /wallet/top-up.
class WalletTopUpSession {
  const WalletTopUpSession({
    required this.razorpayOrderId,
    required this.amountPaise,
    required this.amountInr,
    required this.currency,
    required this.keyId,
    this.userName,
    this.userEmail,
  });

  final String razorpayOrderId;
  final int amountPaise;
  final double amountInr;
  final String currency;
  final String keyId;
  final String? userName;
  final String? userEmail;
}
