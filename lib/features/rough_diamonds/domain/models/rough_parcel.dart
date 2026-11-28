/// Natural or lab-grown rough: the two catalogue tabs.
enum RoughDiamondType {
  natural('natural', 'NATURAL'),
  lab('lab', 'LAB');

  const RoughDiamondType(this.query, this.api);

  /// Value sent as `diamondType` on search and filters.
  final String query;

  /// Value the parcel carries in `diamondType`.
  final String api;

  static RoughDiamondType fromApi(String? raw) =>
      (raw ?? '').trim().toLowerCase() == 'lab' ? lab : natural;

  /// `?type=lab` deep links (website style); anything else is natural.
  static RoughDiamondType fromQuery(String? raw) =>
      (raw ?? '').trim().toLowerCase() == 'lab' ? lab : natural;
}

/// One sieve lot of a parcel (a size band with its own carats and price).
class RoughLot {
  const RoughLot({
    required this.id,
    required this.position,
    required this.sieveSize,
    required this.pieces,
    required this.caratWeight,
    required this.pricePerCarat,
    required this.totalPrice,
    this.sieveStandard,
    this.averageCaratPerPiece,
    this.notes,
    this.isSold = false,
    this.isReserved = false,
  });

  final String id;
  final int position;
  final String? sieveStandard;
  final String sieveSize;
  final int pieces;
  final double caratWeight;
  final double? averageCaratPerPiece;
  final double pricePerCarat;
  final double totalPrice;
  final String? notes;
  final bool isSold;
  final bool isReserved;

  /// Sold or held by another order: never buyable.
  bool get isTaken => isSold || isReserved;

  /// Carat per piece, from the lot totals when the seller left it out.
  double? get caratPerPiece {
    final avg = averageCaratPerPiece;
    if (avg != null && avg > 0) return avg;
    return pieces > 0 && caratWeight > 0 ? caratWeight / pieces : null;
  }
}

/// The server's verdict on what can be bought; it decides every button.
class RoughBuy {
  const RoughBuy({
    this.onSale = false,
    this.separable = false,
    this.canBuyWhole = false,
    this.canBuyLots = false,
    this.freeLotIds = const {},
    this.remainingCarat = 0,
    this.remainingPrice = 0,
  });

  final bool onSale;
  final bool separable;
  final bool canBuyWhole;
  final bool canBuyLots;
  final Set<String> freeLotIds;
  final double remainingCarat;
  final double remainingPrice;
}

/// Public seller card of a parcel.
class RoughSeller {
  const RoughSeller({
    required this.id,
    this.userId,
    this.sellerType,
    this.companyName,
    this.companyLogo,
    this.city,
    this.state,
    this.country,
    this.isVerified = false,
    this.averageRating,
    this.reviewCount = 0,
  });

  final String id;
  final String? userId;
  final String? sellerType;
  final String? companyName;
  final String? companyLogo;
  final String? city;
  final String? state;
  final String? country;
  final bool isVerified;
  final double? averageRating;
  final int reviewCount;

  String? get location {
    final parts = [
      for (final p in [city, state, country])
        if (p != null && p.trim().isNotEmpty) p.trim(),
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }
}

/// A rough diamond listing ("parcel"): natural or lab-grown, sold whole or,
/// when separable, lot by lot. Prices are USD.
class RoughParcel {
  const RoughParcel({
    required this.id,
    required this.stockNumber,
    required this.diamondType,
    required this.displayName,
    required this.available,
    required this.totalCaratWeight,
    required this.totalPcs,
    required this.pricePerCarat,
    required this.totalPrice,
    required this.buy,
    this.sellerId,
    this.growthType,
    this.title,
    this.countryOfOrigin,
    this.mineSource,
    this.compositionType,
    this.roughQuality,
    this.crystalShape,
    this.crystalCondition,
    this.transparency,
    this.surfaceCondition,
    this.crystalStructure,
    this.twinning,
    this.fluorescence,
    this.colorRange,
    this.colorDistribution,
    this.clarityRange,
    this.manufacturingPotential,
    this.estimatedYield,
    this.length,
    this.width,
    this.height,
    this.averageCaratPerPiece,
    this.parcelType,
    this.parcelConsistency,
    this.isSeparable,
    this.pricePerPiece,
    this.paymentTerms,
    this.deliveryTerms,
    this.deliveryDays,
    this.inspectionAllowed,
    this.returnTerms,
    this.images = const [],
    this.videoUrl,
    this.kpStatus,
    this.kpCertificateNumber,
    this.kpCertificateUrl,
    this.labReportAvailable = false,
    this.labName,
    this.labReportNumber,
    this.labReportUrl,
    this.description,
    this.isSold = false,
    this.isExpired = false,
    this.isOnAuction = false,
    this.isReserved = false,
    this.isMakeAnOfferAllowed = false,
    this.maxOfferAttemptsPerUser = 5,
    this.createdAt,
    this.seller,
    this.lots = const [],
    this.auctionId,
    this.auctionStartTime,
    this.auctionEndTime,
  });

  final String id;
  final String? sellerId;
  final String stockNumber;
  final RoughDiamondType diamondType;
  final String? growthType;
  final String? title;
  final String displayName;

  /// `yes`, `hold` or `memo`; only `yes` can be bought.
  final String available;
  final String? countryOfOrigin;
  final String? mineSource;
  final String? compositionType;
  final String? roughQuality;
  final String? crystalShape;
  final String? crystalCondition;
  final String? transparency;
  final String? surfaceCondition;
  final String? crystalStructure;
  final String? twinning;
  final String? fluorescence;
  final String? colorRange;
  final String? colorDistribution;
  final String? clarityRange;
  final String? manufacturingPotential;

  /// Percent (0–100).
  final double? estimatedYield;

  /// Millimetres.
  final double? length;
  final double? width;
  final double? height;
  final double? averageCaratPerPiece;
  final String? parcelType;
  final String? parcelConsistency;

  /// `Yes`, `No` or `Not assessed`; only `Yes` allows lot buying.
  final String? isSeparable;
  final double totalCaratWeight;
  final int totalPcs;
  final double pricePerCarat;
  final double totalPrice;
  final double? pricePerPiece;
  final String? paymentTerms;
  final String? deliveryTerms;
  final int? deliveryDays;
  final bool? inspectionAllowed;
  final String? returnTerms;

  /// image1…image6 with the empty ones dropped.
  final List<String> images;
  final String? videoUrl;
  final String? kpStatus;
  final String? kpCertificateNumber;
  final String? kpCertificateUrl;
  final bool labReportAvailable;
  final String? labName;
  final String? labReportNumber;
  final String? labReportUrl;
  final String? description;
  final bool isSold;
  final bool isExpired;
  final bool isOnAuction;
  final bool isReserved;
  final bool isMakeAnOfferAllowed;
  final int maxOfferAttemptsPerUser;
  final DateTime? createdAt;
  final RoughSeller? seller;

  /// Sorted by position; empty for most parcels.
  final List<RoughLot> lots;
  final RoughBuy buy;

  /// Set only while a timed auction runs.
  final String? auctionId;
  final DateTime? auctionStartTime;
  final DateTime? auctionEndTime;

  bool get isLab => diamondType == RoughDiamondType.lab;

  /// A running timed auction replaces every buy button.
  bool get inAuction => (auctionId ?? '').isNotEmpty;

  bool get isAvailable => available.trim().toLowerCase() == 'yes';

  /// Hold / memo tag for cards ("Hold", "Memo"); null when available.
  String? get availabilityTag {
    final a = available.trim().toLowerCase();
    if (a == 'hold') return 'Hold';
    if (a == 'memo') return 'Memo';
    return null;
  }

  /// Status code the shared availability dot understands.
  String get statusCode {
    if (isSold) return 'sold';
    if (!buy.onSale && isAvailable) return 'unavailable';
    return available.trim().toLowerCase();
  }

  double? get caratPerPiece {
    final avg = averageCaratPerPiece;
    if (avg != null && avg > 0) return avg;
    return totalPcs > 0 && totalCaratWeight > 0
        ? totalCaratWeight / totalPcs
        : null;
  }

  RoughLot? lotById(String id) {
    for (final lot in lots) {
      if (lot.id == id) return lot;
    }
    return null;
  }

  /// Lots the buyer may tick: free per the server and not marked taken.
  bool isLotFree(RoughLot lot) =>
      buy.canBuyLots && !lot.isTaken && buy.freeLotIds.contains(lot.id);
}
