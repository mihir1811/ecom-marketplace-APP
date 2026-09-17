enum RefundStatus {
  pending('PENDING', 'Pending'),
  accepted('ACCEPTED', 'Accepted'),
  rejected('REJECTED', 'Rejected'),
  cancelled('CANCELLED', 'Cancelled');

  const RefundStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static RefundStatus fromApi(String? raw) {
    for (final status in RefundStatus.values) {
      if (status.apiValue == raw) return status;
    }
    return RefundStatus.pending;
  }

  bool get isPending => this == RefundStatus.pending;
}

class RefundPartyUser {
  const RefundPartyUser({
    required this.id,
    required this.name,
    this.profilePicture,
  });

  final String id;
  final String name;
  final String? profilePicture;
}

class RefundPartySeller {
  const RefundPartySeller({
    required this.id,
    this.companyName,
    this.companyLogo,
  });

  final String id;
  final String? companyName;
  final String? companyLogo;
}

class RefundRequest {
  const RefundRequest({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.sellerId,
    required this.status,
    required this.reason,
    required this.amountInr,
    required this.amountUsd,
    required this.createdAtLabel,
    required this.updatedAtLabel,
    this.sellerNote,
    this.razorpayRefundId,
    this.resolvedAtLabel,
    this.user,
    this.seller,
  });

  final String id;
  final String orderId;
  final String userId;
  final String sellerId;
  final RefundStatus status;
  final String reason;

  /// Charge amount in INR as returned by the refunds API (`amount`).
  final double amountInr;

  /// USD equivalent for display (API `amountUsd` when present, else converted).
  final double amountUsd;

  final String createdAtLabel;
  final String updatedAtLabel;
  final String? sellerNote;
  final String? razorpayRefundId;
  final String? resolvedAtLabel;
  final RefundPartyUser? user;
  final RefundPartySeller? seller;

  /// Legacy alias for [amountInr].
  double get amount => amountInr;

  String get buyerLabel => user?.name.trim().isNotEmpty == true
      ? user!.name
      : 'Buyer';

  String get sellerLabel {
    final name = seller?.companyName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Seller';
  }

  bool get canCancel => status.isPending;
  bool get canSellerDecide => status.isPending;
}
