/// Tabs of the seller's Interested buyers list (`tab` query value).
enum InterestedBuyersTab {
  fresh('new', 'Not contacted'),
  contacted('contacted', 'Contacted'),
  all('all', 'All');

  const InterestedBuyersTab(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

/// How the seller last reached this buyer about this item.
enum InterestedContactKind {
  message,
  offer;

  static InterestedContactKind? fromApi(String? raw) =>
      switch (raw?.trim().toUpperCase()) {
        'MESSAGE' => InterestedContactKind.message,
        'OFFER' => InterestedContactKind.offer,
        _ => null,
      };

  String get label => switch (this) {
    InterestedContactKind.message => 'Messaged',
    InterestedContactKind.offer => 'Offer sent',
  };
}

/// Why `canOffer` is false (`offerBlock`), with the seller-facing line.
enum InterestedOfferBlock {
  notSupported(
    'notSupported',
    'Private offers aren’t available for this kind of item.',
  ),
  partialItem(
    'partialItem',
    'The buyer picked part of a parcel. Send a message instead.',
  ),
  noPrice('noPrice', 'This item has no price, so an offer can’t be worked out.'),
  reserved('reserved', 'Another buyer has accepted an offer on this item.'),
  openOffer('openOffer', 'An offer is already open with this buyer.'),
  noAttempts(
    'noAttempts',
    'This buyer has used all offer attempts on this item.',
  ),
  contactLimit('contactLimit', 'You contacted this buyer recently.');

  const InterestedOfferBlock(this.apiValue, this.text);
  final String apiValue;
  final String text;

  static InterestedOfferBlock? fromApi(String? raw) {
    final key = raw?.trim();
    if (key == null || key.isEmpty) return null;
    for (final b in values) {
      if (b.apiValue == key) return b;
    }
    return null;
  }
}

class InterestedLastContact {
  const InterestedLastContact({required this.kind, this.at});

  final InterestedContactKind kind;
  final DateTime? at;
}

/// An offer already open between this buyer and seller on the item.
class InterestedOpenOffer {
  const InterestedOpenOffer({
    required this.id,
    required this.amount,
    required this.status,
    required this.fromSeller,
    this.expiresAt,
  });

  final String id;
  final num amount;

  /// `PENDING` or `ACCEPTED`.
  final String status;
  final bool fromSeller;
  final DateTime? expiresAt;

  bool get isAccepted => status == 'ACCEPTED';

  String get label => isAccepted
      ? 'Offer accepted · awaiting payment'
      : fromSeller
      ? 'Your offer · waiting for the buyer'
      : 'Buyer’s offer · waiting for you';
}

class InterestedProduct {
  const InterestedProduct({
    required this.id,
    required this.type,
    this.title,
    this.image,
    this.stockNumber,
    this.minimumOfferPrice,
  });

  final String id;

  /// diamond, meleeDiamond, gemstone, roughDiamond, watch or bullion.
  final String type;
  final String? title;
  final String? image;
  final String? stockNumber;

  /// The seller's own hidden minimum; shown only on the seller screen.
  final num? minimumOfferPrice;

  String get typeLabel => switch (type) {
    'diamond' => 'Diamond',
    'meleeDiamond' => 'Melee diamond',
    'gemstone' => 'Gemstone',
    'roughDiamond' => 'Rough diamond',
    'watch' => 'Watch',
    'bullion' => 'Bullion',
    _ => type,
  };

  String get displayTitle {
    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;
    final s = stockNumber?.trim();
    if (s != null && s.isNotEmpty) return s;
    return typeLabel;
  }
}

/// One cart line the seller may reach out about. [id] is the cart line id.
class InterestedBuyer {
  const InterestedBuyer({
    required this.id,
    required this.buyerName,
    required this.quantity,
    required this.lineTotal,
    required this.product,
    required this.buyerReplied,
    required this.canMessage,
    required this.canOffer,
    this.addedAt,
    this.lastContact,
    this.nextContactAt,
    this.chatPath,
    this.openOffer,
    this.offerBlock,
  });

  final String id;

  /// Display name only; the server never sends other buyer details.
  final String buyerName;
  final DateTime? addedAt;

  /// Pieces or carats on the line.
  final num quantity;

  /// The buyer's current cart price for this line, USD.
  final num lineTotal;
  final InterestedProduct product;
  final InterestedLastContact? lastContact;

  /// When the seller may contact again; null = now.
  final DateTime? nextContactAt;
  final bool buyerReplied;

  /// Web chat path; set only once the buyer has written.
  final String? chatPath;
  final InterestedOpenOffer? openOffer;
  final bool canMessage;
  final bool canOffer;
  final InterestedOfferBlock? offerBlock;

  bool get contacted => lastContact != null;

  /// The buyer's user id, from `participantId` in [chatPath].
  String? get chatBuyerId {
    final path = chatPath;
    if (path == null || path.isEmpty) return null;
    final id = Uri.tryParse(path)?.queryParameters['participantId']?.trim();
    return id == null || id.isEmpty ? null : id;
  }
}

/// Header stats over every visible cart line (ignores tab, search, page).
class InterestedBuyersSummary {
  const InterestedBuyersSummary({
    required this.items,
    required this.buyers,
    required this.notContacted,
    required this.totalValue,
  });

  static const empty = InterestedBuyersSummary(
    items: 0,
    buyers: 0,
    notContacted: 0,
    totalValue: 0,
  );

  final int items;
  final int buyers;
  final int notContacted;
  final num totalValue;
}

class InterestedBuyersPage {
  const InterestedBuyersPage({
    required this.items,
    required this.summary,
    required this.total,
    required this.currentPage,
    required this.hasMore,
  });

  final List<InterestedBuyer> items;
  final InterestedBuyersSummary summary;

  /// Count after filters.
  final int total;
  final int currentPage;
  final bool hasMore;
}
