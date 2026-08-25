enum ReferenceStatus {
  pending('PENDING', 'Pending'),
  accepted('ACCEPTED', 'Accepted'),
  rejected('REJECTED', 'Rejected');

  const ReferenceStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static ReferenceStatus fromApi(String? raw) {
    for (final status in ReferenceStatus.values) {
      if (status.apiValue == raw) return status;
    }
    return ReferenceStatus.pending;
  }

  bool get isPending => this == ReferenceStatus.pending;
}

class ReferenceParty {
  const ReferenceParty({
    required this.id,
    required this.name,
    required this.email,
    required this.userName,
    required this.referralCode,
  });

  final String id;
  final String name;
  final String email;
  final String userName;
  final String referralCode;

  String get displayName {
    final n = name.trim();
    if (n.isNotEmpty) return n;
    final u = userName.trim();
    if (u.isNotEmpty) return u;
    return email;
  }

  /// e.g. `peter (m3847693@gmail.com)`
  String get nameWithEmail {
    final n = displayName;
    final e = email.trim();
    if (e.isEmpty || e == n) return n;
    return '$n ($e)';
  }

  /// e.g. `peter · m3847693@gmail.com`
  String get nameDotEmail {
    final n = displayName;
    final e = email.trim();
    if (e.isEmpty || e == n) return n;
    return '$n · $e';
  }
}

class ReferenceRequest {
  const ReferenceRequest({
    required this.id,
    required this.status,
    required this.createdAtLabel,
    this.acceptedAtLabel,
    this.party,
  });

  final String id;
  final ReferenceStatus status;
  final String createdAtLabel;
  final String? acceptedAtLabel;
  final ReferenceParty? party;

  String get partyLabel => party?.displayName ?? 'User';
}

class ReferenceProfile {
  const ReferenceProfile({
    required this.email,
    required this.name,
    required this.userName,
    required this.referralCode,
    required this.shareRegisterUrl,
    required this.inboundPendingCount,
    required this.inboundAcceptedCount,
    required this.totalCommissionEarned,
    this.activeOutbound,
    this.outboundHistory = const [],
  });

  final String email;
  final String name;
  final String userName;
  final String referralCode;
  final String shareRegisterUrl;
  final int inboundPendingCount;
  final int inboundAcceptedCount;
  final double totalCommissionEarned;
  final ReferenceRequest? activeOutbound;
  final List<ReferenceRequest> outboundHistory;
}

class ReferencePurchase {
  const ReferencePurchase({
    required this.id,
    required this.label,
    required this.amountLabel,
    required this.createdAtLabel,
    this.productType,
    this.raw,
  });

  final String id;
  final String label;
  final String amountLabel;
  final String createdAtLabel;
  final String? productType;
  final Map<String, dynamic>? raw;
}

class ReferencePurchasePage {
  const ReferencePurchasePage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<ReferencePurchase> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
